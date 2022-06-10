#import "GREYDistantObjectUtils.h"

#import "GREYTestApplicationDistantObject.h"

BOOL GREYIsTestProcess(void) { return YES; }

NSArray<id> *GREYGetLocalArrayShallowCopy(NSArray<id> *remoteArray) {
  NSMutableArray<id> *localArray = [NSMutableArray array];
  for (id element in remoteArray) {
    [localArray addObject:element];
  }
  return localArray;
}

NSArray<id> *GREYGetRemoteArrayShallowCopy(NSArray<id> *localArray) {
  NSMutableArray<id> *remoteArray = [GREY_REMOTE_CLASS_IN_APP(NSMutableArray) array];
  for (id element in localArray) {
    [remoteArray addObject:element];
  }
  return remoteArray;
}
