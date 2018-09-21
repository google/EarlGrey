//
// Copyright 2018 Google Inc.
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

#import "ZoomingScrollViewController.h"

@interface ZoomingScrollViewController ()

/**
 *  The Scroll View containing the image view to zoom into.
 */
@property(nonatomic, weak) IBOutlet UIScrollView *scrollView;

@end

@interface ZoomingScrollViewController ()

@end

@implementation ZoomingScrollViewController {
  UIImageView *_imageView;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.scrollView.delegate = self;
  self.scrollView.accessibilityIdentifier = @"ZoomingScrollView";
  self.scrollView.backgroundColor = [UIColor blueColor];

  // Make the image fit completely inside the scroll view.
  CGSize imageViewSize = _imageView.bounds.size;
  CGSize scrollViewSize = self.scrollView.bounds.size;
  CGFloat widthScale = scrollViewSize.width / imageViewSize.width;
  CGFloat heightScale = scrollViewSize.height / imageViewSize.height;
  CGFloat minimumZoomScale = MIN(widthScale, heightScale);

  self.scrollView.minimumZoomScale = minimumZoomScale;
  self.scrollView.maximumZoomScale = 4;
  self.scrollView.zoomScale = minimumZoomScale;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return _imageView;
}

@end
