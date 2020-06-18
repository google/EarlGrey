#import "Service/Sources/EDORemoteException.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const kEDORemoteExceptionCoderName = @"name";
static NSString *const kEDORemoteExceptionCoderReason = @"reason";
static NSString *const kEDORemoteExceptionCoderStacks = @"callStackSymbols";

@implementation EDORemoteException {
  NSArray<NSString *> *_callStackSymbols;
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithName:(NSExceptionName)name
                      reason:(nullable NSString *)reason
            callStackSymbols:(NSArray<NSString *> *)callStackSymbols {
  self = [super initWithName:name reason:reason userInfo:nil];
  if (self) {
    _callStackSymbols = [callStackSymbols copy];
  }
  return self;
}

- (NSArray<NSString *> *)callStackSymbols {
  return [_callStackSymbols copy];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  // initWithCoder: is not NSException's designated initializer, so we need to encode/decode
  // its properties in subclass and use NSException::initWithName:reason:userInfo: to construct
  // the super class.
  Class stringClass = [NSString class];
  NSString *name = [aDecoder decodeObjectOfClass:stringClass forKey:kEDORemoteExceptionCoderName];
  NSString *reason = [aDecoder decodeObjectOfClass:stringClass
                                            forKey:kEDORemoteExceptionCoderReason];
  self = [super initWithName:name reason:reason userInfo:nil];
  if (self) {
    _callStackSymbols =
        [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[ [NSArray class], stringClass ]]
                                 forKey:kEDORemoteExceptionCoderStacks];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.name forKey:kEDORemoteExceptionCoderName];
  [aCoder encodeObject:self.reason forKey:kEDORemoteExceptionCoderReason];
  [aCoder encodeObject:self.callStackSymbols forKey:kEDORemoteExceptionCoderStacks];
}

@end

NS_ASSUME_NONNULL_END
