# frozen_string_literal: true

module SystemBrowser
  def use_headless_chrome!(screen_size: [ 1_280, 900 ])
    driven_by(
      :selenium,
      using: :chrome,
      screen_size:
    ) do |browser_options|
      browser_options.binary = "/usr/bin/chromium" if File.executable?("/usr/bin/chromium")
      browser_options.add_argument("--headless=new")
      browser_options.add_argument("--no-sandbox")
      browser_options.add_argument("--disable-dev-shm-usage")
    end
  end

  def expect_inertia_runtime(page_marker: nil)
    expect(page).to have_css(page_marker, visible: false) if page_marker
    expect(page).to have_css("script[type='module'][src*='application']", visible: false)
  end
end

RSpec.configure do |config|
  config.include SystemBrowser, type: :system
end
