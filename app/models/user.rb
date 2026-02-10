class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :accounting_periods, dependent: :destroy
  has_many :accounts, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  before_validation :normalize_email
  after_create :setup_default_periods

  class << self
    def from_omniauth(auth)
      provider = auth.provider.to_s
      uid = auth.uid.to_s
      email = auth.info.email.to_s.strip.downcase

      raise ArgumentError, "invalid omniauth payload" if provider.blank? || uid.blank? || email.blank?
      raise ArgumentError, "email is not verified" unless google_email_verified?(auth)

      user = find_by(provider:, uid:)
      return user if user

      user = find_by_verified_email(email)
      user ||= new(email:, password: Devise.friendly_token.first(32))

      if user.provider.present? && (user.provider != provider || user.uid != uid)
        user.errors.add(:base, "このメールアドレスは別の外部アカウントに連携済みです")
        raise ActiveRecord::RecordInvalid, user
      end

      user.provider = provider
      user.uid = uid
      user.save!
      user
    end

    # Google 連携済みユーザーはメール/パスワード認証対象から除外する。
    def find_for_database_authentication(warden_conditions)
      conditions = warden_conditions.dup
      email = conditions.delete(:email).to_s.strip.downcase
      return nil if email.blank?

      where(conditions).where("LOWER(email) = ?", email).where(provider: [ nil, "" ]).first
    end

    def google_email_verified?(auth)
      raw_verified =
        auth&.dig("info", "email_verified") ||
        auth&.dig("info", "verified") ||
        auth&.dig("extra", "raw_info", "email_verified")

      ActiveModel::Type::Boolean.new.cast(raw_verified)
    end

    private

    def find_by_verified_email(email)
      find_by("LOWER(email) = ?", email)
    end
  end

  def google_authenticated?
    provider == "google_oauth2" && uid.present?
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def setup_default_periods
    (2024..Date.current.year).each do |y|
      accounting_periods.find_or_create_by!(accounting_year: y)
    end
  end
end
