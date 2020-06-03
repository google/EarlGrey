//
//  GREYErrorFormatter.h
//  CommonLib
//
//  Created by Will Said on 6/1/20.
//

#import "GREYError.h"

NS_ASSUME_NONNULL_BEGIN

@interface GREYErrorFormatter: NSObject

/**
 * For a given @c hierarchy, create a human-readable hierarchy
 * including the legend.
 *
 * @param hierarchy The string representation of the App UI Hierarchy
 *
 * @return The formatted hierarchy and legend to be printed on the console
*/
+ (NSString *)formattedHierarchy:(nonnull NSString *)hierarchy;

/**
 * For a given @c error, create a GREYErrorFormatter to provide a formattedDescription.
 *
 * @param error The GREYError used to format the description
 *
 * @return An instance of GREYErrorFormatter
*/
- (instancetype)initWithError:(GREYError *)error;

/**
 * Create a human-readable formatted string for the GREYError,
 * depending on its code and domain.
 *
 * @return The full description of the error including its nested errors
 *          suitable for output to the user.
*/
- (NSString *)formattedDescription;

@end

NS_ASSUME_NONNULL_END
