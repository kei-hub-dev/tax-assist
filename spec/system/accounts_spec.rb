require "rails_helper"

RSpec.describe "勘定科目の編集画面", type: :system do
  let(:user) { create_user_with_accounts(email: "accounts@example.com") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }
  let(:sales) { user.accounts.find_by!(name: "売上高") }

  before { sign_in_through_ui(user, period) }

  it "区分に応じてサブ区分の選択肢が入れ替わる" do
    visit edit_account_path(sales)

    expect(sub_category_values).to contain_exactly("sales", "non_op_income", "special_gain")

    select "費用", from: "account_category"
    expect(page).to have_selector("#account_sub_category option[value='cogs']", visible: :all)
    expect(sub_category_values).to contain_exactly(
      "cogs", "sganda", "non_op_expense", "special_loss", "tax"
    )
  end

  it "収益・費用以外の区分ではサブ区分欄が隠れる" do
    visit edit_account_path(sales)

    select "資産", from: "account_category"

    hidden = page.evaluate_script(
      %{document.querySelector('[data-account-sub-category-target="subCategoryField"]').hidden}
    )
    expect(hidden).to be(true)
    expect(page.evaluate_script("document.getElementById('account_sub_category').value")).to eq("")
  end

  it "編集時は保存済みのサブ区分が選択された状態で表示される" do
    visit edit_account_path(sales)

    expect(page.evaluate_script("document.getElementById('account_sub_category').value")).to eq("sales")
  end

  private

  def sub_category_values
    page.all("#account_sub_category option", visible: :all).map(&:value).reject(&:empty?)
  end
end
