require "rails_helper"

RSpec.describe "仕訳の入力画面", type: :system do
  let(:user) { create_user_with_accounts(email: "journal@example.com") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }

  before { sign_in_through_ui(user, period) }

  it "Stimulus と Turbo が読み込まれている" do
    visit journal_entries_path

    # リダイレクトされていても JS の有無だけは確認できてしまうため、
    # 仕訳画面にいることを先に確かめる
    expect(page).to have_selector("#lines")

    expect(page.evaluate_script("typeof window.Stimulus")).to eq("object")
    expect(page.evaluate_script("typeof window.Turbo")).to eq("object")
  end

  describe "明細行の追加" do
    it "行が増え、child_index のプレースホルダが一意な値に置換される" do
      visit journal_entries_path

      before_count = page.all("#lines tr.line", visible: :all).size
      click_button "行を追加"

      expect(page).to have_selector("#lines tr.line", count: before_count + 1, visible: :all)

      names = page.all("#lines input[name], #lines select[name]", visible: :all).map { |e| e[:name] }
      expect(names).to all(satisfy { |n| !n.include?("NEW_RECORD") })
    end

    it "連続して追加してもパラメータ名が衝突しない" do
      visit journal_entries_path

      3.times { click_button "行を追加" }

      account_names = page
        .all("#lines select[name*='[account_id]']", visible: :all)
        .map { |e| e[:name] }

      expect(account_names.size).to eq(account_names.uniq.size)
    end
  end

  describe "明細行の削除" do
    it "行が隠れ、_destroy が 1 になる" do
      visit journal_entries_path
      click_button "行を追加"

      page.all("#lines tr.line", visible: :all).last.click_button "行削除"

      state = page.evaluate_script(<<~JS)
        (() => {
          const rows = document.querySelectorAll('#lines tr.line');
          const last = rows[rows.length - 1];
          return {
            hidden: last.hidden,
            destroy: last.querySelector("input[name*='[_destroy]']").value
          };
        })()
      JS

      expect(state["hidden"]).to be(true)
      expect(state["destroy"]).to eq("1")
    end
  end
end
