module SystemHelpers
  DEFAULT_PASSWORD = "password123".freeze

  # 検証に必要な最小限の勘定科目を持つユーザーを作る。
  # accounting_period は User#after_create が自動生成する。
  def create_user_with_accounts(email:)
    user = User.create!(email: email, password: DEFAULT_PASSWORD)
    Account.create!(user: user, name: "現金", category: "asset")
    Account.create!(user: user, name: "売上高", category: "revenue", sub_category: "sales")
    user
  end

  # 画面から実際にログインし、会計年度を選択するところまで進める。
  # current_period は session に持たれるため、UI を経由しないと帳簿系の画面に入れない。
  def sign_in_through_ui(user, period)
    visit new_user_session_path
    fill_in "user[email]", with: user.email
    fill_in "user[password]", with: DEFAULT_PASSWORD
    click_button "ログイン"

    expect(page).to have_selector("#year-select")
    select period.accounting_year.to_s, from: "accounting_period_id"
    click_button "設定"

    # 送信完了を待たずに次の画面へ進むと、session に会計年度が入る前に
    # require_accounting_period! でリダイレクトされてしまう
    expect(page).to have_current_path(accounting_menu_path)
    expect(page).to have_content("会計メニュー")
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system

  config.before(:each, type: :system) do
    driven_by :headless_chromium
  end
end
