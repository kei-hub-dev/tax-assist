require "rails_helper"

RSpec.describe "帳票の出力", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { User.create!(email: "reports@example.com", password: "password1") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }
  let!(:cash) { Account.create!(user: user, name: "現金", category: "asset") }
  let!(:sales) { Account.create!(user: user, name: "売上高", category: "revenue", sub_category: "sales") }
  let!(:travel) { Account.create!(user: user, name: "旅費交通費", category: "expense", sub_category: "sganda") }

  before do
    entry = JournalEntry.create!(accounting_period: period, entry_date: Date.new(period.accounting_year, 4, 1),
                                 description: "A社 請求書")
    JournalEntryLine.create!(journal_entry: entry, account: cash,  dc: "debit",  amount: 100_000)
    JournalEntryLine.create!(journal_entry: entry, account: sales, dc: "credit", amount: 100_000)

    expense = JournalEntry.create!(accounting_period: period, entry_date: Date.new(period.accounting_year, 4, 2),
                                   description: "JR西日本 大阪→三ノ宮")
    JournalEntryLine.create!(journal_entry: expense, account: travel, dc: "debit",  amount: 320)
    JournalEntryLine.create!(journal_entry: expense, account: cash,   dc: "credit", amount: 320)

    sign_in user
    post select_accounting_period_path, params: { accounting_period_id: period.id }
  end

  describe "CSV エクスポート" do
    it "損益計算書を出力し、段階利益が積み上がっている" do
      get reports_income_statement_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")

      rows = CSV.parse(response.body).to_h
      expect(rows["売上高"]).to eq("100000")
      expect(rows["販売費及び一般管理費"]).to eq("320")
      expect(rows["営業利益"]).to eq("99680")
      expect(rows["当期純利益"]).to eq("99680")
    end

    it "総勘定元帳を出力する" do
      get reports_general_ledger_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(CSV.parse(response.body).size).to be > 1
    end

    it "貸借対照表を出力する" do
      get reports_balance_sheet_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(CSV.parse(response.body).size).to be > 1
    end
  end

  describe "PDF エクスポート" do
    # grover -> puppeteer -> Chromium の経路。日本語フォントの埋め込みまで確認する
    it "損益計算書を PDF で出力し、日本語フォントが埋め込まれる" do
      get reports_income_statement_path(format: :pdf)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.body[0, 5]).to eq("%PDF-")
      expect(response.body).to include("Noto Sans CJK")
    end
  end

  # styleguide.md でも最優先に挙げている観点。
  # JournalEntry は user_id を持たず accounting_period 経由で user に紐づくため、
  # スコープを取り違えると他ユーザーの帳簿が見えてしまう。
  describe "ユーザースコープ" do
    let(:intruder) { User.create!(email: "intruder@example.com", password: "password1") }

    it "他ユーザーの会計年度は選択できない" do
      other_period = intruder.accounting_periods.order(:accounting_year).last

      post select_accounting_period_path, params: { accounting_period_id: other_period.id }

      expect(response).to redirect_to(authenticated_root_path)
      expect(flash[:alert]).to eq("会計年度を選択してください")
    end

    it "他ユーザーの仕訳は取得できない" do
      other_period = intruder.accounting_periods.order(:accounting_year).last
      other_entry = JournalEntry.create!(accounting_period: other_period, entry_date: Date.current,
                                         description: "他人の仕訳")

      get edit_journal_entry_path(other_entry)

      expect(response).not_to have_http_status(:ok)
    end

    it "他ユーザーの仕訳は削除できない" do
      other_period = intruder.accounting_periods.order(:accounting_year).last
      other_entry = JournalEntry.create!(accounting_period: other_period, entry_date: Date.current,
                                         description: "他人の仕訳")

      expect { delete journal_entry_path(other_entry) }.not_to change(JournalEntry, :count)
    end

    it "他ユーザーの勘定科目は削除できない" do
      other_account = Account.create!(user: intruder, name: "他人の現金", category: "asset")

      expect { delete account_path(other_account) }.not_to change(Account, :count)
    end
  end

  describe "認証" do
    it "未ログインで HTML を要求するとログイン画面へ飛ばされる" do
      sign_out user

      get reports_income_statement_path

      expect(response).to redirect_to(new_user_session_path)
    end

    # CSV は navigational_formats に含まれないため、リダイレクトではなく 401 を返す
    it "未ログインで CSV を要求すると 401 を返す" do
      sign_out user

      get reports_income_statement_path(format: :csv)

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
