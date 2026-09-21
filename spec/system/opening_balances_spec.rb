require "rails_helper"

RSpec.describe "期首残高の設定画面", type: :system do
  let(:user) { create_user_with_accounts(email: "opening@example.com") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }

  before { sign_in_through_ui(user, period) }

  it "入力に応じて借方・貸方の合計が再計算される" do
    visit opening_balances_path

    debit = page.all('input[data-opening-balance-totals-target="debit"]', visible: :all).first
    credit = page.all('input[data-opening-balance-totals-target="credit"]', visible: :all).last

    fill_in_number(debit, 12_345)
    expect(page).to have_selector("#total-debit", text: "12,345")

    fill_in_number(credit, 12_345)
    expect(page).to have_selector("#total-credit", text: "12,345")
  end

  it "貸借が一致しないうちは警告を表示し、一致すると消える" do
    visit opening_balances_path

    debit = page.all('input[data-opening-balance-totals-target="debit"]', visible: :all).first
    credit = page.all('input[data-opening-balance-totals-target="credit"]', visible: :all).last

    fill_in_number(debit, 1000)
    expect(page).to have_selector("#sum-row.sum-ng")
    expect(page).to have_content("借方と貸方の合計が一致していません")

    fill_in_number(credit, 1000)
    expect(page).to have_selector("#sum-row.sum-ok")
    expect(page).to have_no_content("借方と貸方の合計が一致していません")
  end

  private

  # number_field は set だけでは input イベントが発火しない場合があるため明示的に投げる
  def fill_in_number(element, value)
    element.set(value.to_s)
    page.driver.browser.execute_script(
      "arguments[0].dispatchEvent(new Event('input', { bubbles: true }))",
      element.native
    )
  end
end
