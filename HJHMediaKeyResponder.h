//
//  HJHMediaKeyResponder.h
//  BetterBugs
//
//  Created by Jonghwan Hyeon on 3/10/13.
//  Copyright (c) 2013 Jonghwan Hyeon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HJHMediaKeyResponder;

@protocol HJHMediaKeyResponderDelegate <NSObject>
@optional
- (BOOL)mediaKeyResponder:(HJHMediaKeyResponder *)sender handleKeyDown:(NSEvent *)event;
- (BOOL)mediaKeyResponder:(HJHMediaKeyResponder *)sender handleKeyUp:(NSEvent *)event;
@end

@interface HJHMediaKeyResponder : NSObject
@property (weak) id<HJHMediaKeyResponderDelegate> delegate;

- (id)initWithDelegate:(id<HJHMediaKeyResponderDelegate>)delegate;
+ (id)responderWithDelegate:(id<HJHMediaKeyResponderDelegate>)delegate;

+ (BOOL)isSupportedMediaKey:(unsigned short)keyCode;
@end
