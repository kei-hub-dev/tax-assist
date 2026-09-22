require "rails_helper"

RSpec.describe OllamaClient, type: :model do
  let(:base_url) { "http://ollama.test:11434" }
  let(:endpoint) { "#{base_url}/api/chat" }
  let(:schema) { { "type" => "object" } }

  def stub_chat(content:, status: 200)
    stub_request(:post, endpoint)
      .to_return(status: status, body: { message: { content: content } }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  describe ".enabled?" do
    it "OLLAMA_URL が未設定なら無効" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("OLLAMA_URL").and_return(nil)

      expect(described_class.enabled?).to be(false)
    end

    it "OLLAMA_URL があれば有効" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("OLLAMA_URL").and_return(base_url)

      expect(described_class.enabled?).to be(true)
    end
  end

  describe "#chat" do
    subject(:client) { described_class.new(base_url: base_url, model: "test-model", timeout: 5) }

    it "構造化された応答を解析して返す" do
      stub_chat(content: { "debit_account" => "旅費交通費" }.to_json)

      result = client.chat(system: "sys", user: "usr", schema: schema)

      expect(result).to eq("debit_account" => "旅費交通費")
    end

    it "モデル名とスキーマをリクエストに載せる" do
      stub_chat(content: "{}")

      client.chat(system: "sys", user: "usr", schema: schema)

      expect(a_request(:post, endpoint).with { |req|
        body = JSON.parse(req.body)
        body["model"] == "test-model" && body["format"] == schema && body["stream"] == false
      }).to have_been_made
    end

    it "content が JSON でなければ Error" do
      stub_chat(content: "これは JSON ではない")

      expect { client.chat(system: "s", user: "u", schema: schema) }
        .to raise_error(described_class::Error, /JSON として解釈できません/)
    end

    it "content が空なら Error" do
      stub_chat(content: "")

      expect { client.chat(system: "s", user: "u", schema: schema) }
        .to raise_error(described_class::Error, /content がありません/)
    end

    it "HTTP エラーなら Error" do
      stub_request(:post, endpoint).to_return(status: 500, body: "boom")

      expect { client.chat(system: "s", user: "u", schema: schema) }
        .to raise_error(described_class::Error, /500/)
    end

    # 接続できない・遅いは「壊れている」ではなく「今使えない」なので区別する
    it "接続拒否なら Unavailable" do
      stub_request(:post, endpoint).to_raise(Errno::ECONNREFUSED)

      expect { client.chat(system: "s", user: "u", schema: schema) }
        .to raise_error(described_class::Unavailable, /接続できません/)
    end

    it "タイムアウトなら Unavailable" do
      stub_request(:post, endpoint).to_timeout

      expect { client.chat(system: "s", user: "u", schema: schema) }
        .to raise_error(described_class::Unavailable, /タイムアウト/)
    end

    # リモートの Ollama をリバースプロキシで保護している場合に使う
    it "OLLAMA_API_KEY があれば Authorization ヘッダを付ける" do
      stub_chat(content: "{}")
      authed = described_class.new(base_url: base_url, model: "m", timeout: 5, api_key: "secret-token")

      authed.chat(system: "s", user: "u", schema: schema)

      expect(a_request(:post, endpoint)
        .with(headers: { "Authorization" => "Bearer secret-token" })).to have_been_made
    end

    it "OLLAMA_API_KEY が無ければ Authorization ヘッダを付けない" do
      stub_chat(content: "{}")

      client.chat(system: "s", user: "u", schema: schema)

      expect(a_request(:post, endpoint).with { |req| req.headers.key?("Authorization") })
        .not_to have_been_made
    end

    # 接続先はリモートでもよいため https を扱えること
    it "https の接続先でも動作する" do
      secure_url = "https://ollama.example.com"
      stub_request(:post, "#{secure_url}/api/chat")
        .to_return(status: 200, body: { message: { content: '{"ok":true}' } }.to_json,
                   headers: { "Content-Type" => "application/json" })
      remote = described_class.new(base_url: secure_url, model: "m", timeout: 5)

      expect(remote.chat(system: "s", user: "u", schema: schema)).to eq("ok" => true)
    end

    it "base_url が空なら Unavailable" do
      bare = described_class.new(base_url: nil, model: "m", timeout: 5)

      expect { bare.chat(system: "s", user: "u", schema: schema) }
        .to raise_error(described_class::Unavailable, /OLLAMA_URL/)
    end
  end
end
