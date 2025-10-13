Grover.configure do |config|
  config.options = {
    executable_path: "/usr/bin/chromium",
    format: "A4",
    print_background: true,
    launch_args: [ "--no-sandbox" ]
  }
end
