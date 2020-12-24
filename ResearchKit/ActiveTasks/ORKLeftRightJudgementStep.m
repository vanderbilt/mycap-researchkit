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


#import "ORKLeftRightJudgementStep.h"
#import "ORKLeftRightJudgementStepViewController.h"
#import "ORKHelpers_Internal.h"


@implementation ORKLeftRightJudgementStep {
}

+ (Class)stepViewControllerClass {
    return [ORKLeftRightJudgementStepViewController class];
}


- (instancetype)initWithIdentifier:(NSString *)identifier {
    self = [super initWithIdentifier:identifier];
    if (self) {
        self.shouldVibrateOnStart = YES;
        self.shouldShowDefaultTimer = NO;
        self.shouldContinueOnFinish = YES;
        self.shouldStartTimerAutomatically = YES;
        self.stepDuration = NSIntegerMax;
        self.imageOption = _imageOption;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)validateParameters {
    [super validateParameters];
    NSInteger minimumAttempts = 10;
    if (self.numberOfAttempts < minimumAttempts) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"number of attempts should be greater or equal to %ld.", (long)minimumAttempts]
                                     userInfo:nil];
    }
    if (self.minimumInterStimulusInterval <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"minimumInterStimulusInterval must be greater than zero"
                                     userInfo:nil];
    }
    if (self.maximumInterStimulusInterval < self.minimumInterStimulusInterval) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"maximumInterStimulusInterval cannot be less than minimumInterStimulusInterval"
                                     userInfo:nil];
    }
    if (self.timeout <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"timeout must be greater than zero"
                                     userInfo:nil];
    }
    if (!(self.imageOption & ORKPredefinedTaskImageOptionHands) && !(self.imageOption & ORKPredefinedTaskImageOptionFeet)) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:ORKLocalizedString(@"LEFT_RIGHT_JUDGEMENT_IMAGE_OPTION_ERROR", nil)
                                     userInfo:nil];
    }
    if ((self.imageOption & ORKPredefinedTaskImageOptionHands) && self.numberOfAttempts > self.numberOfImages)  {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:ORKLocalizedString(@"Number of attempts is beyond number of available hand images", nil)
                                 userInfo:nil];
    }
    if ((self.imageOption & ORKPredefinedTaskImageOptionFeet) && self.numberOfAttempts > self.numberOfImages)  {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:ORKLocalizedString(@"Number of attempts is beyond number of available foot images", nil)
                                 userInfo:nil];
    }
}

- (BOOL)startsFinished {
    return NO;
}

- (BOOL)allowsBackNavigation {
    return NO;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLeftRightJudgementStep *step = [super copyWithZone:zone];
    step.numberOfAttempts = self.numberOfAttempts;
    step.minimumInterStimulusInterval = self.minimumInterStimulusInterval;
    step.maximumInterStimulusInterval = self.maximumInterStimulusInterval;
    step.timeout = self.timeout;
    step.shouldDisplayAnswer = self.shouldDisplayAnswer;
    step.imageOption = self.imageOption;
    return step;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self ) {
        ORK_DECODE_INTEGER(aDecoder, numberOfAttempts);
        ORK_DECODE_DOUBLE(aDecoder, minimumInterStimulusInterval);
        ORK_DECODE_DOUBLE(aDecoder, maximumInterStimulusInterval);
        ORK_DECODE_DOUBLE(aDecoder, timeout);
        ORK_DECODE_BOOL(aDecoder, shouldDisplayAnswer);
        ORK_DECODE_ENUM(aDecoder, imageOption);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_INTEGER(aCoder, numberOfAttempts);
    ORK_ENCODE_DOUBLE(aCoder, minimumInterStimulusInterval);
    ORK_ENCODE_DOUBLE(aCoder, maximumInterStimulusInterval);
    ORK_ENCODE_DOUBLE(aCoder, timeout);
    ORK_DECODE_BOOL(aCoder, shouldDisplayAnswer);
    ORK_ENCODE_ENUM(aCoder, imageOption);
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.numberOfAttempts == castObject.numberOfAttempts) &&
            (self.minimumInterStimulusInterval == castObject.minimumInterStimulusInterval) &&
            (self.maximumInterStimulusInterval == castObject.maximumInterStimulusInterval) &&
            (self.timeout == castObject.timeout) &&
            (self.shouldDisplayAnswer == castObject.shouldDisplayAnswer) &&
            (self.imageOption == castObject.imageOption));
}

- (NSInteger)numberOfImages {
    NSString *directory = (self.getDirectoryForImages);
    NSArray *pathArray = [[NSBundle bundleForClass:[self class]] pathsForResourcesOfType:@"png" inDirectory:directory];
    NSInteger count = [pathArray count];
    return count;
}

- (NSString *)getDirectoryForImages {
    NSString *directory;
    if (self.imageOption == ORKPredefinedTaskImageOptionHands) {
        directory = @"Images/Hands";
    } else if (self.imageOption == ORKPredefinedTaskImageOptionFeet) {
        directory = @"Images/Feet";
    }
    return directory;
}

@end
