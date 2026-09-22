require "rails_helper"

RSpec.describe JournalEntrySuggester, type: :model do
  let(:user) { User.create!(email: "suggester@example.com", password: "password1") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }

  let!(:cash) { Account.create!(user: user, name: "現金", category: "asset", guidance: "手元の現金。") }
  let!(:travel) do
    Account.create!(user: user, name: "旅費交通費", category: "expense", sub_category: "sganda",
                    guidance: "電車・バスなど移動に伴う費用。接待交際費にはしない。")
  end
  let!(:entertainment) do
    Account.create!(user: user, name: "接待交際費", category: "expense", sub_category: "sganda",
                    guidance: "取引先との飲食・贈答。移動費は含めない。")
  end

  # LLM は呼ばず、返ってきた JSON の扱いだけを検証する
  let(:client) { instance_double(OllamaClient) }
  subject(:suggester) { described_class.new(user: user, accounting_period: period, client: client) }

  def stub_response(overrides = {})
    allow(client).to receive(:chat).and_return({
      "debit_account" => "旅費交通費",
      "credit_account" => "現金",
      "standard_debit_account" => "旅費交通費",
      "differs_from_standard" => false,
      "warning" => "",
      "confidence" => 0.95
    }.merge(overrides))
  end

  describe "#call" do
    it "勘定科目を ActiveRecord のオブジェクトとして返す" do
      stub_response

      result = suggester.call(description: "阪急電鉄 顧客訪問", amount: 280)

      expect(result.debit_account).to eq(travel)
      expect(result.credit_account).to eq(cash)
      expect(result.confidence).to eq(0.95)
      expect(result).not_to be_differs_from_standard
    end

    it "判定基準と食い違う場合は警告を持つ" do
      stub_response("differs_from_standard" => true,
                    "warning" => "過去に接待交際費が使われていますが、判定基準では旅費交通費が適切です")

      result = suggester.call(description: "阪急電鉄 顧客訪問")

      expect(result).to be_differs_from_standard
      expect(result.warning).to include("旅費交通費")
    end

    it "摘要が空なら例外" do
      expect { suggester.call(description: "  ") }.to raise_error(ArgumentError, /摘要/)
    end

    it "勘定科目が無ければ例外" do
      user.accounts.destroy_all

      expect { suggester.call(description: "何か") }.to raise_error(ArgumentError, /勘定科目/)
    end

    # LLM は候補に無い名前を返すことがある。そのまま ID 解決すると nil になるので必ず弾く
    it "候補に無い勘定科目を返されたら例外" do
      stub_response("debit_account" => "架空の科目")

      expect { suggester.call(description: "阪急電鉄 顧客訪問") }
        .to raise_error(OllamaClient::Error, /候補に無い勘定科目/)
    end
  end

  describe "プロンプトの組み立て" do
    def captured_prompt(description: "阪急電鉄 顧客訪問", amount: 280)
      stub_response
      prompt = nil
      allow(client).to receive(:chat) { |args| prompt = args[:user]; stub_body }
      suggester.call(description: description, amount: amount)
      prompt
    end

    def stub_body
      { "debit_account" => "旅費交通費", "credit_account" => "現金",
        "standard_debit_account" => "旅費交通費", "differs_from_standard" => false,
        "warning" => "", "confidence" => 0.9 }
    end

    it "勘定科目と判定基準を含む" do
      prompt = captured_prompt

      expect(prompt).to include("旅費交通費: 電車・バスなど移動に伴う費用。接待交際費にはしない。")
      expect(prompt).to include("接待交際費: 取引先との飲食・贈答。移動費は含めない。")
    end

    it "過去の仕訳を含む" do
      entry = JournalEntry.create!(accounting_period: period, entry_date: Date.current,
                                   description: "JR西日本 大阪→三ノ宮")
      JournalEntryLine.create!(journal_entry: entry, account: entertainment, dc: "debit", amount: 320)
      JournalEntryLine.create!(journal_entry: entry, account: cash, dc: "credit", amount: 320)

      prompt = captured_prompt

      expect(prompt).to include("摘要「JR西日本 大阪→三ノ宮」 借方:接待交際費 貸方:現金")
    end

    it "履歴が無いときはその旨を示す" do
      expect(captured_prompt).to include("過去の仕訳例: (まだありません)")
    end

    # JournalEntry は user_id を持たず accounting_period 経由でしか user に紐づかない。
    # スコープを誤ると他ユーザーの帳簿がプロンプトに混入する。
    it "他ユーザーの仕訳を含めない" do
      intruder = User.create!(email: "intruder@example.com", password: "password1")
      other_account = Account.create!(user: intruder, name: "他人の現金", category: "asset")
      other_period = intruder.accounting_periods.order(:accounting_year).last
      other_entry = JournalEntry.create!(accounting_period: other_period, entry_date: Date.current,
                                         description: "他人の極秘取引")
      JournalEntryLine.create!(journal_entry: other_entry, account: other_account, dc: "debit", amount: 1)
      JournalEntryLine.create!(journal_entry: other_entry, account: other_account, dc: "credit", amount: 1)

      prompt = captured_prompt

      expect(prompt).not_to include("他人の極秘取引")
      expect(prompt).not_to include("他人の現金")
    end

    it "金額を含む" do
      expect(captured_prompt(amount: 280)).to include("金額: 280円")
    end
  end
end
