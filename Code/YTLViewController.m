//
//  YTLViewController.m
//  TouchLong
//
//  Created by Kelan Champagne on 2/12/14.
//  Copyright (c) 2014 Kelan Champagne. All rights reserved.
//

#import "YTLViewController.h"

#import <AudioToolbox/AudioToolbox.h>


// Helper functions
CGPoint YTLCenterOfRect(CGRect rect);
CGPoint YTLPointDelta(CGPoint initial, CGPoint final);
CGFloat YTLPointLength(CGPoint p);


@interface YTLViewController ()
@end


@implementation YTLViewController {
    // Views
    UIView *_dotView;
    UILabel *_label;

    UIPanGestureRecognizer *_panGR;
    CGPoint _currentTouchLocationInView; // in self.view
    NSDate *_startTime;

    // Animation
    CGFloat _animTimeInterval;
    NSTimer *_animTimer;
    CGPoint _currentVelocity;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    CGSize s = self.view.bounds.size;

    self.view.backgroundColor = [UIColor blueColor];
    self.view.frame = self.window.bounds;
    [self.window addSubview:self.view];

    _dotView = [UIView new];
    CGFloat dotSize = 50.0;
    _dotView.frame = CGRectMake((s.width - 2 * dotSize) / 2,
                                -dotSize,
                                dotSize,
                                dotSize);
    _dotView.backgroundColor = [UIColor yellowColor];
    _dotView.layer.cornerRadius = _dotView.frame.size.height / 2.0;
    [self.view addSubview:_dotView];

    _panGR = [[UIPanGestureRecognizer alloc]
              initWithTarget:self
              action:@selector(handlePanGR:)];
    [self.view addGestureRecognizer:_panGR];
//    _dotView.userInteractionEnabled = YES;
//    self.view.userInteractionEnabled = YES;

    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc]
                                     initWithTarget:self
                                     action:@selector(handlePanGR:)];
    [self.view addGestureRecognizer:tapGR];

    _label = [UILabel new];
    _label.frame = CGRectMake(10.0, 20.0, s.width - 20.0, 40.0);
    _label.textColor = [UIColor whiteColor];
    _label.text = @"Touch the screen to begin.";
    _label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_label];

    _animTimeInterval = 0.02;
}

- (BOOL) prefersStatusBarHidden { return YES; }

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Gesture Recognizers

- (void) handlePanGR:(UIPanGestureRecognizer *)gr
{
    if (gr == _panGR) {
        if (gr.state == UIGestureRecognizerStateBegan) {
            _currentTouchLocationInView = [gr locationInView:self.view];
            [self startGame];
        }
        else if (_panGR.state == UIGestureRecognizerStateChanged) {
            _currentTouchLocationInView = [gr locationInView:self.view];
        }
        else if (_panGR.state == UIGestureRecognizerStateCancelled) {
            [self endGameFromCollision:YES];
        }
        else if (_panGR.state == UIGestureRecognizerStateFailed ||
                 _panGR.state == UIGestureRecognizerStateEnded) {
            [self endGameFromCollision:NO];
        }
    }
}

#pragma mark - Game

- (void) startGame
{
    [UIView animateWithDuration:0.15 animations:^{
        _label.textColor = [UIColor blackColor];
        self.view.backgroundColor = [UIColor yellowColor];
        _dotView.backgroundColor = [UIColor blueColor];
    }];
    _startTime = [NSDate new];
    _animTimer = [NSTimer scheduledTimerWithTimeInterval:_animTimeInterval
                                                  target:self
                                                selector:@selector(animTimerFired:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void) endGameFromCollision:(BOOL)collided
{
    // stop the animation
    [_animTimer invalidate];
    _animTimer = nil;

    if (collided) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }

    _label.text = [NSString stringWithFormat:@"%@  (%0.2f seconds)",
                   collided ? @"It got you!" : @"You let go!",
                   -1 * [_startTime timeIntervalSinceNow]];

    [UIView animateWithDuration:collided ? 0.15 : 0.3
                     animations:^{
        _label.textColor = [UIColor whiteColor];
        _dotView.backgroundColor = [UIColor whiteColor];
        self.view.backgroundColor = [UIColor redColor];
    }];

}

#pragma mark - Animation

- (void) animTimerFired:(NSTimer *)timer
{
    // Move the point constantly away from your finger
    CGPoint currentDotCenter = _dotView.center; YTLCenterOfRect(_dotView.frame);

    CGPoint delta = YTLPointDelta(currentDotCenter, _currentTouchLocationInView);

    // Check if the dot is too close to the finger
    if (YTLPointLength(delta) < 40.0) {
        // disabling a GR cancles it if it's in progress
        _panGR.enabled = NO;
        _panGR.enabled = YES;
        return;
    }

    // damp the velocity
    const CGFloat dampFactor = 0.9;
    _currentVelocity.x *= dampFactor;
    _currentVelocity.y *= dampFactor;

    // accelerate it towards your finger
    const CGFloat accelFactor = 0.5;
    _currentVelocity.x += delta.x * accelFactor;
    _currentVelocity.y += delta.y * accelFactor;

    // move the dot by the velocity
    currentDotCenter.x += _currentVelocity.x * _animTimeInterval;
    currentDotCenter.y += _currentVelocity.y * _animTimeInterval;
    _dotView.center = currentDotCenter;

//    NSLog(@"delta = %0.2f %0.2f  velocity=%0.2f %0.2f",
//          delta.x, delta.y,
//          _currentVelocity.x, _currentVelocity.y);

    _label.text =
    _label.text = [NSString stringWithFormat:@"Don't let go!  (%0.2f seconds)",
                   -1 * [_startTime timeIntervalSinceNow]];
}

@end


#pragma mark - Helper functions

inline CGPoint YTLCenterOfRect(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect),
                       CGRectGetMidY(rect));
}

inline CGPoint YTLPointDelta(CGPoint initial, CGPoint final)
{
    return CGPointMake(final.x - initial.x,
                       final.y - initial.y);
}

inline CGFloat YTLPointLength(CGPoint p)
{
    return sqrtf((p.x * p.x) + (p.y * p.y));
}
