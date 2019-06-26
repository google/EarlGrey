# Install in main app target using pod 'EarlGrey/App'
Pod::Spec.new do |s|

  s.name = "EarlGreyApp"
  s.version = "2.0.0"
  s.summary = "iOS UI Automation Test Framework"
  s.homepage = "https://github.com/google/EarlGrey"
  s.author = "Google Inc."
  s.summary = "EarlGrey is a native iOS UI automation test framework that enables you to write clear, concise tests.\\n\\nWith the EarlGrey framework, you have access to enhanced synchronization features. EarlGrey automatically synchronizes with the UI, network requests, and various queues, but still allows you to manually implement customized timings, if needed.\\n\\nEarlGrey’s synchronization features help ensure that the UI is in a steady state before actions are performed. This greatly increases test stability and makes tests highly repeatable.\\n\\nEarlGrey works in conjunction with the XCTest framework and integrates with Xcode’s Test Navigator so you can run tests directly from Xcode or the command line (using xcodebuild)."
  s.license = { :type => "Apache 2.0", :file => "LICENSE" }

  s.source = { :http => 'file:' + __dir__ + '/EarlGreyApp.zip' }
  s.vendored_frameworks = "AppFramework.framework"

  s.pod_target_xcconfig = { "FRAMEWORK_SEARCH_PATHS" =>"$(inherited) $(PLATFORM_DIR)/Developer/Library/Frameworks",
                              "ENABLE_BITCODE" => "NO" }

  s.platform = :ios, '10.0'
end
