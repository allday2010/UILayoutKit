//
//  ULKResourceStateList.m
//  UILayoutKit
//
//  Created by Tom Quist on 07.12.12.
//  Copyright (c) 2012 Tom Quist. All rights reserved.
//

#import "ULKResourceStateList.h"
#import "ULKResourceStateItem+ULK_Internal.h"
#import "ULKResourceStateList+ULK_Internal.h"
#import "TBXML.h"
#import "UIView+ULK_Layout.h"

@interface ULKResourceStateList ()

@property (nonatomic, strong) NSArray *internalItems;

@end

@implementation ULKResourceStateList

- (instancetype)init {
    self = [super init];
    if (self) {
        self.internalItems = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (UIControlState)controlStateForAttribute:(NSString *)attributeName {
    UIControlState controlState = UIControlStateNormal;
    if ([attributeName isEqualToString:@"state_disabled"]) {
        controlState |= UIControlStateDisabled;
    } else if ([attributeName isEqualToString:@"state_highlighted"]) {
        controlState |= UIControlStateHighlighted;
    } else if ([attributeName isEqualToString:@"state_selected"]) {
        controlState |= UIControlStateSelected;
    }
    return controlState;
}

+ (UIControlState)controlStateFromElement:(TBXMLElement *)element {
    __block UIControlState controlState = UIControlStateNormal;
    [TBXML iterateAttributesOfElement:element withBlock:^(TBXMLAttribute *attribute, NSString *attributeName, NSString *attributeValue) {
        NSRange prefixRange = [attributeName rangeOfString:@":"];
        if (prefixRange.location != NSNotFound) {
            attributeName = [attributeName substringFromIndex:(prefixRange.location+1)];
        }
        BOOL value = ULKBOOLFromString(attributeValue);
        if (value) {
            controlState |= [self controlStateForAttribute:attributeName];
        }
    }];
    return controlState;
}

+ (ULKResourceStateItem *)createItemWithControlState:(UIControlState)controlState fromElement:(TBXMLElement *)element {
    ULKResourceStateItem *ret = [[ULKResourceStateItem alloc] initWithControlState:controlState];
    return ret;
}

+ (instancetype)inflateParser:(TBXML *)parser {
    ULKResourceStateList *ret = nil;
    TBXMLElement *root = parser.rootXMLElement;
    if ([[TBXML elementName:root] isEqualToString:@"selector"]) {
        ret = [[self alloc] init];
        NSMutableArray *mutableItems = [[NSMutableArray alloc] init];
        TBXMLElement *child = root->firstChild;
        if (child != nil) {
            do {
                UIControlState controlState = [self controlStateFromElement:child];
                ULKResourceStateItem *item = [self createItemWithControlState:controlState fromElement:child];
                if (item != nil) {
                    [mutableItems addObject:item];
                }
            } while ((child = child->nextSibling));
            
        }
        NSArray *nonMutableItems = [[NSArray alloc] initWithArray:mutableItems];
        ret.internalItems = nonMutableItems;
    }
    return ret;
}

+ (instancetype)createFromXMLData:(NSData *)data {
    if (data == nil) return nil;
    ULKResourceStateList *ret = nil;
    NSError *error = nil;
    TBXML *xml = [TBXML tbxmlWithXMLData:data error:&error];
    if (error == nil) {
        ret = [self inflateParser:xml];
    } else {
        NSLog(@"Could not parse resource state list: %@", error);
    }
    return ret;
}

+ (instancetype)createFromXMLURL:(NSURL *)url {
    return [self createFromXMLData:[NSData dataWithContentsOfURL:url]];
}

- (NSArray *)items {
    return _internalItems;
}

- (ULKResourceStateItem *)itemForControlState:(UIControlState)controlState {
    ULKResourceStateItem *ret = nil;
    for (ULKResourceStateItem *item in self.items) {
        if ((item.controlState & controlState) == item.controlState) {
            ret = item;
            break;
        }
    }
    return ret;
}

@end
