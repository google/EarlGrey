#
#  Copyright 2016 Google Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# Usage:
# bundle install             # install required gems
# bundle exec ruby render.rb # update cheatsheet png

require_relative 'setup'

cheatsheet_dir = join(__dir__, *%w[.. .. docs cheatsheet])
cheatsheet_html = join(cheatsheet_dir, 'cheatsheet.html')
cheatsheet_png = join(cheatsheet_dir, 'cheatsheet.png')
assert_exists(cheatsheet_html, "Cheatsheet HTML doesn't exist!")
assert_exists(cheatsheet_png, "Cheatsheet PNG doesn't exist!")

web_driver = Selenium::WebDriver.for :chrome

begin
  web_driver.get 'file://' + cheatsheet_html

  eyes = Applitools::Eyes.new
  eyes.api_key = ' '
  eyes.scale_ratio = 0.5 # must be '0.5' to trigger the size_factor = 2 logic in fullpage_screenshot
  eyes_driver = eyes.open(driver: web_driver, app_name: ' ', test_name: ' ')
  eyes_browser = eyes_driver.browser

  screenshot = eyes_browser.fullpage_screenshot

  # remove right hand scrollbars by cropping.
  crop_width = screenshot.width - 20
  screenshot.crop!(0, 0, crop_width, screenshot.height)
  screenshot.save(cheatsheet_png, :best_compression)
ensure
  web_driver.quit
end
