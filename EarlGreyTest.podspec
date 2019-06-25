# Install in ui test target using pod 'EarlGreyTest'
Pod::Spec.new do |s|

  s.name = "EarlGreyTest"
  s.version = "2.0.0"
  s.summary = "iOS UI Automation Test Framework"
  s.homepage = "https://github.com/brettfazio/EarlGrey"
  s.author = "Google LLC."
  s.summary = 'EarlGrey is a native iOS UI automation test framework that enables you to write clear, concise tests.\\n\\n'\
                'With the EarlGrey framework, you have access to enhanced synchronization features. EarlGrey automatically'\
                ' synchronizes with the UI, network requests, and various queues, but still allows you to manually implement'\
                ' customized timings, if needed.\\n\\nEarlGrey’s synchronization features help ensure that the UI is in a'\
                ' steady state before actions are performed. This greatly increases test stability and makes tests highly'\
                ' repeatable.\\n\\nEarlGrey works in conjunction with the XCTest framework and integrates with Xcode’s'\
                ' Test Navigator so you can run tests directly from Xcode or the command line (using xcodebuild).'
  s.license = { :type => "Apache 2.0", :file => "LICENSE" }

  # For testing purposes you will need to change ":tag" to ":branch" and give a
  # branch name (like "earlgrey2). Note that the branch will have to have the proper
  # header imports (reduced). Right now earlgrey2 does not have those.
  # Use this line as it has the proper changes:
  # s.source = { :git => "https://github.com/brettfazio/EarlGrey.git", :branch => "recentclone" }
  s.source = { :git => "https://github.com/google/EarlGrey.git", :branch => "edoimporttest" }

  s.dependency "eDistantObject"

  s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/EarlGreyTest/**" "${PODS_ROOT}"' }

  test_sources = Dir.glob("{TestLib,CommonLib}/**/*.{m,h}") +
                Dir.glob("{AppFramework,UILib}/**/*.h") +
                Dir.glob("{TestLib,CommonLib,UILib}/**/*Stub.m") +
                Dir.glob("{TestLib,CommonLib,AppFramework,UILib}/**/*Shorthand.m")

  test_headers = ["AppFramework/Action/GREYAction.h",
                  "AppFramework/Action/GREYActionsShorthand.h",
                  "AppFramework/DistantObject/GREYHostBackgroundDistantObject+GREYApp.h",
                  "AppFramework/Matcher/GREYMatchersShorthand.h",
                  "CommonLib/Assertion/GREYAssertionBlock.h",
                  "CommonLib/Config/GREYConfiguration.h",
                  "CommonLib/DistantObject/GREYHostApplicationDistantObject.h",
                  "CommonLib/DistantObject/GREYTestApplicationDistantObject.h",
                  "CommonLib/Error/GREYErrorConstants.h",
                  "CommonLib/Exceptions/GREYFailureHandler.h",
                  "CommonLib/Exceptions/GREYFrameworkException.h",
                  "CommonLib/GREYDefines.h",
                  "CommonLib/Matcher/GREYElementMatcherBlock.h",
                  "CommonLib/Matcher/GREYMatcher.h",
                  "TestLib/AlertHandling/XCTestCase+GREYSystemAlertHandler.h",
                  "TestLib/Assertion/GREYAssertionDefines.h",
                  "TestLib/Condition/GREYCondition.h",
                  "TestLib/EarlGreyImpl/EarlGrey.h",
                  "AppFramework/Core/GREYElementInteraction.h",
                  "AppFramework/Core/GREYInteraction.h",
                  "AppFramework/Core/GREYInteractionDataSource.h",
                  "AppFramework/Matcher/GREYAllOf.h",
                  "AppFramework/Matcher/GREYAnyOf.h",
                  "AppFramework/Matcher/GREYMatchers.h",
                  "AppFramework/Matcher/GREYNot.h",
                  "AppFramework/Synchronization/GREYAppStateTracker.h",
                  "AppFramework/Synchronization/GREYAppStateTrackerObject.h",
                  "AppFramework/Synchronization/GREYSyncAPI.h",
                  "AppFramework/Synchronization/GREYUIThreadExecutor.h",
                  "CommonLib/GREYConstants.h",
                  "AppFramework/Core/GREYElementInteraction.h",
                  "CommonLib/Assertion/GREYAssertion.h",
                  "CommonLib/Config/GREYConfigKey.h",
                  "CommonLib/Matcher/GREYBaseMatcher.h",
                  "CommonLib/Matcher/GREYDescription.h",
                  "CommonLib/DistantObject/GREYHostBackgroundDistantObject.h",
                  "CommonLib/Assertion/GREYAssertionDefinesPrivate.h",
                  "CommonLib/Config/GREYAppState.h",
                  "CommonLib/GREYDiagnosable.h",
                  "AppFramework/IdlingResources/GREYIdlingResource.h"
        ]

  s.source_files = test_sources
  s.public_header_files = test_headers

  s.frameworks = "XCTest"

  s.platform = :ios, '10.0'
end
