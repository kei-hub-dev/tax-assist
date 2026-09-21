require "rails_helper"

RSpec.describe "仕訳の AI 提案", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { User.create!(email: "suggest@example.com", password: "password1") }
  let(:period) { user.accounting_periods.order(:accounting_year).last }
  let!(:cash) { Account.create!(user: user, name: "現金", category: "asset") }
  let!(:travel) do
    Account.create!(user: user, name: "旅費交通費", category: "expense", sub_category: "sganda")
  end

  let(:ollama_url) { "http://ollama.test:11434" }

  before do
    sign_in user
    post select_accounting_period_path, params: { accounting_period_id: period.id }
  end

  def enable_ai
    allow(OllamaClient).to receive(:enabled?).and_return(true)
    allow(OllamaClient).to receive(:base_url).and_return(ollama_url)
  end

  def stub_ollama(payload)
    stub_request(:post, "#{ollama_url}/api/chat")
      .to_return(status: 200,
                 body: { message: { content: payload.to_json } }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  describe "AI が無効なとき" do
    it "エンドポイントは 404 を返す" do
      allow(OllamaClient).to receive(:enabled?).and_return(false)

      post suggest_journal_entries_path, params: { description: "小田急線 顧客訪問" }

      expect(response).to have_http_status(:not_found)
    end

    it "仕訳画面に AI 提案ボタンが出ない" do
      allow(OllamaClient).to receive(:enabled?).and_return(false)

      get journal_entries_path

      expect(response.body).not_to include("AI提案")
      expect(response.body).not_to include("journal-entry-suggestion")
    end
  end

  describe "AI が有効なとき" do
    before { enable_ai }

    it "仕訳画面に AI 提案ボタンが出る" do
      get journal_entries_path

      expect(response.body).to include("AI提案")
      expect(response.body).to include('data-controller="journal-entry-suggestion"')
    end

    it "勘定科目の ID を含む JSON を返す" do
      stub_ollama(
        "debit_account" => "旅費交通費", "credit_account" => "現金",
        "standard_debit_account" => "旅費交通費", "differs_from_standard" => false,
        "warning" => "", "confidence" => 0.95
      )

      post suggest_journal_entries_path, params: { description: "小田急線 顧客訪問", amount: 280 }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["debit_account_id"]).to eq(travel.id)
      expect(body["credit_account_id"]).to eq(cash.id)
      expect(body["confidence"]).to eq(0.95)
      expect(body["differs_from_standard"]).to be(false)
    end

    it "判定基準と食い違う場合は警告を返す" do
      stub_ollama(
        "debit_account" => "旅費交通費", "credit_account" => "現金",
        "standard_debit_account" => "旅費交通費", "differs_from_standard" => true,
        "warning" => "過去に接待交際費が使われています", "confidence" => 0.9
      )

      post suggest_journal_entries_path, params: { description: "小田急線 顧客訪問" }

      body = JSON.parse(response.body)
      expect(body["differs_from_standard"]).to be(true)
      expect(body["warning"]).to include("接待交際費")
    end

    it "摘要が空なら 422" do
      post suggest_journal_entries_path, params: { description: "" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["error"]).to include("摘要")
    end

    # Ollama が落ちていても、アプリ全体が壊れたように見えないよう区別する
    it "Ollama に繋がらなければ 503" do
      stub_request(:post, "#{ollama_url}/api/chat").to_raise(Errno::ECONNREFUSED)

      post suggest_journal_entries_path, params: { description: "小田急線 顧客訪問" }

      expect(response).to have_http_status(:service_unavailable)
    end

    it "候補に無い科目を返されたら 502" do
      stub_ollama(
        "debit_account" => "架空の科目", "credit_account" => "現金",
        "standard_debit_account" => "架空の科目", "differs_from_standard" => false,
        "warning" => "", "confidence" => 0.5
      )

      post suggest_journal_entries_path, params: { description: "小田急線 顧客訪問" }

      expect(response).to have_http_status(:bad_gateway)
    end
  end

  describe "認証と会計年度" do
    before { enable_ai }

    it "未ログインなら提案できない" do
      sign_out user

      post suggest_journal_entries_path, params: { description: "小田急線 顧客訪問" }

      expect(response).not_to have_http_status(:ok)
    end
  end
end
