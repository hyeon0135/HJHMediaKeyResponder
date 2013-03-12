//
//  HJHPushingKeyRecognizer.m
//  BetterBugs
//
//  Created by Jonghwan Hyeon on 3/11/13.
//  Copyright (c) 2013 Jonghwan Hyeon. All rights reserved.
//

#import "HJHPushingKeyRecognizer.h"

#define DEFAULT_THRESHOLD 5

@interface HJHPushingKeyRecognizer()
@property (nonatomic) int countOfKeyDown;
@end

@implementation HJHPushingKeyRecognizer
- (id)init
{
    self = [super init];
    if (!self) return nil;
    
    self.threshold = DEFAULT_THRESHOLD;
    
    self.tappingKeyCode = 0;
    self.pushingKeyCode = 1;
    
    self.countOfKeyDown = 0;
    
    return self;
}

+ (id)recognizer
{
    return [[self alloc] init];
}

- (id)initWithTappingKeycode:(int)tappingKeyCode pushingKeyCode:(int)pushingKeyCode
{
    self = [self init];
    if (!self) return nil;
    
    self.tappingKeyCode = tappingKeyCode;
    self.pushingKeyCode = pushingKeyCode;
    
    return self;
}

+ (id)recognizerWithTappingKeycode:(int)tappingKeyCode pushingKeyCode:(int)pushingKeyCode
{
    return [[self alloc] initWithTappingKeycode:tappingKeyCode pushingKeyCode:pushingKeyCode];
}

- (void)recordKeyDown
{
    self.countOfKeyDown += 1;
}

- (void)recordKeyUp
{
    self.countOfKeyDown = 0;
}

- (HJHPusingKeyRecognizerState)state
{
    if (self.countOfKeyDown == 0) {
        return HJHPushingKeyRecognizerInitialState;
    } else if (self.countOfKeyDown < self.threshold) {
        return HJHPushingKeyRecognizerBeforeThresholdState;
    } else {
        return HJHPushingKeyRecognizerAfterThresholdStateState;
    }
}

- (BOOL)isPushing
{
    return (self.state == HJHPushingKeyRecognizerAfterThresholdStateState);
}

- (int)currentKeyCode
{
    int keyCode = self.tappingKeyCode;
    if (self.isPushing) keyCode = self.pushingKeyCode;
    
    return keyCode;
}
@end
