//
//  GREYErrorFormatter.h
//  CommonLib
//
//  Created by Will Said on 6/1/20.
//

#import "GREYError.h"

NS_ASSUME_NONNULL_BEGIN

@interface GREYErrorFormatter: NSObject

- (instancetype)initWithError:(GREYError *)error;

- (NSString *)humanReadableDescription;

@end

NS_ASSUME_NONNULL_END
