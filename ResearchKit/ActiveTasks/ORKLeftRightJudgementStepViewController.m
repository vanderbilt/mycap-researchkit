/*
 Copyright (c) 2020, Dr David W. Evans. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ORKLeftRightJudgementStepViewController.h"
#import "ORKActiveStepView.h"
#import "ORKLeftRightJudgementContentView.h"
#import "ORKActiveStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"
#import "ORKLeftRightJudgementResult.h"
#import "ORKResult_Private.h"
#import "ORKCollectionResult_Private.h"
#import "ORKLeftRightJudgementStep.h"
#import "ORKHelpers_Internal.h"
#import "ORKBorderedButton.h"
#import "ORKNavigationContainerView_Internal.h"


@interface ORKLeftRightJudgementStepViewController ()

@property (nonatomic, strong) ORKLeftRightJudgementContentView *leftRightJudgementContentView;


@end


@implementation ORKLeftRightJudgementStepViewController {
    
    NSMutableArray *_results;
    NSTimeInterval _startTime;
    NSTimer *_interStimulusIntervalTimer;
    NSTimer *_timeoutTimer;
    NSTimer *_timeoutNotificationTimer;
    NSTimer *_displayAnswerTimer;
    NSArray *_imageQueue;
    NSArray *_imagePaths;
    NSInteger _imageCount;
    NSInteger _leftCount;
    NSInteger _rightCount;
    NSInteger _leftSumCorrect;
    NSInteger _rightSumCorrect;
    NSInteger _timedOutCount;
    double _percentTimedOut;
    double _leftPercentCorrect;
    double _rightPercentCorrect;
    double _meanLeftDuration;
    double _varianceLeftDuration;
    double _stdLeftDuration;
    double _prevMl;
    double _newMl;
    double _prevSl;
    double _newSl;
    double _meanRightDuration;
    double _varianceRightDuration;
    double _stdRightDuration;
    double _prevMr;
    double _newMr;
    double _prevSr;
    double _newSr;
    BOOL _match;
    BOOL _timedOut;
}

- (instancetype)initWithStep:(ORKStep *)step {
    self = [super initWithStep:step];
    
    if (self) {
        self.suspendIfInactive = YES;
    }
    return self;
}

- (ORKLeftRightJudgementStep *)leftRightJudgementStep {
    return (ORKLeftRightJudgementStep *)self.step;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _results = [NSMutableArray new];
    [self configureInstructions];
    [self setupCustomView];
}

- (void)setupCustomView {
    _leftRightJudgementContentView = [ORKLeftRightJudgementContentView new];
    _leftRightJudgementContentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.activeStepView.activeCustomView = _leftRightJudgementContentView;
        
    NSLayoutConstraint *center = [NSLayoutConstraint
                                  constraintWithItem:_leftRightJudgementContentView
                                  attribute:NSLayoutAttributeCenterX
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:self.activeStepView
                                  attribute:NSLayoutAttributeCenterX
                                  multiplier:1.0
                                  constant:0.0];
    
    NSLayoutConstraint *width = [NSLayoutConstraint
                                 constraintWithItem:_leftRightJudgementContentView
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                 toItem:self.activeStepView
                                 attribute:NSLayoutAttributeWidth
                                 multiplier:1.0
                                 constant:0.0];
    
    // Height set to 75% of containing view
    NSLayoutConstraint *height = [NSLayoutConstraint
                                  constraintWithItem:_leftRightJudgementContentView
                                  attribute:NSLayoutAttributeHeight
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:self.activeStepView
                                  attribute:NSLayoutAttributeHeight
                                  multiplier:0.75
                                  constant:0.0];
    
    // Pin bottom to bottom of containing view
    NSLayoutConstraint *bottom = [NSLayoutConstraint
                                  constraintWithItem:_leftRightJudgementContentView
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:self.activeStepView
                                  attribute:NSLayoutAttributeBottom
                                  multiplier:1.0
                                  constant:0.0];
    
    [self.activeStepView addConstraints:@[center, width, height, bottom]];
}

- (void)setupButtons {
    [self.leftRightJudgementContentView.leftButton addTarget:self
                                       action:@selector(buttonPressed:)
                             forControlEvents:UIControlEventTouchUpInside];
    [self.leftRightJudgementContentView.rightButton addTarget:self
                                       action:@selector(buttonPressed:)
                             forControlEvents:UIControlEventTouchUpInside];
    [self setButtonsDisabled]; // buttons should not appear until a question starts
}

- (void)configureInstructions {
    NSString *instruction;
    if ([self leftRightJudgementStep].imageOption == ORKPredefinedTaskImageOptionHands) {
        instruction= ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_TASK_STEP_TEXT_HAND", nil);
    } else if ([self leftRightJudgementStep].imageOption == ORKPredefinedTaskImageOptionFeet) {
        instruction= ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_TASK_STEP_TEXT_FOOT", nil);
    }
    [self.activeStepView updateText:instruction];
}

- (void)configureCountText {
    NSString *countText = [NSString stringWithFormat:
                       ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_TASK_IMAGE_COUNT", nil),
                       ORKLocalizedStringFromNumber(@(_imageCount)),
                       ORKLocalizedStringFromNumber(@([self leftRightJudgementStep].numberOfAttempts))];
    self.leftRightJudgementContentView.countText = countText;
}

- (void)startTimeoutTimer {
    NSTimeInterval timeout = [self leftRightJudgementStep].timeout;
    if (timeout > 0) {
        _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                         target:self
                                                       selector:@selector(timeoutTimerDidFire)
                                                       userInfo:nil
                                                        repeats:NO];
    }
}

- (void)timeoutTimerDidFire {
    [_timeoutTimer invalidate];
    double duration = [self reactionTime];
    NSString *sidePresented = [self sidePresented];
    NSString *view = [self viewPresented];
    NSString *orientation = [self orientationPresented];
    NSInteger rotation = [self rotationPresented];
    NSString *sideSelected = @"None";
    _match = NO;
    _timedOut = YES;
    _timedOutCount++;
    [self calculatePercentagesForSides:sidePresented andTimeouts:_timedOut];
    [self createResultfromImage:[self nextFileNameInQueue] withView:view inRotation:rotation inOrientation:orientation matching:_match sidePresented:sidePresented withSideSelected:sideSelected inDuration:duration];
    [self displayTimeoutNotification:sidePresented];
}

-(void)displayTimeoutNotification:(NSString *)sidePresented {
    [self hideImage];
    [self setButtonsDisabled];
    NSString *timeoutText = ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_TIMEOUT_NOTIFICATION", nil);
    self.leftRightJudgementContentView.timeoutText = timeoutText;
    if ([self leftRightJudgementStep].shouldDisplayAnswer) {
    self.leftRightJudgementContentView.answerText = [self answerForSidePresented:sidePresented];
    }
    _timeoutNotificationTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                                 target:self
                                                               selector:@selector(startInterStimulusInterval)
                                                               userInfo:nil
                                                                repeats:NO];
}

- (NSString *)answerForSidePresented:(NSString *)sidePresented {
    [self hideImage];
    [self setButtonsDisabled];
    NSString *answerText;
    if ([self leftRightJudgementStep].imageOption == ORKPredefinedTaskImageOptionHands) {
        if ([sidePresented isEqualToString: @"Left"]) {
            answerText = ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_ANSWER_LEFT_HAND", nil);
        } else if ([sidePresented isEqualToString: @"Right"]) {
            answerText = ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_ANSWER_RIGHT_HAND", nil);
        }
    } else if ([self leftRightJudgementStep].imageOption == ORKPredefinedTaskImageOptionFeet) {
        if ([sidePresented isEqualToString: @"Left"]) {
            answerText = ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_ANSWER_LEFT_FOOT", nil);
        } else if ([sidePresented isEqualToString: @"Right"]) {
            answerText = ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_ANSWER_RIGHT_FOOT", nil);
        }
    }
    return answerText;
}

- (void)displayAnswerWhenButtonPressed:(NSString *)sidePresented forMatches:(BOOL)match {
    NSString *answerText = [self answerForSidePresented:sidePresented];
    NSString *text;
    if (match) {
        text = [NSString stringWithFormat:@"%@\n%@", ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_ANSWER_CORRECT", nil), answerText];
    } else {
        text = [NSString stringWithFormat:@"%@\n%@", ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_ANSWER_INCORRECT", nil), answerText];
    }
    self.leftRightJudgementContentView.answerText = text;
    _displayAnswerTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                                 target:self
                                                               selector:@selector(startInterStimulusInterval)
                                                               userInfo:nil
                                                                repeats:NO];
}

- (void)startInterStimulusInterval {
    [_timeoutNotificationTimer invalidate];
    [_displayAnswerTimer invalidate];
    [self hideImage];
    [self hideCountText];
    [self hideTimeoutText];
    [self hideAnswerText];
    _interStimulusIntervalTimer = [NSTimer scheduledTimerWithTimeInterval:[self interStimulusInterval]
                                                              target:self
                                                            selector:@selector(startNextQuestionOrFinish)
                                                            userInfo:nil
                                                             repeats:NO];
}

- (NSTimeInterval)interStimulusInterval {
    NSTimeInterval timeInterval;
    ORKLeftRightJudgementStep *step = [self leftRightJudgementStep];
    NSTimeInterval range = step.maximumInterStimulusInterval - step.minimumInterStimulusInterval;
    NSTimeInterval randomFactor = (arc4random_uniform(range * 1000) + 1); // non-zero random number of milliseconds between min/max limits
    if (range == 0 || step.maximumInterStimulusInterval == step.minimumInterStimulusInterval ||
        _imageCount == step.numberOfAttempts) { // use min interval after last image of set
        timeInterval = step.minimumInterStimulusInterval;
    } else {
        timeInterval = (randomFactor / 1000) + step.minimumInterStimulusInterval; // in seconds
    }
    return timeInterval;
}

- (NSTimeInterval)reactionTime {
    NSTimeInterval endTime = [NSProcessInfo processInfo].systemUptime;
    double duration = (endTime - _startTime);
    return duration;
}
 
- (void)buttonPressed:(id)sender {
    if (!(self.leftRightJudgementContentView.imageToDisplay == [UIImage imageNamed:@""])) {
        [self setButtonsDisabled];
        [_timeoutTimer invalidate];
        _timedOut = NO;
        double duration = [self reactionTime];
        NSString *sidePresented = [self sidePresented];
        NSString *view = [self viewPresented];
        NSString *orientation = [self orientationPresented];
        NSInteger rotation = [self rotationPresented];
        // evaluate matches according to button pressed
        NSString *sideSelected;
        if (sender == self.leftRightJudgementContentView.leftButton) {
            sideSelected = @"Left";
            _match = ([sidePresented isEqualToString:sideSelected]) ? YES : NO;
            _leftSumCorrect = (_match) ? _leftSumCorrect + 1 : _leftSumCorrect;
            [self calculateMeanAndStdReactionTimes:sidePresented fromDuration: duration forMatches:_match];
            [self calculatePercentagesForSides:sidePresented andTimeouts:_timedOut];
            [self createResultfromImage:[self nextFileNameInQueue] withView:view inRotation:rotation inOrientation:orientation matching:_match sidePresented:sidePresented withSideSelected:sideSelected inDuration:duration];
        }
        else if (sender == self.leftRightJudgementContentView.rightButton) {
            sideSelected = @"Right";
            _match = ([sidePresented isEqualToString:sideSelected]) ? YES : NO;
            _rightSumCorrect = (_match) ? _rightSumCorrect + 1 : _rightSumCorrect;
            [self calculateMeanAndStdReactionTimes:sidePresented fromDuration: duration forMatches:_match];
            [self calculatePercentagesForSides:sidePresented andTimeouts:_timedOut];
            [self createResultfromImage:[self nextFileNameInQueue] withView:view inRotation:rotation inOrientation:orientation matching:_match sidePresented:sidePresented withSideSelected:sideSelected inDuration:duration];
        }
        if ([self leftRightJudgementStep].shouldDisplayAnswer) {
            [self displayAnswerWhenButtonPressed:sidePresented forMatches:_match];
        } else {
            [self startInterStimulusInterval];
        }
    }
}

- (void)calculatePercentagesForSides:(NSString *)sidePresented andTimeouts:(BOOL)timeout {
    if ([sidePresented isEqualToString:@"Left"]) {
        if (_leftCount > 0) { // prevent zero denominator
            _leftPercentCorrect = (100 * (double)_leftSumCorrect) / (double)_leftCount;
        }
    } else if ([sidePresented isEqualToString:@"Right"]) {
        if (_rightCount > 0) { // prevent zero denominator
            _rightPercentCorrect = (100 * (double)_rightSumCorrect) / (double)_rightCount;
        }
    }
    if (_imageCount > 0) { // prevent zero denominator
        _percentTimedOut = (100 * (double)_timedOutCount) / (double)_imageCount;
    }
}

- (void)calculateMeanAndStdReactionTimes:(NSString *)sidePresented fromDuration:(NSTimeInterval)duration forMatches:(BOOL)match {
    // calculate mean and unbiased standard deviation of duration for correct matches only (using Welford's algorithm: Welford. (1962) Technometrics 4(3), 419-420)
    if ([sidePresented isEqualToString: @"Left"] && (match)) {
        if (_leftSumCorrect == 1) {
            _prevMl = _newMl = duration;
            _prevSl = 0;
        } else {
            _newMl = _prevMl + (duration - _prevMl) / (double)_leftSumCorrect;
            _newSl += _prevSl + (duration - _prevMl) * (duration - _newMl);
            _prevMl = _newMl;
        }
        _meanLeftDuration = (_leftSumCorrect > 0) ? _newMl : 0;
        _varianceLeftDuration = (_leftSumCorrect > 1) ? _newSl / ((double)_leftSumCorrect - 1) : 0;
        if (_varianceLeftDuration > 0) {
            _stdLeftDuration = sqrt(_varianceLeftDuration);
        }
    } else if ([sidePresented isEqualToString: @"Right"] && (match)) {
        if (_rightSumCorrect == 1) {
            _prevMr = _newMr = duration;
            _prevSr = 0;
        } else {
            _newMr = _prevMr + (duration - _prevMr) / (double)_rightSumCorrect;
            _newSr += _prevSr + (duration - _prevMr) * (duration - _newMr);
            _prevMr = _newMr;
        }
        _meanRightDuration = (_rightSumCorrect > 0) ? _newMr : 0;
        _varianceRightDuration = (_rightSumCorrect > 1) ? _newSr / ((double)_rightSumCorrect - 1) : 0;
        if (_varianceRightDuration > 0) {
            _stdRightDuration = sqrt(_varianceRightDuration);
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)stepDidFinish {
    [super stepDidFinish];
    [self.leftRightJudgementContentView finishStep:self];
    [self goForward];
}

- (void)start {
    [super start];
    [self startInterStimulusInterval];
}
             
- (NSString *)sidePresented {
    NSString *fileName = [self nextFileNameInQueue];
    NSString *sidePresented;
    if ([fileName containsString:@"LH"] || [fileName containsString:@"LF"]) {
        sidePresented = @"Left";
        _leftCount ++;
    } else if ([fileName containsString:@"RH"] || [fileName containsString:@"RF"]) {
        sidePresented = @"Right";
        _rightCount ++;
    }
    return sidePresented;
}

- (NSString *)viewPresented {
    NSString *fileName = [self nextFileNameInQueue];
    NSString *anglePresented;
    if ([self leftRightJudgementStep].imageOption == ORKPredefinedTaskImageOptionHands) {
        if ([fileName containsString:@"LH1"] ||
            [fileName containsString:@"RH1"]) {
            anglePresented = @"Back";
        } else if ([fileName containsString:@"LH2"] ||
                   [fileName containsString:@"RH2"]) {
            anglePresented = @"Palm";
        } else if ([fileName containsString:@"LH3"] ||
                   [fileName containsString:@"RH3"]) {
            anglePresented = @"Pinkie";
        } else if ([fileName containsString:@"LH4"] ||
                   [fileName containsString:@"RH4"]) {
            anglePresented = @"Thumb";
        } else if ([fileName containsString:@"LH5"] ||
                   [fileName containsString:@"RH5"]) {
            anglePresented = @"Wrist";
        }
    } else if ([self leftRightJudgementStep].imageOption == ORKPredefinedTaskImageOptionFeet) {
        if ([fileName containsString:@"LF1"] ||
            [fileName containsString:@"RF1"]) {
            anglePresented = @"Top";
        } else if ([fileName containsString:@"LF2"] ||
                   [fileName containsString:@"RF2"]) {
            anglePresented = @"Sole";
        } else if ([fileName containsString:@"LF3"] ||
                   [fileName containsString:@"RF3"]) {
            anglePresented = @"Heel";
        } else if ([fileName containsString:@"LF4"] ||
                   [fileName containsString:@"RF4"]) {
            anglePresented = @"Toes";
        } else if ([fileName containsString:@"LF5"] ||
                   [fileName containsString:@"RF5"]) {
            anglePresented = @"Inside";
        } else if ([fileName containsString:@"LF6"] ||
                   [fileName containsString:@"RF6"]) {
            anglePresented = @"Outside";
        }
    }
    return anglePresented;
}

- (NSString *)orientationPresented {
    NSString *fileName = [self nextFileNameInQueue];
    NSString *anglePresented;
    NSString *viewPresented = [self viewPresented];
    if ([self leftRightJudgementStep].imageOption == ORKPredefinedTaskImageOptionHands) {
        if ([fileName containsString:@"LH"]) { // left hand
            if ([viewPresented isEqualToString: @"Back"] ||
                [viewPresented isEqualToString: @"Palm"] ||
                [viewPresented isEqualToString: @"Pinkie"] ||
                [viewPresented isEqualToString: @"Thumb"]) {
                    if ([fileName containsString:@"000cw"]) {
                        anglePresented = @"Neutral";
                    } else if ([fileName containsString:@"030cw"] ||
                               [fileName containsString:@"060cw"] ||
                               [fileName containsString:@"090cw"] ||
                               [fileName containsString:@"120cw"] ||
                               [fileName containsString:@"150cw"]) {
                        anglePresented = @"Medial";
                    } else if ([fileName containsString:@"180cw"]) {
                        anglePresented = @"Neutral";
                    } else if ([fileName containsString:@"210cw"] ||
                               [fileName containsString:@"240cw"] ||
                               [fileName containsString:@"270cw"] ||
                               [fileName containsString:@"300cw"] ||
                               [fileName containsString:@"330cw"]) {
                        anglePresented = @"Lateral";
                    }
            } else if ([viewPresented isEqualToString: @"Wrist"]) {
                if ([fileName containsString:@"000cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"030cw"] ||
                           [fileName containsString:@"060cw"] ||
                           [fileName containsString:@"090cw"] ||
                           [fileName containsString:@"120cw"] ||
                           [fileName containsString:@"150cw"]) {
                    anglePresented = @"Lateral";
                } else if ([fileName containsString:@"180cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"210cw"] ||
                           [fileName containsString:@"240cw"] ||
                           [fileName containsString:@"270cw"] ||
                           [fileName containsString:@"300cw"] ||
                           [fileName containsString:@"330cw"]) {
                    anglePresented = @"Medial";
                }
            }
        } else if ([fileName containsString:@"RH"]) { // right hand
            if ([viewPresented isEqualToString: @"Back"] ||
                [viewPresented isEqualToString: @"Palm"] ||
                [viewPresented isEqualToString: @"Pinkie"] ||
                [viewPresented isEqualToString: @"Thumb"]) {
                if ([fileName containsString:@"000cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"030cw"] ||
                           [fileName containsString:@"060cw"] ||
                           [fileName containsString:@"090cw"] ||
                           [fileName containsString:@"120cw"] ||
                           [fileName containsString:@"150cw"]) {
                    anglePresented = @"Lateral";
                } else if ([fileName containsString:@"180cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"210cw"] ||
                           [fileName containsString:@"240cw"] ||
                           [fileName containsString:@"270cw"] ||
                           [fileName containsString:@"300cw"] ||
                           [fileName containsString:@"330cw"]) {
                    anglePresented = @"Medial";
                }
            } else if ([viewPresented isEqualToString: @"Wrist"]) {
                if ([fileName containsString:@"000cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"030cw"] ||
                           [fileName containsString:@"060cw"] ||
                           [fileName containsString:@"090cw"] ||
                           [fileName containsString:@"120cw"] ||
                           [fileName containsString:@"150cw"]) {
                    anglePresented = @"Medial";
                } else if ([fileName containsString:@"180cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"210cw"] ||
                           [fileName containsString:@"240cw"] ||
                           [fileName containsString:@"270cw"] ||
                           [fileName containsString:@"300cw"] ||
                           [fileName containsString:@"330cw"]) {
                    anglePresented = @"Lateral";
                }
            }
        }
    } else if ([self leftRightJudgementStep].imageOption == ORKPredefinedTaskImageOptionFeet) {
        if ([fileName containsString:@"LF"]) { // left foot
            if ([viewPresented isEqualToString: @"Top"] ||
                [viewPresented isEqualToString: @"Heel"]) {
                    if ([fileName containsString:@"000cw"]) {
                        anglePresented = @"Neutral";
                    } else if ([fileName containsString:@"030cw"] ||
                               [fileName containsString:@"060cw"] ||
                               [fileName containsString:@"090cw"] ||
                               [fileName containsString:@"120cw"] ||
                               [fileName containsString:@"150cw"]) {
                        anglePresented = @"Medial";
                    } else if ([fileName containsString:@"180cw"]) {
                        anglePresented = @"Neutral";
                    } else if ([fileName containsString:@"210cw"] ||
                               [fileName containsString:@"240cw"] ||
                               [fileName containsString:@"270cw"] ||
                               [fileName containsString:@"300cw"] ||
                               [fileName containsString:@"330cw"]) {
                        anglePresented = @"Lateral";
                    }
            } else if ([viewPresented isEqualToString: @"Sole"] ||
                       [viewPresented isEqualToString: @"Toes"] ||
                       [viewPresented isEqualToString: @"Inside"] ||
                       [viewPresented isEqualToString: @"Outside"]) {
                if ([fileName containsString:@"000cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"030cw"] ||
                           [fileName containsString:@"060cw"] ||
                           [fileName containsString:@"090cw"] ||
                           [fileName containsString:@"120cw"] ||
                           [fileName containsString:@"150cw"]) {
                    anglePresented = @"Lateral";
                } else if ([fileName containsString:@"180cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"210cw"] ||
                           [fileName containsString:@"240cw"] ||
                           [fileName containsString:@"270cw"] ||
                           [fileName containsString:@"300cw"] ||
                           [fileName containsString:@"330cw"]) {
                    anglePresented = @"Medial";
                }
            }
        } else if ([fileName containsString:@"RF"]) { // right foot
            if ([viewPresented isEqualToString: @"Top"] ||
                [viewPresented isEqualToString: @"Heel"]) {
                if ([fileName containsString:@"000cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"030cw"] ||
                           [fileName containsString:@"060cw"] ||
                           [fileName containsString:@"090cw"] ||
                           [fileName containsString:@"120cw"] ||
                           [fileName containsString:@"150cw"]) {
                    anglePresented = @"Lateral";
                } else if ([fileName containsString:@"180cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"210cw"] ||
                           [fileName containsString:@"240cw"] ||
                           [fileName containsString:@"270cw"] ||
                           [fileName containsString:@"300cw"] ||
                           [fileName containsString:@"330cw"]) {
                    anglePresented = @"Medial";
                }
            } else if ([viewPresented isEqualToString: @"Sole"] ||
                       [viewPresented isEqualToString: @"Toes"] ||
                       [viewPresented isEqualToString: @"Inside"] ||
                       [viewPresented isEqualToString: @"Outside"]) {
                if ([fileName containsString:@"000cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"030cw"] ||
                           [fileName containsString:@"060cw"] ||
                           [fileName containsString:@"090cw"] ||
                           [fileName containsString:@"120cw"] ||
                           [fileName containsString:@"150cw"]) {
                    anglePresented = @"Medial";
                } else if ([fileName containsString:@"180cw"]) {
                    anglePresented = @"Neutral";
                } else if ([fileName containsString:@"210cw"] ||
                           [fileName containsString:@"240cw"] ||
                           [fileName containsString:@"270cw"] ||
                           [fileName containsString:@"300cw"] ||
                           [fileName containsString:@"330cw"]) {
                    anglePresented = @"Lateral";
                }
            }
        }
    }
    return anglePresented;
}

- (NSInteger)rotationPresented {
    NSString *fileName = [self nextFileNameInQueue];
    NSInteger rotationPresented = 0;
    if ([fileName containsString:@"000cw"]) {
        rotationPresented = 0;
    } else if ([fileName containsString:@"030cw"] ||
        [fileName containsString:@"330cw"]) {
        rotationPresented = 30;
    } else if ([fileName containsString:@"060cw"] ||
            [fileName containsString:@"300cw"]) {
        rotationPresented = 60;
    } else if ([fileName containsString:@"090cw"] ||
            [fileName containsString:@"270cw"]) {
        rotationPresented = 90;
    } else if ([fileName containsString:@"120cw"] ||
            [fileName containsString:@"240cw"]) {
        rotationPresented = 120;
    } else if ([fileName containsString:@"150cw"] ||
            [fileName containsString:@"210cw"]) {
        rotationPresented = 150;
    } else if ([fileName containsString:@"180cw"]) {
        rotationPresented = 180;
    }
    return rotationPresented;
}

- (UIImage *)nextImageInQueue {
    _imageQueue = [self arrayOfImagesForEachAttempt];
    UIImage *image = [_imageQueue objectAtIndex:_imageCount];
    _imageCount++; // increment when called
    return image;
}

- (NSString *)nextFileNameInQueue {
    NSString *path = [_imagePaths objectAtIndex:(_imageCount - 1)];
    NSString *fileName = [[path lastPathComponent] stringByDeletingPathExtension];
    return fileName;
}

- (NSArray *)arrayOfImagesForEachAttempt {
    NSInteger imageQueueLength = ([self leftRightJudgementStep].numberOfAttempts);
    NSString *directory = [self leftRightJudgementStep].getDirectoryForImages;
    if (_imageCount == 0) { // build shuffled array only once
        _imagePaths = [self arrayOfShuffledPaths:@"png" fromDirectory:directory];
    }
    NSMutableArray *imageQueueArray = [NSMutableArray arrayWithCapacity:imageQueueLength];
    // Allocate images
    for(NSUInteger i = 1; i <= imageQueueLength; i++) {
        UIImage *image = [UIImage imageWithContentsOfFile:[_imagePaths objectAtIndex:(i - 1)]];
        [imageQueueArray addObject:image];
    }
    return [imageQueueArray copy];
}

- (NSArray *)arrayOfShuffledPaths:(NSString*)type fromDirectory:(NSString*)directory {
    NSArray *pathArray = [[NSBundle bundleForClass:[self class]] pathsForResourcesOfType:type inDirectory:directory];
    NSArray *shuffled;
    shuffled = [self shuffleArray:pathArray];
    return shuffled;
}

- (NSArray *)shuffleArray:(NSArray*)array {
    NSMutableArray *shuffledArray = [NSMutableArray arrayWithArray:array];
    // use a Fisher–Yates shuffle
    for (NSUInteger i = 0; i < ([shuffledArray count]) - 1; ++i) {
        NSInteger remainingCount = [shuffledArray count] - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t)remainingCount);
        [shuffledArray exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
    return [shuffledArray copy];
}


#pragma mark - ORKResult

- (ORKStepResult *)result {
    ORKStepResult *stepResult = [super result];
    if (_results) {
         stepResult.results = [_results copy];
    }
    return stepResult;
}

- (void)createResultfromImage:(NSString *)imageName withView:(NSString *)view inRotation:(NSInteger)rotation inOrientation:(NSString *)orientation matching:(BOOL)match sidePresented:(NSString *)sidePresented withSideSelected:(NSString *)sideSelected inDuration:(double)duration {
    ORKLeftRightJudgementResult *leftRightJudgementResult = [[ORKLeftRightJudgementResult alloc] initWithIdentifier:self.step.identifier];
    // image results
    leftRightJudgementResult.imageNumber = _imageCount;
    leftRightJudgementResult.imageName = imageName;
    leftRightJudgementResult.viewPresented = view;
    leftRightJudgementResult.orientationPresented = orientation;
    leftRightJudgementResult.rotationPresented = rotation;
    leftRightJudgementResult.reactionTime = duration;
    leftRightJudgementResult.sidePresented = sidePresented;
    leftRightJudgementResult.sideSelected = sideSelected;
    leftRightJudgementResult.sideMatch = match;
    leftRightJudgementResult.timedOut = _timedOut;
    // task results
    leftRightJudgementResult.leftImages = _leftCount;
    leftRightJudgementResult.rightImages = _rightCount;
    leftRightJudgementResult.percentTimedOut = _percentTimedOut;
    leftRightJudgementResult.leftPercentCorrect = _leftPercentCorrect;
    leftRightJudgementResult.rightPercentCorrect = _rightPercentCorrect;
    leftRightJudgementResult.leftMeanReactionTime = _meanLeftDuration;
    leftRightJudgementResult.rightMeanReactionTime = _meanRightDuration;
    leftRightJudgementResult.leftSDReactionTime = _stdLeftDuration;
    leftRightJudgementResult.rightSDReactionTime = _stdRightDuration;
    [_results addObject:leftRightJudgementResult];
}

- (void)startNextQuestionOrFinish {
    [_interStimulusIntervalTimer invalidate];
    if (_imageCount == ([self leftRightJudgementStep].numberOfAttempts)) {
        [self finish];
    } else {
        [self startQuestion];
    }
}

- (void)startQuestion {
    UIImage *image = [self nextImageInQueue];
    self.leftRightJudgementContentView.imageToDisplay = image;
    if (_imageCount == 1) {
        [self setupButtons];
    }
    [self setButtonsEnabled];
    [self configureCountText];
    _startTime = [NSProcessInfo processInfo].systemUptime;
    [self startTimeoutTimer];
}

- (void)setButtonsDisabled {
    [self.leftRightJudgementContentView.leftButton setEnabled: NO];
    [self.leftRightJudgementContentView.rightButton setEnabled: NO];
}

- (void)setButtonsEnabled {
    [self.leftRightJudgementContentView.leftButton setEnabled: YES];
    [self.leftRightJudgementContentView.rightButton setEnabled: YES];
}

- (void)hideCountText {
    self.leftRightJudgementContentView.countText = @" ";
}

- (void)hideTimeoutText {
    self.leftRightJudgementContentView.timeoutText = @" ";
}

- (void)hideAnswerText {
    self.leftRightJudgementContentView.answerText = @" ";
}

- (void)hideImage {
    self.leftRightJudgementContentView.imageToDisplay = [UIImage imageNamed:@""];
}

@end
