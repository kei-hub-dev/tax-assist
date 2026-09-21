require "rails_helper"

RSpec.describe Account, type: :model do
  let(:user) { User.create!(email: "account@example.com", password: "password1") }

  describe "区分 (category)" do
    it "資産・負債・純資産・収益・費用のいずれかを受け付ける" do
      %w[asset liability equity].each do |category|
        account = described_class.new(user: user, name: "科目_#{category}", category: category)
        expect(account).to be_valid
      end
    end

    it "定義外の区分は無効" do
      account = described_class.new(user: user, name: "謎の科目", category: "unknown")

      expect(account).to be_invalid
      expect(account.errors[:category]).to be_present
    end

    it "前後の空白を取り除く" do
      account = described_class.create!(user: user, name: "現金", category: "  asset  ")

      expect(account.category).to eq("asset")
    end
  end

  describe "サブ区分 (sub_category)" do
    # 収益・費用は決算書の区分集計に使うため、サブ区分が必須になっている
    it "収益にはサブ区分が必要" do
      account = described_class.new(user: user, name: "売上高", category: "revenue")

      expect(account).to be_invalid
      expect(account.errors[:sub_category]).to be_present
    end

    it "費用にはサブ区分が必要" do
      account = described_class.new(user: user, name: "旅費交通費", category: "expense")

      expect(account).to be_invalid
      expect(account.errors[:sub_category]).to be_present
    end

    it "定義外のサブ区分は無効" do
      account = described_class.new(user: user, name: "売上高", category: "revenue", sub_category: "unknown")

      expect(account).to be_invalid
    end

    it "資産・負債・純資産ではサブ区分を nil に落とす" do
      account = described_class.create!(user: user, name: "現金", category: "asset", sub_category: "sales")

      expect(account.sub_category).to be_nil
    end
  end

  describe "科目名の一意性" do
    it "同じユーザー内では重複できない" do
      described_class.create!(user: user, name: "現金", category: "asset")
      duplicate = described_class.new(user: user, name: "現金", category: "asset")

      expect(duplicate).to be_invalid
    end

    it "ユーザーが違えば同じ名前を使える" do
      other = User.create!(email: "other@example.com", password: "password1")
      described_class.create!(user: user, name: "現金", category: "asset")

      expect(described_class.new(user: other, name: "現金", category: "asset")).to be_valid
    end
  end
end
