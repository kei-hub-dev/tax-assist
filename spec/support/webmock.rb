require "webmock/rspec"

# 外部への通信は既定で遮断する。Ollama を叩くコードは必ずスタブする。
# ただしシステムスペックは Capybara がローカルサーバと ChromeDriver に
# 通信するため、localhost 系は許可する。
WebMock.disable_net_connect!(allow_localhost: true)
