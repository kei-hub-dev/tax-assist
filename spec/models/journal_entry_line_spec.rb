require "rails_helper"

RSpec.describe JournalEntryLine, type: :model do
  let(:user) { User.create!(email: "line@example.com", password: "password1") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }
  let(:account) { Account.create!(user: user, name: "現金", category: "asset") }
  let(:entry) { JournalEntry.create!(accounting_period: period, entry_date: Date.current) }

  def build_line(**attrs)
    described_class.new({ journal_entry: entry, account: account, dc: "debit", amount: 100 }.merge(attrs))
  end

  describe "貸借区分 (dc)" do
    it "debit と credit を受け付ける" do
      expect(build_line(dc: "debit")).to be_valid
      expect(build_line(dc: "credit")).to be_valid
    end

    it "それ以外は無効" do
      expect(build_line(dc: "both")).to be_invalid
      expect(build_line(dc: nil)).to be_invalid
    end
  end

  describe "金額 (amount)" do
    # 金額は円単位の integer。小数や 0 円・マイナスの行は帳簿として意味を持たない
    it "0 以下は無効" do
      expect(build_line(amount: 0)).to be_invalid
      expect(build_line(amount: -1)).to be_invalid
    end

    it "小数は無効" do
      expect(build_line(amount: 100.5)).to be_invalid
    end

    it "正の整数は有効" do
      expect(build_line(amount: 1)).to be_valid
    end
  end

  describe "勘定科目" do
    it "account は必須" do
      line = build_line
      line.account = nil

      expect(line).to be_invalid
    end
  end

  # モデルには貸借一致のバリデーションが無く、呼び出し側が担保する前提になっている。
  # 将来ここに検証を足す場合、このテストが変更の起点になる。
  describe "貸借一致" do
    it "モデル単体では貸借の不一致を検出しない" do
      described_class.create!(journal_entry: entry, account: account, dc: "debit", amount: 100)
      credit_only = described_class.create!(journal_entry: entry, account: account, dc: "credit", amount: 999)

      expect(credit_only).to be_persisted
      expect(entry.reload).to be_valid
    end
  end
end
