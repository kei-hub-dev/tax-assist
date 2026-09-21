require "rails_helper"

RSpec.describe JournalEntry, type: :model do
  let(:user) { User.create!(email: "entry@example.com", password: "password1") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }
  let(:other_period) { user.accounting_periods.order(:accounting_year).first }

  describe "伝票番号 (entry_no) の自動採番" do
    it "会計年度内の最初の仕訳は 1 になる" do
      entry = described_class.create!(accounting_period: period, entry_date: Date.current)

      expect(entry.entry_no).to eq(1)
    end

    it "同じ会計年度内では連番になる" do
      3.times { described_class.create!(accounting_period: period, entry_date: Date.current) }

      expect(described_class.where(accounting_period: period).pluck(:entry_no).sort).to eq([ 1, 2, 3 ])
    end

    # 帳簿は年度単位で閉じているため、番号も年度ごとに 1 から振り直す
    it "会計年度が違えば別々に採番される" do
      described_class.create!(accounting_period: period, entry_date: Date.current)
      entry = described_class.create!(accounting_period: other_period, entry_date: Date.current)

      expect(entry.entry_no).to eq(1)
    end

    it "明示的に指定された entry_no は上書きしない" do
      entry = described_class.create!(accounting_period: period, entry_date: Date.current, entry_no: 99)

      expect(entry.entry_no).to eq(99)
    end
  end

  describe "バリデーション" do
    it "entry_date は必須" do
      expect(described_class.new(accounting_period: period)).to be_invalid
    end

    it "entry_no は 0 以下を許さない" do
      entry = described_class.new(accounting_period: period, entry_date: Date.current, entry_no: 0)

      expect(entry).to be_invalid
    end
  end

  describe "明細行の連鎖削除" do
    it "仕訳を削除すると明細行も消える" do
      account = Account.create!(user: user, name: "現金", category: "asset")
      entry = described_class.create!(accounting_period: period, entry_date: Date.current)
      JournalEntryLine.create!(journal_entry: entry, account: account, dc: "debit", amount: 100)

      expect { entry.destroy }.to change(JournalEntryLine, :count).by(-1)
    end
  end
end
