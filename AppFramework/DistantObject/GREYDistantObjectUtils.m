#import "GREYDistantObjectUtils.h"

#import "GREYHostApplicationDistantObject.h"
#import "EDOClientService.h"

BOOL GREYIsTestProcess(void) { return NO; }

NSArray<id> *GREYGetLocalArrayShallowCopy(NSArray<id> *remoteArray) {
  NSMutableArray<id> *localArray = [NSMutableArray array];
  for (id element in remoteArray) {
    [localArray addObject:element];
  }
  return localArray;
}

NSArray<id> *GREYGetRemoteArrayShallowCopy(NSArray<id> *localArray) {
  NSMutableArray<id> *remoteArray = [GREY_REMOTE_CLASS_IN_TEST(NSMutableArray) array];
  for (id element in localArray) {
    [remoteArray addObject:element];
  }
  return remoteArray;
}
