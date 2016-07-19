//
//  TextView.h
//  UILayoutKit
//
//  Created by Tom Quist on 22.07.12.
//  Copyright (c) 2012 Tom Quist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ULKTextView : UILabel {
    UIControlContentVerticalAlignment _contentVerticalAlignment;
}

@property (nonatomic, assign) UIControlContentVerticalAlignment contentVerticalAlignment;

@end
