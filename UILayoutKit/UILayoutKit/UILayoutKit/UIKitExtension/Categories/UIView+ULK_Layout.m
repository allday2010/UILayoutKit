//
//  UIView+ULK.m
//  UILayoutKit
//
//  Created by Tom Quist on 22.07.12.
//  Copyright (c) 2012 Tom Quist. All rights reserved.
//
//  Modified by towik on 19.07.16.
//  Copyright (c) 2016 towik. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIView+ULK_Layout.h"
#import "UIView+ULK_ViewGroup.h"

#pragma mark - import libs
#include <objc/runtime.h>

#pragma mark -

NSString *const ULKViewAttributeActionTarget = @"__actionTarget";

ULKLayoutMeasureSpec ULKLayoutMeasureSpecMake(CGFloat size, ULKLayoutMeasureSpecMode mode) {
    ULKLayoutMeasureSpec measureSpec;
    measureSpec.size = size;
    measureSpec.mode = mode;
    return measureSpec;
}

ULKViewVisibility ULKViewVisibilityFromString(NSString *visibilityString) {
    ULKViewVisibility visibility = ULKViewVisibilityVisible;
    if ([visibilityString isEqualToString:@"visible"]) {
        visibility = ULKViewVisibilityVisible;
    } else if ([visibilityString isEqualToString:@"invisible"]) {
        visibility = ULKViewVisibilityInvisible;
    } else if ([visibilityString isEqualToString:@"gone"]) {
        visibility = ULKViewVisibilityGone;
    }
    return visibility;
}

ULKLayoutMeasuredSize ULKLayoutMeasuredSizeMake(ULKLayoutMeasuredDimension width, ULKLayoutMeasuredDimension height) {
    ULKLayoutMeasuredSize ret = {width, height};
    return ret;
}

BOOL ULKBOOLFromString(NSString *boolString) {
    return [boolString isEqualToString:@"true"] || [boolString isEqualToString:@"TRUE"] || [boolString isEqualToString:@"yes"] || [boolString isEqualToString:@"YES"] || [boolString boolValue];
}

@implementation UIView (ULK_Layout)

static char identifierKey;
static char minSizeKey;
static char measuredSizeKey;
static char paddingKey;
static char isLayoutRequestedKey;
static char visibilityKey;

- (ULKLayoutMeasuredDimension)ulk_defaultSizeForSize:(CGFloat)size measureSpec:(ULKLayoutMeasureSpec)measureSpec {
    CGFloat result = size;
    ULKLayoutMeasureSpecMode specMode = measureSpec.mode;
    CGFloat specSize = measureSpec.size;
    
    switch (specMode) {
        case ULKLayoutMeasureSpecModeUnspecified:
            result = size;
            break;
        case ULKLayoutMeasureSpecModeAtMost:
        case ULKLayoutMeasureSpecModeExactly:
            result = specSize;
            break;
    }
    ULKLayoutMeasuredDimension ret = {result, ULKLayoutMeasuredStateNone};
    return ret;
}

+ (ULKLayoutMeasuredWidthHeightState)ulk_combineMeasuredStatesCurrentState:(ULKLayoutMeasuredWidthHeightState)curState newState:(ULKLayoutMeasuredWidthHeightState)newState {
    curState.widthState |= newState.widthState;
    curState.heightState |= newState.heightState;
    return curState;
}

/**
 * Utility to reconcile a desired size and state, with constraints imposed
 * by a MeasureSpec.  Will take the desired size, unless a different size
 * is imposed by the constraints.  The returned value is a compound integer,
 * with the resolved size in the {@link #MEASURED_SIZE_MASK} bits and
 * optionally the bit {@link #MEASURED_STATE_TOO_SMALL} set if the resulting
 * size is smaller than the size the view wants to be.
 *
 * @param size How big the view wants to be
 * @param measureSpec Constraints imposed by the parent
 * @return Size information bit mask as defined by
 * {@link #MEASURED_SIZE_MASK} and {@link #MEASURED_STATE_TOO_SMALL}.
 */
+ (ULKLayoutMeasuredDimension)ulk_resolveSizeAndStateForSize:(CGFloat)size measureSpec:(ULKLayoutMeasureSpec)measureSpec childMeasureState:(ULKLayoutMeasuredState)childMeasuredState {
    ULKLayoutMeasuredDimension result = {size, ULKLayoutMeasuredStateNone};
    switch (measureSpec.mode) {
        case ULKLayoutMeasureSpecModeUnspecified:
            result.size = size;
            break;
        case ULKLayoutMeasureSpecModeAtMost:
            if (measureSpec.size < size) {
                result.size = measureSpec.size;
                result.state = ULKLayoutMeasuredStateTooSmall;
            } else {
                result.size = size;
            }
            break;
        case ULKLayoutMeasureSpecModeExactly:
            result.size = measureSpec.size;
            break;
    }
    result.state |= childMeasuredState;
    return result;
}

+ (CGFloat)ulk_resolveSizeForSize:(CGFloat)size measureSpec:(ULKLayoutMeasureSpec)measureSpec {
    return [self ulk_resolveSizeAndStateForSize:size measureSpec:measureSpec childMeasureState:ULKLayoutMeasuredStateNone].size;
}

- (void)setUlk_identifier:(NSString *)identifier {
    objc_setAssociatedObject(self,
                             &identifierKey,
                             identifier,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    static BOOL hasPixateFreestyle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hasPixateFreestyle = (NSClassFromString(@"PixateFreestyle") != NULL);
    });
    if (hasPixateFreestyle) {
        [self setValue:identifier forKey:@"styleId"];
    }
}

- (NSString *)ulk_identifier {
    return objc_getAssociatedObject(self, &identifierKey);
}

- (void)setUlk_visibility:(ULKViewVisibility)visibility {
    ULKViewVisibility curVisibility = self.ulk_visibility;
    [self setHidden:(visibility != ULKViewVisibilityVisible)];
    NSValue *newVisibilityObj = nil;
    switch (visibility) {
        case ULKViewVisibilityGone: {
            static NSValue *visibilityGone;
            if (!visibilityGone) {
                visibilityGone = [[NSValue alloc] initWithBytes:&visibility objCType:@encode(ULKViewVisibility)];
            }
            newVisibilityObj = visibilityGone;
        break;
        }
        case ULKViewVisibilityVisible: {
            static NSValue *visibilityVisible;
            if (!visibilityVisible) {
                visibilityVisible = [[NSValue alloc] initWithBytes:&visibility objCType:@encode(ULKViewVisibility)];
            }
            newVisibilityObj = visibilityVisible;
            break;
        }
        case ULKViewVisibilityInvisible: {
            static NSValue *visibilityInvisible;
            if (!visibilityInvisible) {
                visibilityInvisible = [[NSValue alloc] initWithBytes:&visibility objCType:@encode(ULKViewVisibility)];
            }
            newVisibilityObj = visibilityInvisible;
            break;
        }
    }

    objc_setAssociatedObject(self,
                             &visibilityKey,
                             newVisibilityObj,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ((curVisibility != visibility) && (curVisibility == ULKViewVisibilityGone || visibility == ULKViewVisibilityGone)) {
        [self ulk_requestLayout];
    }
}

- (ULKViewVisibility)ulk_visibility {
    ULKViewVisibility visibility = ULKViewVisibilityVisible;
    NSValue *value = objc_getAssociatedObject(self, &visibilityKey);
    [value getValue:&visibility];
    if (visibility == ULKViewVisibilityVisible && self.isHidden) {
        // Visibility has been set independently
        visibility = ULKViewVisibilityInvisible;
    }
    return visibility;
}

- (CGSize)ulk_minSize {
    CGSize ret = CGSizeZero;
    NSValue *value = objc_getAssociatedObject(self, &minSizeKey);
    [value getValue:&ret];
    return ret;

}

- (void)setUlk_minSize:(CGSize)size {
    NSValue *v = [[NSValue alloc] initWithBytes:&size objCType:@encode(CGSize)];
    objc_setAssociatedObject(self,
                             &minSizeKey,
                             v,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGSize)ulk_suggestedMinimumSize {
    CGSize size = self.ulk_minSize;
    return size;
}

- (void)ulk_setMeasuredDimensionSize:(ULKLayoutMeasuredSize)size {
    NSValue *value = [[NSValue alloc] initWithBytes:&size objCType:@encode(ULKLayoutMeasuredSize)];
    objc_setAssociatedObject(self,
                             &measuredSizeKey,
                             value,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)ulk_clearMeasuredDimensionSize
{
    objc_setAssociatedObject(self,
                             &measuredSizeKey,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ULKLayoutMeasuredSize)ulk_measuredDimensionSize {
    NSValue *value = objc_getAssociatedObject(self, &measuredSizeKey);
    ULKLayoutMeasuredSize ret;
    [value getValue:&ret];
    return ret;
}

- (CGSize)ulk_measuredSize {
    ULKLayoutMeasuredSize size = [self ulk_measuredDimensionSize];
    return CGSizeMake(size.width.size, size.height.size);
}

- (BOOL)ulk_hadMeasured {
    NSValue *value = objc_getAssociatedObject(self, &measuredSizeKey);
    return value != nil;
}

- (void)ulk_onMeasureWithWidthMeasureSpec:(ULKLayoutMeasureSpec)widthMeasureSpec heightMeasureSpec:(ULKLayoutMeasureSpec)heightMeasureSpec {
    CGSize minSize = [self ulk_suggestedMinimumSize];
    ULKLayoutMeasuredSize size;
    size.width = [self ulk_defaultSizeForSize:minSize.width measureSpec:widthMeasureSpec];
    size.height = [self ulk_defaultSizeForSize:minSize.height measureSpec:heightMeasureSpec];
    [self ulk_setMeasuredDimensionSize:size];
}

- (void)ulk_measureWithWidthMeasureSpec:(ULKLayoutMeasureSpec)widthMeasureSpec heightMeasureSpec:(ULKLayoutMeasureSpec)heightMeasureSpec {
    [self ulk_onMeasureWithWidthMeasureSpec:widthMeasureSpec heightMeasureSpec:heightMeasureSpec];
}

- (void)ulk_onLayoutWithFrame:(CGRect)frame didFrameChange:(BOOL)changed {
    
}

- (CGRect)ulk_roundFrame:(CGRect)frame {
    frame.origin.x = ceilf(frame.origin.x);
    frame.origin.y = ceilf(frame.origin.y);
    frame.size.width = ceilf(frame.size.width);
    frame.size.height = ceilf(frame.size.height);
    return frame;
}

- (BOOL)ulk_setFrame:(CGRect)frame
{
    CGRect oldFrame = self.frame;
    CGRect newFrame = [self ulk_roundFrame:frame];
    BOOL changed = !CGRectEqualToRect(oldFrame, newFrame);
    if (changed) {
        self.frame = newFrame;
    }
    
    return changed;
}

- (void)ulk_layoutWithFrame:(CGRect)frame {
    BOOL changed = [self ulk_setFrame:frame];
    [self ulk_onLayoutWithFrame:frame didFrameChange:changed];
    if (changed) {
        NSString *identifier = self.ulk_identifier;
        if (identifier != nil) {
        }
        else {
        }
    }
}

- (UIEdgeInsets)ulk_padding {
    NSValue *value = objc_getAssociatedObject(self, &paddingKey);
    return [value UIEdgeInsetsValue];
}

- (void)setUlk_padding:(UIEdgeInsets)padding {
    UIEdgeInsets prevPadding = self.ulk_padding;
    if (!UIEdgeInsetsEqualToEdgeInsets(prevPadding, padding)) {
        objc_setAssociatedObject(self,
                                 &paddingKey,
                                 [NSValue valueWithUIEdgeInsets:padding],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self ulk_requestLayout];
    }
}

/**
 * <p>Return the offset of the widget's text baseline from the widget's top
 * boundary. If this widget does not support baseline alignment, this
 * method returns -1. </p>
 *
 * @return the offset of the baseline within the widget's bounds or -1
 *         if baseline alignment is not supported
 */
- (CGFloat)ulk_baseline {
    return -1;
}

- (ULKLayoutMeasuredWidthHeightState)ulk_measuredState {
    ULKLayoutMeasuredWidthHeightState ret;
    ULKLayoutMeasuredSize measuredSize = [self ulk_measuredDimensionSize];
    ret.widthState = measuredSize.width.state;
    ret.heightState = measuredSize.height.state;
    return ret;
}

- (void)ulk_requestLayout {
    [self setNeedsLayout];
    [self ulk_clearMeasuredDimensionSize];
    if (self.superview != nil
        && (self.superview.layoutWidth == ULKLayoutParamsSizeWrapContent
            || self.superview.layoutHeight == ULKLayoutParamsSizeWrapContent)) {
        [self.superview ulk_requestLayout];
    }
}

- (void)ulk_onFinishInflate {
    
}

- (UIView *)ulk_findViewById:(NSString *)identifier {
    UIView *ret = nil;
    if (self.ulk_isViewGroup) {
        ret = [self ulk_findViewTraversal:identifier];
    } else if ([self.ulk_identifier isEqualToString:identifier]) {
        ret = self;
    }
    return ret;
}

@end
