//
//  ULKClipDrawable.h
//  UILayoutKit
//
//  Created by Tom Quist on 07.01.13.
//  Copyright (c) 2013 Tom Quist. All rights reserved.
//

#import "UILayoutKit.h"

typedef NS_ENUM(NSInteger, ULKClipDrawableOrientation) {
    ULKClipDrawableOrientationNone = 0,
    ULKClipDrawableOrientationHorizontal = 1,
    ULKClipDrawableOrientationVertical = 2
};

@interface ULKClipDrawable : ULKDrawable <ULKDrawableDelegate>

@end

@interface ULKClipDrawableConstantState : ULKDrawableConstantState

@end