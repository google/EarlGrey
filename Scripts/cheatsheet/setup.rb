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

def join *args
  File.expand_path(File.join(*args))
end

def assert_exists(path, message)
  abort message unless File.exist?(path.gsub('\ ', ' '))
end

def run_command cmd
  puts "$ #{cmd}"
  raise "#{cmd} failed" unless system(cmd)
end

def assert_chrome_59_required
  version = `#{'/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome  --version'}`
  major_version = version.match(/(\d+)\./)[1].to_i
  raise "Chrome v59 or newer required. Found v#{major_version}" unless major_version >= 59
end
