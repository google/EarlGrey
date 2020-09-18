#import "GREYDistantObjectUtils.h"

#import "GREYHostApplicationDistantObject.h"
#import "GREYTestApplicationDistantObject.h"
#import "EDOClientService.h"
#import "EDOHostService.h"
#import "EDOServicePort.h"

NSArray<id> *GREYGetLocalArrayShallowCopy(NSArray<id> *remoteArray) {
  NSMutableArray<id> *localArray = [NSMutableArray array];
  for (id element in remoteArray) {
    [localArray addObject:element];
  }
  return localArray;
}

NSArray<id> *GREYGetRemoteArrayShallowCopy(NSArray<id> *localArray) {
  static BOOL isTestProcess;
  static dispatch_once_t once_token;
  dispatch_once(&once_token, ^{
    UInt16 testPort = GREYHostApplicationDistantObject.testPort;
    UInt16 localProcessPort =
        [EDOHostService serviceForOriginatingQueue:dispatch_get_main_queue()].port.port;
    isTestProcess = testPort == localProcessPort;
  });

  Class remoteArrayClass = isTestProcess ? GREY_REMOTE_CLASS_IN_APP(NSMutableArray)
                                         : GREY_REMOTE_CLASS_IN_TEST(NSMutableArray);
  NSMutableArray<id> *remoteArray = [remoteArrayClass array];
  for (id element in localArray) {
    [remoteArray addObject:element];
  }
  return remoteArray;
}
