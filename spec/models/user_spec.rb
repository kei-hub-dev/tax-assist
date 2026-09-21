require "rails_helper"
require "omniauth"

RSpec.describe User, type: :model do
  def google_auth_hash(email:, uid:, verified: true)
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, email_verified: verified },
      extra: { raw_info: { email_verified: verified } }
    )
  end

  describe ".from_omniauth" do
    it "未登録のメールアドレスならユーザーを新規作成する" do
      auth = google_auth_hash(email: "new_google_user@example.com", uid: "google-uid-1")

      user = described_class.from_omniauth(auth)

      expect(user).to be_persisted
      expect(user.email).to eq("new_google_user@example.com")
      expect(user.provider).to eq("google_oauth2")
      expect(user.uid).to eq("google-uid-1")
    end

    it "同じメールアドレスの既存ユーザーがいれば連携する" do
      existing = described_class.create!(email: "existing@example.com", password: "password1")
      auth = google_auth_hash(email: existing.email, uid: "google-uid-2")

      user = described_class.from_omniauth(auth)

      expect(user.id).to eq(existing.id)
      expect(existing.reload.provider).to eq("google_oauth2")
      expect(existing.uid).to eq("google-uid-2")
    end

    it "メールアドレスが未検証なら例外を投げる" do
      auth = google_auth_hash(email: "unverified@example.com", uid: "google-uid-4", verified: false)

      expect { described_class.from_omniauth(auth) }.to raise_error(ArgumentError)
      expect(described_class.find_by(email: "unverified@example.com")).to be_nil
    end
  end

  describe ".find_for_database_authentication" do
    # Google 連携済みユーザーがメール/パスワードでもログインできると、
    # 連携の意味が薄れるうえ乗っ取り経路にもなるため除外している
    it "Google 連携済みユーザーは対象外にする" do
      described_class.create!(
        email: "google_only@example.com", password: "password1",
        provider: "google_oauth2", uid: "google-uid-3"
      )

      found = described_class.find_for_database_authentication(email: "google_only@example.com")

      expect(found).to be_nil
    end

    it "連携していないユーザーは認証対象になる" do
      user = described_class.create!(email: "email_login_user@example.com", password: "password1")

      found = described_class.find_for_database_authentication(email: "email_login_user@example.com")

      expect(found.id).to eq(user.id)
    end

    it "大文字小文字の違いを無視して照合する" do
      user = described_class.create!(email: "MixedCase@Example.com", password: "password1")

      found = described_class.find_for_database_authentication(email: "mixedcase@example.com")

      expect(found.id).to eq(user.id)
    end
  end

  describe "作成時の会計年度" do
    it "2024年から当年までの accounting_period が自動生成される" do
      user = described_class.create!(email: "periods@example.com", password: "password1")

      years = user.accounting_periods.pluck(:accounting_year).sort

      expect(years).to eq((2024..Date.current.year).to_a)
    end
  end
end
