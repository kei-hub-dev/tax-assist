require "rails_helper"

RSpec.describe "仕訳の AI 提案 (画面)", type: :system do
  let(:user) { create_user_with_accounts(email: "ai_system@example.com") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }
  let(:travel) do
    Account.create!(user: user, name: "旅費交通費", category: "expense", sub_category: "sganda",
                    guidance: "電車・バスなど移動に伴う費用。")
  end

  context "AI が無効なとき" do
    before do
      allow(OllamaClient).to receive(:enabled?).and_return(false)
      sign_in_through_ui(user, period)
    end

    it "AI 提案ボタンが表示されない" do
      visit journal_entries_path

      expect(page).to have_selector("#lines")
      expect(page).to have_no_button("AI提案")
    end
  end

  context "AI が有効なとき" do
    let(:ollama_url) { "http://ollama.test:11434" }

    before do
      travel
      allow(OllamaClient).to receive(:enabled?).and_return(true)
      allow(OllamaClient).to receive(:base_url).and_return(ollama_url)
      sign_in_through_ui(user, period)
    end

    def stub_ollama(payload)
      stub_request(:post, "#{ollama_url}/api/chat")
        .to_return(status: 200,
                   body: { message: { content: payload.to_json } }.to_json,
                   headers: { "Content-Type" => "application/json" })
    end

    it "摘要が空ならメッセージを出し、提案を要求しない" do
      visit journal_entries_path

      click_button "AI提案"

      expect(page).to have_content("摘要を入力してください")
      expect(a_request(:post, "#{ollama_url}/api/chat")).not_to have_been_made
    end

    it "提案を取得して明細行に反映する" do
      stub_ollama(
        "debit_account" => "旅費交通費", "credit_account" => "現金",
        "standard_debit_account" => "旅費交通費", "differs_from_standard" => false,
        "warning" => "", "confidence" => 0.95
      )

      visit journal_entries_path
      fill_in "journal_entry[description]", with: "阪急電鉄 顧客訪問"
      click_button "AI提案"

      expect(page).to have_content("借方: 旅費交通費")
      expect(page).to have_content("確信度 95%")

      selected = page.evaluate_script(
        %{document.querySelector("#lines select[name*='[account_id]']").value}
      )
      expect(selected).to eq(travel.id.to_s)

      dc = page.evaluate_script(%{document.querySelector("#lines select[name*='[dc]']").value})
      expect(dc).to eq("debit")
    end

    it "判定基準と食い違う場合は警告を表示する" do
      stub_ollama(
        "debit_account" => "旅費交通費", "credit_account" => "現金",
        "standard_debit_account" => "旅費交通費", "differs_from_standard" => true,
        "warning" => "過去に接待交際費が使われていますが、判定基準では旅費交通費が適切です",
        "confidence" => 0.9
      )

      visit journal_entries_path
      fill_in "journal_entry[description]", with: "阪急電鉄 顧客訪問"
      click_button "AI提案"

      expect(page).to have_content("過去に接待交際費が使われていますが")
    end

    it "Ollama が落ちていてもフォームは壊れない" do
      stub_request(:post, "#{ollama_url}/api/chat").to_raise(Errno::ECONNREFUSED)

      visit journal_entries_path
      fill_in "journal_entry[description]", with: "阪急電鉄 顧客訪問"
      click_button "AI提案"

      expect(page).to have_content("接続できません")
      # ボタンが押しっぱなしで固まらないこと
      expect(page).to have_button("AI提案", disabled: false)
    end
  end
end
