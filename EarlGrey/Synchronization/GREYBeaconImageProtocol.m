//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Synchronization/GREYBeaconImageProtocol.h"

/**
 *  Beacon image that must be served, this is lazily loaded.
 */
static NSData *gBeaconImagePNGData;

/**
 *  Error domain for errors occuring in GREYBeaconImageProtocol.
 */
static NSString *const kBeaconImageProtocolErrorDomain =
    @"com.google.earlgrey.BeaconImageProtocolErrorDomain";

NSString *const kGREYBeaconScheme = @"earlgreybeacon";
NSString *const kGREYBeaconImagePath = @"earlgrey/beacon.png";

@implementation GREYBeaconImageProtocol

/**
 *  @return @c YES for @c EARLGREY_BEACON_IMAGE_NAME requests, @c NO otherwise.
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
  return [request.URL.scheme isEqualToString:kGREYBeaconScheme];
}

// Required overidden method.
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
  return request;
}

- (NSCachedURLResponse *)cachedResponse {
  return nil; // returning nil to indicate that supported URLs are never cached.
}

- (void)startLoading {
  if ([self.request.URL.absoluteString hasSuffix:kGREYBeaconImagePath]) {
    // This indicates that we got a request to serve the beacon image.
    // Create the beacon image if not already done so.
    static dispatch_once_t token = 0;
    dispatch_once(&token, ^{
      // Create a 1 pixel invisible image.
      UIGraphicsBeginImageContext(CGSizeMake(1, 1));
      CGContextRef context = UIGraphicsGetCurrentContext();
      CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0 alpha:0].CGColor);
      CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
      gBeaconImagePNGData =
          UIImagePNGRepresentation(UIGraphicsGetImageFromCurrentImageContext());
      UIGraphicsEndImageContext();
    });

    // Create a HTTP response with the image.
    NSDictionary *headers = @{ @"Content-Type": @"image/png" };
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:headers];

    // Serve the image response.
    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:gBeaconImagePNGData];
    [self.client URLProtocolDidFinishLoading:self];
  } else {
    NSString *errorDescription =
        [NSString stringWithFormat:@"Unknown request %@ received.", self.request];
    NSError *error = [NSError errorWithDomain:kBeaconImageProtocolErrorDomain
                                         code:404
                                     userInfo:@{ NSLocalizedDescriptionKey : errorDescription }];
    [self.client URLProtocol:self didFailWithError:error];
  }
}

// Required overidden method.
- (void)stopLoading {
}

@end
