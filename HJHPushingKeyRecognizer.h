//
//  HJHPushingKeyRecognizer.h
//  BetterBugs
//
//  Created by Jonghwan Hyeon on 3/11/13.
//  Copyright (c) 2013 Jonghwan Hyeon. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    HJHPushingKeyRecognizerInitialState,
    HJHPushingKeyRecognizerBeforeThresholdState,
    HJHPushingKeyRecognizerAfterThresholdStateState,
};
typedef NSInteger HJHPusingKeyRecognizerState;

@interface HJHPushingKeyRecognizer : NSObject
- (id)init;
+ (id)recognizer;

- (id)initWithTappingKeycode:(int)tappingKeyCode pushingKeyCode:(int)pushingKeyCode;
+ (id)recognizerWithTappingKeycode:(int)tappingKeyCode pushingKeyCode:(int)pushingKeyCode;

@property (nonatomic) int threshold;

@property (nonatomic) int tappingKeyCode;
@property (nonatomic) int pushingKeyCode;

@property (readonly) HJHPusingKeyRecognizerState state;
@property (readonly) BOOL isPushing;
@property (readonly) int currentKeyCode;

- (void)recordKeyDown;
- (void)recordKeyUp;
- (BOOL)isPushing;
@end
