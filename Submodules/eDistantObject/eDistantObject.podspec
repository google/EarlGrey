Pod::Spec.new do |s|
  s.name = "eDistantObject"
  s.version = "0.9.1"
  s.summary = "ObjC and Swift remote invocation framework"
  s.homepage = "https://github.com/google/eDistantObject"
  s.author = "Google LLC."
  s.description = <<-DESC
            eDistantObject provides users an easy way to make remote method invocations between
            processes in Objective-C and Swift without explicitly constructing RPC structures.
            DESC
  s.license = { :type => "Apache 2.0", :file => "LICENSE" }
  s.source = { :git => "https://github.com/google/eDistantObject.git", :tag => "0.9.1" }

  s.public_header_files = %w[Service/Sources/EDOClientService.h
                             Service/Sources/EDOClientServiceStatsCollector.h
                             Service/Sources/EDOHostNamingService.h
                             Service/Sources/EDOHostService.h
                             Service/Sources/EDORemoteException.h
                             Service/Sources/EDORemoteVariable.h
                             Service/Sources/EDOServiceError.h
                             Service/Sources/EDOServiceException.h
                             Service/Sources/EDOServicePort.h
                             Service/Sources/NSObject+EDOBlacklistedType.h
                             Service/Sources/NSObject+EDOValueObject.h
                             Service/Sources/NSObject+EDOWeakObject.h
                             Device/Sources/EDODeviceConnector.h
                             Device/Sources/EDODeviceDetector.h
                           ]

  s.pod_target_xcconfig = { "HEADER_SEARCH_PATHS" => "${PODS_ROOT}/eDistantObject" }
  s.source_files = "Channel/Sources/*.{m,h}", "Device/Sources/*.{m,h}",
                   "Measure/Sources/*.{m,h}", "Service/Sources/*.{m,h}"

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.10"
end
