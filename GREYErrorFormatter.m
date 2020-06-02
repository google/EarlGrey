//
//  GREYErrorFormatter.m
//  CommonLib
//
//  Created by Will Said on 6/1/20.
//

#import "GREYErrorFormatter.h"

#import "GREYObjectFormatter.h"
#import "GREYInteraction.h"
#import "GREYFatalAsserts.h"
#import "GREYErrorConstants.h"

@interface GREYErrorFormatter ()

@property(readonly, nonatomic) GREYError *error;

@end

@implementation GREYErrorFormatter

#pragma mark - Init

- (instancetype)initWithError:(GREYError *)error {
  self = [super init];
  if (self) {
    _error = error;
  }
  return self;
}

#pragma mark - Public Methods

- (NSString *)humanReadableDescription {
  if (_error.domain == kGREYInteractionErrorDomain &&
      _error.code == kGREYInteractionElementNotFoundErrorCode) {
    return [self _elementNotFoundDescription];
  }
  GREYFatalAssertWithMessage(false, @"Exception type not supported for formatting");
}

#pragma mark - Private Methods

- (NSString *)_formattedHierarchy:(nonnull NSString *)hierarchy {
    NSMutableArray *logger = [[NSMutableArray alloc] init];
    
    [logger addObject:@"UI Hierarchy (ordered by window level, back to front):\n"];

    NSString *windowLegend = @"[Window 1]";
    NSString *axLegend = @"[AX]";
    NSString *uieLegend = @"[UIE]";

    NSDictionary *legendLabels = @{
      windowLegend : @"Back-Most Window",
      axLegend : @"Accessibility",
      uieLegend : @"User Interaction Enabled"
    };
    NSArray *keyOrder = @[ windowLegend, axLegend, uieLegend ];

    NSString *legendDescription = [GREYObjectFormatter formatDictionary:legendLabels
                                                                 indent:kGREYObjectFormatIndent
                                                              hideEmpty:NO
                                                               keyOrder:keyOrder];
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", @"Legend", legendDescription]];
    [logger addObject:_error.appUIHierarchy];
    return [logger componentsJoinedByString:@"\n"];
}

- (NSString *)_elementNotFoundDescription {
  NSMutableArray *logger = [[NSMutableArray alloc] init];
  
  // exception reason
  [logger addObject:[NSString stringWithFormat:@"\n%@\n", _error.localizedDescription]];

  // recovery suggestion
  if (_error.userInfo[kErrorDetailRecoverySuggestionKey]) {
    [logger addObject:[NSString stringWithFormat:@"%@\n",
                       _error.userInfo[kErrorDetailRecoverySuggestionKey]]];
  }
  
  // element matcher
  if (_error.userInfo[kErrorDetailElementMatcherKey]) {
    [logger addObject:[NSString stringWithFormat:@"Element Matcher: \n%@\n",
                       _error.userInfo[kErrorDetailElementMatcherKey]]];
  }

  // search api info, pretty printed (if it was a search)
  if (_error.userInfo[kErrorDetailSearchActionInfoKey]) {
    [logger addObject:[NSString stringWithFormat:@"Search Action Info \n%@\n",
                       _error.userInfo[kErrorDetailSearchActionInfoKey]]];
  }
  
  // screenshots
  for (NSString *key in _error.appScreenshots.allKeys) {
    [logger addObject:[NSString stringWithFormat:@"%@: %@\n", key, _error.appScreenshots[key]]];
  }
  
  // nested error
  if (_error.nestedError) {
    [logger addObject:[NSString stringWithFormat:@"Underlying Error: \n%@\n",
                       _error.nestedError.description]];
  }
  
  // UI hierarchy
  if (_error.appUIHierarchy) {
    [logger addObject:[self _formattedHierarchy:_error.appUIHierarchy]];
  }

  // stack trace
  [logger addObject:[NSString stringWithFormat:@"Stack Trace: %@\n", _error.stackTrace]];
  
  return [logger componentsJoinedByString:@"\n"];
}

@end
