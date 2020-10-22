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

#import "ORKLeftRightJudgementResult.h"
#import "ORKResult_Private.h"
#import "ORKHelpers_Internal.h"

@implementation ORKLeftRightJudgementResult

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    ORK_ENCODE_DOUBLE(aCoder, reactionTime);
    ORK_ENCODE_DOUBLE(aCoder, leftPercentCorrect);
    ORK_ENCODE_DOUBLE(aCoder, rightPercentCorrect);
    ORK_ENCODE_DOUBLE(aCoder, leftMeanReactionTime);
    ORK_ENCODE_DOUBLE(aCoder, rightMeanReactionTime);
    ORK_ENCODE_DOUBLE(aCoder, leftSDReactionTime);
    ORK_ENCODE_DOUBLE(aCoder, rightSDReactionTime);
    ORK_ENCODE_BOOL(aCoder, sideMatch);
    ORK_ENCODE_BOOL(aCoder, timedOut);
    ORK_ENCODE_INTEGER(aCoder, imageNumber);
    ORK_ENCODE_INTEGER(aCoder, leftImages);
    ORK_ENCODE_INTEGER(aCoder, rightImages);
    ORK_ENCODE_INTEGER(aCoder, rotationPresented);
    ORK_ENCODE_OBJ(aCoder, imageName);
    ORK_ENCODE_OBJ(aCoder, viewPresented);
    ORK_ENCODE_OBJ(aCoder, orientationPresented);
    ORK_ENCODE_OBJ(aCoder, sidePresented);
    ORK_ENCODE_OBJ(aCoder, sideSelected);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        ORK_DECODE_DOUBLE(aDecoder, reactionTime);
        ORK_DECODE_DOUBLE(aDecoder, leftPercentCorrect);
        ORK_DECODE_DOUBLE(aDecoder, rightPercentCorrect);
        ORK_DECODE_DOUBLE(aDecoder, leftMeanReactionTime);
        ORK_DECODE_DOUBLE(aDecoder, rightMeanReactionTime);
        ORK_DECODE_DOUBLE(aDecoder, leftSDReactionTime);
        ORK_DECODE_DOUBLE(aDecoder, rightSDReactionTime);
        ORK_DECODE_BOOL(aDecoder, sideMatch);
        ORK_DECODE_BOOL(aDecoder, timedOut);
        ORK_DECODE_INTEGER(aDecoder, imageNumber);
        ORK_DECODE_INTEGER(aDecoder, leftImages);
        ORK_DECODE_INTEGER(aDecoder, rightImages);
        ORK_DECODE_INTEGER(aDecoder, rotationPresented);
        ORK_DECODE_OBJ_CLASS(aDecoder, imageName, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, viewPresented, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, orientationPresented, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, sidePresented, NSString);
        ORK_DECODE_OBJ_CLASS(aDecoder, sideSelected, NSString);
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL isParentSame = [super isEqual:object];
    
    __typeof(self) castObject = object;
    return (isParentSame &&
            (self.reactionTime == castObject.reactionTime) &&
            (self.leftPercentCorrect == castObject.leftPercentCorrect) &&
            (self.rightPercentCorrect == castObject.rightPercentCorrect) &&
            (self.leftMeanReactionTime == castObject.leftMeanReactionTime) &&
            (self.rightMeanReactionTime == castObject.rightMeanReactionTime) &&
            (self.leftSDReactionTime == castObject.leftSDReactionTime) &&
            (self.rightSDReactionTime == castObject.rightSDReactionTime) &&
            (self.sideMatch == castObject.sideMatch) &&
            (self.timedOut == castObject.timedOut) &&
            (self.imageNumber == castObject.imageNumber) &&
            (self.leftImages == castObject.leftImages) &&
            (self.rightImages == castObject.rightImages) &&
            (self.rotationPresented == castObject.rotationPresented) &&
            ORKEqualObjects(self.imageName, castObject.imageName) &&
            ORKEqualObjects(self.viewPresented, castObject.viewPresented) &&
            ORKEqualObjects(self.orientationPresented, castObject.orientationPresented) &&
            ORKEqualObjects(self.sidePresented, castObject.sidePresented) &&
            ORKEqualObjects(self.sideSelected, castObject.sideSelected));
}

- (instancetype)copyWithZone:(NSZone *)zone {
    ORKLeftRightJudgementResult *result = [super copyWithZone:zone];
    result.reactionTime = self.reactionTime;
    result.leftPercentCorrect = self.leftPercentCorrect;
    result.rightPercentCorrect = self.rightPercentCorrect;
    result.leftMeanReactionTime = self.leftMeanReactionTime;
    result.rightMeanReactionTime = self.rightMeanReactionTime;
    result.leftSDReactionTime = self.leftSDReactionTime;
    result.rightSDReactionTime = self.rightSDReactionTime;
    result.sideMatch = self.sideMatch;
    result.timedOut = self.timedOut;
    result.imageNumber = self.imageNumber;
    result.leftImages = self.leftImages;
    result.rightImages = self.rightImages;
    result.rotationPresented = self.rotationPresented;
    result -> _imageName = [self.imageName copy];
    result -> _viewPresented = [self.viewPresented copy];
    result -> _orientationPresented = [self.orientationPresented copy];
    result -> _sidePresented = [self.sidePresented copy];
    result -> _sideSelected = [self.sideSelected copy];
    return result;
}

- (NSString *)descriptionWithNumberOfPaddingSpaces:(NSUInteger)numberOfPaddingSpaces {
    return [NSString stringWithFormat:@"%@; reactionTime: %f; imageNumber: %li; leftImages: %li; rightImages: %li; rotationPresented: %li; leftPercentCorrect: %f; rightPercentCorrect: %f; leftMeanReactionTime: %f; rightMeanReactionTime: %f; leftSDReactionTime: %f; rightSDReactionTime: %f; sideMatch: %d; timedOut: %d; imageName: %@; viewPresented: %@; orientationPresented: %@; sidePresented: %@; sideSelected: %@ %@", [self descriptionPrefixWithNumberOfPaddingSpaces:numberOfPaddingSpaces], self.reactionTime, self.imageNumber, self.leftImages, self.rightImages, self.rotationPresented, self.leftPercentCorrect, self.rightPercentCorrect, self.leftMeanReactionTime, self.rightMeanReactionTime, self.leftSDReactionTime, self.rightSDReactionTime, self.sideMatch, self.timedOut, self.imageName, self.orientationPresented, self.viewPresented, self.sidePresented, self.sideSelected, self.descriptionSuffix];
}


@end
