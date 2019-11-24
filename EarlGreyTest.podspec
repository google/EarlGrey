# Install in UI test target using: pod 'EarlGreyTest'
Pod::Spec.new do |s|

  s.name = "EarlGreyTest"
  s.version = "2.1.0"
  s.summary = "iOS UI Automation Test Framework"
  s.homepage = "https://github.com/google/EarlGrey"
  s.author = "Google LLC."
  s.summary = 'EarlGrey is a native iOS UI automation test framework that enables you to write clear, concise tests.\\n\\n'\
                'With the EarlGrey framework, you have access to enhanced synchronization features. EarlGrey automatically'\
                ' synchronizes with the UI, network requests, and various queues, but still allows you to manually implement'\
                ' customized timings, if needed.\\n\\nEarlGrey’s synchronization features help ensure that the UI is in a'\
                ' steady state before actions are performed. This greatly increases test stability and makes tests highly'\
                ' repeatable.\\n\\nEarlGrey works in conjunction with the XCTest framework and integrates with Xcode’s'\
                ' Test Navigator so you can run tests directly from Xcode or the command line (using xcodebuild).'
  s.license = { :type => "Apache 2.0", :file => "LICENSE" }

  s.source = { :git => "https://github.com/google/EarlGrey.git", :tag => "2.1.0" }

  s.dependency "eDistantObject"

  s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/EarlGreyTest/**" "${PODS_ROOT}/eDistantObject/"', 'USER_HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/EarlGreyTest/**" "${PODS_ROOT}/eDistantObject/"' }

  test_sources = Dir.glob("{TestLib,CommonLib}/**/*.{m,h}") +
                Dir.glob("{AppFramework,UILib}/**/*.h") +
                Dir.glob("{TestLib,CommonLib,UILib}/**/*Stub.m") +
                Dir.glob("{TestLib,CommonLib,AppFramework,UILib}/**/*Shorthand.m")

  public_header_files = ["AppFramework/Action/GREYAction.h",
                  "AppFramework/Action/GREYActionsShorthand.h",
                  "AppFramework/Core/GREYElementInteraction.h",
                  "AppFramework/Core/GREYInteraction.h",
                  "AppFramework/Core/GREYInteractionDataSource.h",
                  "AppFramework/DistantObject/GREYHostBackgroundDistantObject+GREYApp.h",
                  "AppFramework/IdlingResources/GREYIdlingResource.h",
                  "AppFramework/Matcher/GREYAllOf.h",
                  "AppFramework/Matcher/GREYAnyOf.h",
                  "AppFramework/Matcher/GREYMatchers.h",
                  "AppFramework/Matcher/GREYMatchersShorthand.h",
                  "AppFramework/Synchronization/GREYAppStateTracker.h",
                  "AppFramework/Synchronization/GREYAppStateTrackerObject.h",
                  "AppFramework/Synchronization/GREYSyncAPI.h",
                  "AppFramework/Synchronization/GREYUIThreadExecutor.h",
                  "CommonLib/Assertion/GREYAssertion.h",
                  "CommonLib/Assertion/GREYAssertionBlock.h",
                  "CommonLib/Assertion/GREYAssertionDefinesPrivate.h",
                  "CommonLib/Config/GREYAppState.h",
                  "CommonLib/Config/GREYConfigKey.h",
                  "CommonLib/Config/GREYConfiguration.h",
                  "CommonLib/DistantObject/GREYHostApplicationDistantObject.h",
                  "CommonLib/DistantObject/GREYHostBackgroundDistantObject.h",
                  "CommonLib/DistantObject/GREYTestApplicationDistantObject.h",
                  "CommonLib/Error/GREYErrorConstants.h",
                  "CommonLib/Exceptions/GREYFailureHandler.h",
                  "CommonLib/Exceptions/GREYFrameworkException.h",
                  "CommonLib/GREYConstants.h",
                  "CommonLib/GREYDefines.h",
                  "CommonLib/GREYDiagnosable.h",
                  "CommonLib/Matcher/GREYBaseMatcher.h",
                  "CommonLib/Matcher/GREYDescription.h",
                  "CommonLib/Matcher/GREYElementMatcherBlock.h",
                  "CommonLib/Matcher/GREYMatcher.h",
                  "TestLib/AlertHandling/XCTestCase+GREYSystemAlertHandler.h",
                  "TestLib/Assertion/GREYAssertionDefines.h",
                  "TestLib/Assertion/GREYWaitFunctions.h",
                  "TestLib/Condition/GREYCondition.h",
                  "TestLib/EarlGreyImpl/EarlGrey.h",
        ]

  s.source_files = test_sources
  s.public_header_files = public_header_files

  s.frameworks = "XCTest"

  s.platform = :ios, '10.0'
end
