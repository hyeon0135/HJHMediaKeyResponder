//
//  HJHMediaKeyResponder.m
//  BetterBugs
//
//  Created by Jonghwan Hyeon on 3/10/13.
//  Copyright (c) 2013 Jonghwan Hyeon. All rights reserved.
//

#import "HJHMediaKeyResponder.h"

#import <IOKit/hidsystem/ev_keymap.h>
#import "HJHPushingKeyRecognizer.h"

@interface HJHMediaKeyResponder()
@property (nonatomic) CFMachPortRef eventTap;
@property (nonatomic) CFRunLoopSourceRef runLoopSource;

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) CFRunLoopRef runLoop;

@property (nonatomic) HJHPushingKeyRecognizer *pushingNextKeyRecognizer;
@property (nonatomic) HJHPushingKeyRecognizer *pushingPreviousKeyRecognizer;
@end

CGEventRef eventTapHandler(CGEventTapProxy proxy, CGEventType type, CGEventRef coreGraphicsEvent, void *userInfo) {
    NSEvent *event = [NSEvent eventWithCGEvent:coreGraphicsEvent];
    if (event.subtype != NX_SUBTYPE_AUX_CONTROL_BUTTONS) return coreGraphicsEvent;
    
    HJHMediaKeyResponder *responder = (__bridge HJHMediaKeyResponder *)userInfo;
    
    int keyCode = ([event data1] & 0xFFFF0000) >> 16;
    if (keyCode == NX_KEYTYPE_FAST) keyCode = NX_KEYTYPE_NEXT;
    else if (keyCode == NX_KEYTYPE_REWIND) keyCode = NX_KEYTYPE_PREVIOUS;
    
    BOOL isKeyDown = (([event data1] & 0x0000FF00) >> 8) == NSKeyDown;
    
    CGEventRef coreGraphicsKeyboardEvent = CGEventCreateKeyboardEvent(NULL, keyCode, isKeyDown);
    NSEvent *keyboardEvent = [NSEvent eventWithCGEvent:coreGraphicsKeyboardEvent];
    
    __block BOOL preventsDefault = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (isKeyDown) {
            preventsDefault = (BOOL)[responder performSelector:@selector(handleKeyDown:) withObject:keyboardEvent];
        } else {
            preventsDefault = (BOOL)[responder performSelector:@selector(handleKeyUp:) withObject:keyboardEvent];
        }
    });
    if (preventsDefault) return NULL;
    
    return coreGraphicsEvent;
}

@implementation HJHMediaKeyResponder
- (id)initWithDelegate:(id<HJHMediaKeyResponderDelegate>)delegate
{
    self = [super init];
    if (!self) return nil;
    
    self.delegate = delegate;
    
    self.pushingNextKeyRecognizer = [HJHPushingKeyRecognizer recognizerWithTappingKeycode:NX_KEYTYPE_NEXT pushingKeyCode:NX_KEYTYPE_FAST];
    self.pushingPreviousKeyRecognizer = [HJHPushingKeyRecognizer recognizerWithTappingKeycode:NX_KEYTYPE_PREVIOUS pushingKeyCode:NX_KEYTYPE_REWIND];
    
    [self installEventTap];
    
    return self;
}

+ (id)responderWithDelegate:(id<HJHMediaKeyResponderDelegate>)delegate
{
    return [[self alloc] initWithDelegate:delegate];
}

- (BOOL)handleKeyDown:(NSEvent *)event
{
    if (![[self class] isSupportedMediaKey:event.keyCode]) return NO;
    
    HJHPushingKeyRecognizer *recognizer = nil;
    if (event.keyCode == NX_KEYTYPE_NEXT) recognizer = self.pushingNextKeyRecognizer;
    else if (event.keyCode == NX_KEYTYPE_PREVIOUS) recognizer = self.pushingPreviousKeyRecognizer;
    if (recognizer) {
        if (recognizer.state == HJHPushingKeyRecognizerBeforeThresholdState) {
            [recognizer recordKeyDown];
            return YES;
        }
        
        CGEventRef coreGraphicsEvent = CGEventCreateKeyboardEvent(NULL, recognizer.currentKeyCode, true);
        event = [NSEvent eventWithCGEvent:coreGraphicsEvent];
        
        [recognizer recordKeyDown];
    }
    
    if ([self.delegate respondsToSelector:@selector(mediaKeyResponder:handleKeyDown:)]) {
        return [self.delegate mediaKeyResponder:self handleKeyDown:event];
    } else {
        return NO;
    }
}

- (BOOL)handleKeyUp:(NSEvent *)event
{
    if (![[self class] isSupportedMediaKey:event.keyCode]) return NO;
    
    HJHPushingKeyRecognizer *recognizer = nil;
    if (event.keyCode == NX_KEYTYPE_NEXT) recognizer = self.pushingNextKeyRecognizer;
    else if (event.keyCode == NX_KEYTYPE_PREVIOUS) recognizer = self.pushingPreviousKeyRecognizer;
    if (recognizer) {
        CGEventRef coreGraphicsEvent = CGEventCreateKeyboardEvent(NULL, recognizer.currentKeyCode, false);
        event = [NSEvent eventWithCGEvent:coreGraphicsEvent];
        
        [recognizer recordKeyUp];
    }
    
    
    if ([self.delegate respondsToSelector:@selector(mediaKeyResponder:handleKeyUp:)]) {
        return [self.delegate mediaKeyResponder:self handleKeyUp:event];
    } else {
        return NO;
    }
}

+ (BOOL)isSupportedMediaKey:(unsigned short)keyCode
{
    switch (keyCode) {
        case NX_KEYTYPE_PLAY:
        case NX_KEYTYPE_NEXT:
        case NX_KEYTYPE_PREVIOUS:
        case NX_KEYTYPE_FAST:
        case NX_KEYTYPE_REWIND:
            return YES;
            break;
            
        default:
            break;
    }
    
    return NO;
}

- (void)installEventTap
{
    self.eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, CGEventMaskBit(NX_SYSDEFINED), eventTapHandler, (__bridge void *)self);
    self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.eventTap, 0);
    CGEventTapEnable(self.eventTap, true);
    
    self.queue = dispatch_queue_create("Run Loop", NULL);
    dispatch_async(self.queue, ^{
        self.runLoop = CFRunLoopGetCurrent();
        CFRunLoopAddSource(self.runLoop, self.runLoopSource, kCFRunLoopCommonModes);
        CFRunLoopRun();
    });
}

- (void)uninstallEventTap
{
    if (self.runLoop) {
        CFRunLoopStop(self.runLoop);
        self.runLoop = NULL;
    }
    
    if (self.eventTap) {
        CFRelease(self.eventTap);
        self.eventTap = NULL;
    }
    
    if (self.runLoopSource) {
        CFRelease(self.runLoopSource);
        self.runLoopSource = NULL;
    }
}

-(void)dealloc
{
    [self uninstallEventTap];
}
@end
