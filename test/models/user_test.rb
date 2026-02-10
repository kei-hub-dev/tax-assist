require "test_helper"
require "omniauth"

class UserTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "from_omniauth creates a new user for verified email" do
    auth = google_auth_hash(email: "new_google_user@example.com", uid: "google-uid-1")

    user = User.from_omniauth(auth)

    assert user.persisted?
    assert_equal "new_google_user@example.com", user.email
    assert_equal "google_oauth2", user.provider
    assert_equal "google-uid-1", user.uid
  end

  test "from_omniauth links an existing email user when email is verified" do
    existing_user = User.create!(email: "existing@example.com", password: "password1")
    auth = google_auth_hash(email: existing_user.email, uid: "google-uid-2")

    user = User.from_omniauth(auth)

    assert_equal existing_user.id, user.id
    assert_equal "google_oauth2", existing_user.reload.provider
    assert_equal "google-uid-2", existing_user.uid
  end

  test "database authentication excludes google linked users" do
    User.create!(email: "google_only@example.com", password: "password1", provider: "google_oauth2", uid: "google-uid-3")

    found = User.find_for_database_authentication(email: "google_only@example.com")

    assert_nil found
  end

  test "database authentication allows email users without provider" do
    user = User.create!(email: "email_login_user@example.com", password: "password1")

    found = User.find_for_database_authentication(email: "email_login_user@example.com")

    assert_equal user.id, found.id
  end

  private

  def google_auth_hash(email:, uid:, verified: true)
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid:,
      info: {
        email:,
        email_verified: verified
      },
      extra: {
        raw_info: {
          email_verified: verified
        }
      }
    )
  end
end
