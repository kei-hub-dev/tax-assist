require "selenium-webdriver"

# 開発コンテナには Debian の chromium / chromium-driver を同梱している。
# Selenium Manager による自動ダウンロードには linux/arm64 版が存在しないため、
# コンテナ内ではパッケージのパスを明示的に指定する。
#
# CI (ubuntu-latest / x86_64) には Chrome が用意されており、そこでは
# Selenium Manager に解決を任せる。
CHROMIUM_BINARY = "/usr/bin/chromium".freeze
CHROMEDRIVER_BINARY = "/usr/bin/chromedriver".freeze

Capybara.register_driver :headless_chromium do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = CHROMIUM_BINARY if File.executable?(CHROMIUM_BINARY)
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1400,1400")

  driver_options = { browser: :chrome, options: options }
  if File.executable?(CHROMEDRIVER_BINARY)
    driver_options[:service] = Selenium::WebDriver::Service.chrome(path: CHROMEDRIVER_BINARY)
  end

  Capybara::Selenium::Driver.new(app, **driver_options)
end

Capybara.default_max_wait_time = 5
