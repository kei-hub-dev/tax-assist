require "rails_helper"

RSpec.describe OpeningBalance, type: :model do
  let(:user) { User.create!(email: "opening@example.com", password: "password1") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }
  let(:account) { Account.create!(user: user, name: "現金", category: "asset") }

  def build_balance(**attrs)
    described_class.new({ accounting_period: period, account: account }.merge(attrs))
  end

  # 一つの勘定科目の期首残高は借方か貸方のどちらか一方にしか立たない
  describe "借方・貸方の排他" do
    it "借方だけなら有効" do
      expect(build_balance(debit_amount: 1000, credit_amount: 0)).to be_valid
    end

    it "貸方だけなら有効" do
      expect(build_balance(debit_amount: 0, credit_amount: 1000)).to be_valid
    end

    it "両方 0 なら有効" do
      expect(build_balance(debit_amount: 0, credit_amount: 0)).to be_valid
    end

    it "両方に金額があると無効" do
      balance = build_balance(debit_amount: 1000, credit_amount: 1000)

      expect(balance).to be_invalid
      expect(balance.errors[:base]).to include("借方と貸方の両方に金額は入力できません")
    end
  end

  describe "金額" do
    it "マイナスは無効" do
      expect(build_balance(debit_amount: -1, credit_amount: 0)).to be_invalid
    end

    it "小数は無効" do
      expect(build_balance(debit_amount: 100.5, credit_amount: 0)).to be_invalid
    end
  end

  describe "会計年度と勘定科目の組み合わせ" do
    it "同じ組み合わせは重複して登録できない" do
      described_class.create!(accounting_period: period, account: account, debit_amount: 100, credit_amount: 0)

      expect {
        described_class.create!(accounting_period: period, account: account, debit_amount: 200, credit_amount: 0)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
