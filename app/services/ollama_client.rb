require "net/http"
require "json"

# Ollama への最小限のクライアント。
#
# 接続先は OLLAMA_URL で指定する。同一マシン・LAN 内の別マシン・リモートの
# サーバのいずれでもよい。認証が必要な場合は OLLAMA_API_KEY を設定すると
# Authorization: Bearer ヘッダを付与する。
#
# OLLAMA_URL が未設定のときは無効 (enabled? が false) となり、AI 機能そのものが
# 画面に出ない。config/initializers/devise.rb が GOOGLE_CLIENT_ID の有無で
# Google 認証を出し分けているのと同じ流儀。
class OllamaClient
  class Error < StandardError; end
  class Unavailable < Error; end

  DEFAULT_MODEL = "qwen3.8:27b-q4_K_M".freeze
  DEFAULT_TIMEOUT = 60

  class << self
    def enabled?
      base_url.present?
    end

    def base_url
      ENV["OLLAMA_URL"].presence
    end

    def model
      ENV["OLLAMA_MODEL"].presence || DEFAULT_MODEL
    end

    def timeout
      Integer(ENV.fetch("OLLAMA_TIMEOUT", DEFAULT_TIMEOUT))
    end

    # リモートの Ollama をリバースプロキシ等で保護している場合に使う
    def api_key
      ENV["OLLAMA_API_KEY"].presence
    end
  end

  def initialize(base_url: self.class.base_url, model: self.class.model,
                 timeout: self.class.timeout, api_key: self.class.api_key)
    @base_url = base_url
    @model = model
    @timeout = timeout
    @api_key = api_key
  end

  attr_reader :model

  # JSON Schema を渡して構造化出力を強制する。
  # think を無効にしているのは、推論過程の出力で待ち時間が数倍になるため。
  def chat(system:, user:, schema:, num_ctx: 8192, num_predict: 300)
    raise Unavailable, "OLLAMA_URL が設定されていません" if @base_url.blank?

    body = {
      model: @model,
      stream: false,
      think: false,
      keep_alive: "10m",
      format: schema,
      options: { temperature: 0, num_ctx: num_ctx, num_predict: num_predict },
      messages: [
        { role: "system", content: system },
        { role: "user", content: user }
      ]
    }

    response = post("/api/chat", body)
    content = response.dig("message", "content")
    raise Error, "応答に content がありません" if content.blank?

    JSON.parse(content)
  rescue JSON::ParserError => e
    raise Error, "応答を JSON として解釈できません: #{e.message}"
  end

  private

  def post(path, body)
    uri = URI.join(@base_url, path)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = @timeout

    headers = { "Content-Type" => "application/json" }
    headers["Authorization"] = "Bearer #{@api_key}" if @api_key.present?

    request = Net::HTTP::Post.new(uri.path, headers)
    request.body = JSON.generate(body)

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Ollama が #{response.code} を返しました: #{response.body.to_s[0, 200]}"
    end

    JSON.parse(response.body)
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
    raise Unavailable, "Ollama に接続できません (#{@base_url}): #{e.class}"
  rescue Net::OpenTimeout, Net::ReadTimeout
    raise Unavailable, "Ollama の応答がタイムアウトしました (#{@timeout}秒)"
  end
end
