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
# bundle exec ruby render.rb # update cheatsheet png

require_relative 'setup'

cheatsheet_dir  = join(__dir__, *%w[.. .. docs cheatsheet])
cheatsheet_html = join(cheatsheet_dir, 'cheatsheet.html').gsub(' ', '\ ')
cheatsheet_png  = join(cheatsheet_dir, 'cheatsheet.png').gsub(' ', '\ ')
cheatsheet_pdf  = join(cheatsheet_dir, 'cheatsheet.pdf').gsub(' ', '\ ')
assert_exists(cheatsheet_html, "Cheatsheet HTML doesn't exist!")
assert_exists(cheatsheet_png, "Cheatsheet PNG doesn't exist!")
assert_exists(cheatsheet_pdf, "Cheatsheet PDF doesn't exist!")

chrome = "/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome"
assert_exists(chrome, "Chrome doesn't exist!")
assert_chrome_59_required

# run_command "#{chrome} --headless --disable-gpu --print-to-pdf=#{cheatsheet_pdf} file://#{cheatsheet_html}"
run_command "#{chrome} --headless --hide-scrollbars --disable-gpu --screenshot=#{cheatsheet_png} --window-size=1024,2550 file://#{cheatsheet_html}"
