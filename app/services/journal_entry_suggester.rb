# 摘要と金額から、借方・貸方の勘定科目を提案する。
#
# 判断材料は優先度順に 3 つ。
#   1. 勘定科目の判定基準 (accounts.guidance) ... 明示的でレビューできる
#   2. その利用者の過去の仕訳                  ... 運用の癖を反映できるが誤りも混ざる
#   3. LLM の一般的な会計知識                  ... 広いが一般論に留まる
#
# 2 に誤りがあると同じ誤りを繰り返すため、1 を最優先にしたうえで、
# 会計上の一般原則と食い違う場合は warning を返して利用者に判断を委ねる。
class JournalEntrySuggester
  # 過去の仕訳をいくつ渡すか。モデルの context は十分広いが、
  # 多すぎると古い例に引きずられるため直近に絞る。
  HISTORY_LIMIT = 40

  SCHEMA = {
    "type" => "object",
    "properties" => {
      "debit_account" => { "type" => "string" },
      "credit_account" => { "type" => "string" },
      "standard_debit_account" => { "type" => "string" },
      "differs_from_standard" => { "type" => "boolean" },
      "warning" => { "type" => "string" },
      "confidence" => { "type" => "number" }
    },
    "required" => %w[debit_account credit_account standard_debit_account differs_from_standard warning confidence]
  }.freeze

  SYSTEM_PROMPT = <<~PROMPT.freeze
    あなたは日本の青色申告(個人事業主)の複式簿記アシスタントです。
    摘要と金額から、借方と貸方の勘定科目を1つずつ選びます。

    判断の優先順位は次のとおりで、上位が下位に優先します。
    1. 各勘定科目に付けられた判定基準 (最優先)
    2. 一般的な会計知識
    3. その利用者の過去の仕訳

    次の手順で答えてください。
    1. 判定基準と一般的な会計知識から、正しい借方科目を決める。
       これを standard_debit_account と debit_account の両方に入れる。
    2. 過去の仕訳を見て、同種の取引が別の科目で計上されていないか確認する。
    3. 過去の仕訳が 1 と異なる場合は differs_from_standard を true にし、warning に
       「過去の仕訳では X が使われていますが、判定基準では Y が適切です」のように具体的に書く。
       このとき debit_account は 1 で決めた正しい科目のままにする。
    4. 判定基準に該当する記述が無く、過去の仕訳にのみ前例がある場合は、
       その前例に合わせて debit_account を決めてよい。その場合 differs_from_standard は false。
    5. 食い違いが無い場合は differs_from_standard を false、warning は空文字にする。

    制約:
    - 勘定科目は必ず与えられた候補の中から選ぶこと。候補に無い名前を作らないこと。
    - 過去の仕訳に誤りが含まれることがある。判定基準から外れる前例は踏襲せず warning で知らせること。
    - warning は 100 文字以内で簡潔に書くこと。
    - confidence は 0.0 から 1.0 の確信度。
  PROMPT

  Result = Struct.new(
    :debit_account, :credit_account, :standard_debit_account,
    :differs_from_standard, :warning, :confidence,
    keyword_init: true
  ) do
    def differs_from_standard? = !!differs_from_standard
  end

  def initialize(user:, accounting_period:, client: OllamaClient.new)
    @user = user
    @accounting_period = accounting_period
    @client = client
  end

  def call(description:, amount: nil)
    raise ArgumentError, "摘要が空です" if description.blank?

    accounts = @user.accounts.order(:category, :name).to_a
    raise ArgumentError, "勘定科目が登録されていません" if accounts.empty?

    raw = @client.chat(
      system: SYSTEM_PROMPT,
      user: build_prompt(accounts, description, amount),
      schema: SCHEMA
    )

    build_result(raw, accounts)
  end

  private

  def build_prompt(accounts, description, amount)
    <<~TEXT
      #{format_accounts(accounts)}

      #{format_history}

      仕訳を作りたい取引:
      摘要: #{description}
      #{"金額: #{amount}円" if amount.present?}
    TEXT
  end

  def format_accounts(accounts)
    lines = accounts.map do |account|
      guidance = account.guidance.presence
      guidance ? "- #{account.name}: #{guidance}" : "- #{account.name}"
    end
    "勘定科目の候補と判定基準:\n#{lines.join("\n")}"
  end

  # 過去の仕訳は accounting_period 経由でしか user に紐づかないため、
  # 必ず accounting_periods.user_id でスコープする。
  def format_history
    entries = JournalEntry
      .joins(:accounting_period)
      .where(accounting_periods: { user_id: @user.id })
      .where.not(description: [ nil, "" ])
      .includes(journal_entry_lines: :account)
      .order(entry_date: :desc, entry_no: :desc)
      .limit(HISTORY_LIMIT)

    lines = entries.filter_map { |entry| format_entry(entry) }
    return "過去の仕訳例: (まだありません)" if lines.empty?

    "過去の仕訳例:\n#{lines.join("\n")}"
  end

  def format_entry(entry)
    debit = entry.journal_entry_lines.find { |line| line.dc == "debit" }
    credit = entry.journal_entry_lines.find { |line| line.dc == "credit" }
    return nil unless debit&.account && credit&.account

    "- 摘要「#{entry.description}」 借方:#{debit.account.name} 貸方:#{credit.account.name}"
  end

  # モデルが候補に無い科目名を返すことがあるため、必ず実在確認をする。
  def build_result(raw, accounts)
    by_name = accounts.index_by(&:name)

    debit = by_name[raw["debit_account"].to_s]
    credit = by_name[raw["credit_account"].to_s]

    if debit.nil? || credit.nil?
      unknown = [ raw["debit_account"], raw["credit_account"] ].compact.reject { |n| by_name.key?(n.to_s) }
      raise OllamaClient::Error, "候補に無い勘定科目が返されました: #{unknown.join(', ')}"
    end

    Result.new(
      debit_account: debit,
      credit_account: credit,
      standard_debit_account: by_name[raw["standard_debit_account"].to_s],
      differs_from_standard: raw["differs_from_standard"],
      warning: raw["warning"].to_s,
      confidence: raw["confidence"].to_f
    )
  end
end
