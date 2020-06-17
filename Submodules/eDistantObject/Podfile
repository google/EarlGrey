#  Copyright 2018 Google Inc.
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
#
platform :ios, '9.0'

target 'TestsHost' do
  pod 'OCMock', '3.4.1'
end

target 'TestsBundle' do
  pod 'OCMock', '3.4.1'
end

target 'ServiceTests' do
  pod 'OCMock', '3.4.1'
end

target 'ServicePerfTests' do
  pod 'OCMock', '3.4.1'
end

target 'DeviceUnitTests' do
  pod 'OCMock', '3.4.1'
end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end
