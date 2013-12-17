//
//  SKMuteSwitchDetector.m
//
//  Created by Filipe on 09/12/13.
//  Copyright (c) 2013 skmobi. All rights reserved.
//
//  Adapted from SKMuteSwitchDetector by Moshe Gottlieb (Sharkfood) @ http://sharkfood.com/archives/450
//  All credits to him

#import "SKMuteSwitchDetector.h"
#import <AudioToolbox/AudioToolbox.h>

#define SAMPLE_RATE 44000
#define SAMPLES 0.2
#define WAIT_THRESHOLD 0.2

void MuteSoundPlaybackComplete(SystemSoundID  ssID,void* clientData){

    NSDictionary *soundData = CFBridgingRelease(clientData);
    SKMuteSwitchDetectorBlock andPerform = soundData[@"andPerform"];
    SystemSoundID soundId = (SystemSoundID)[soundData[@"soundId"] integerValue];

    NSTimeInterval elapsed = [NSDate timeIntervalSinceReferenceDate] - [soundData[@"start"] doubleValue];
    andPerform(elapsed < WAIT_THRESHOLD, nil);
    
    AudioServicesRemoveSystemSoundCompletion(soundId);
    AudioServicesDisposeSystemSoundID(soundId);
}

BOOL createSoundFileIfRequired(NSString *soundFile, NSError **error) {
    if ([[NSFileManager defaultManager] fileExistsAtPath:soundFile isDirectory:NO])
        return YES;
    
    NSUInteger length = (NSUInteger)(SAMPLE_RATE * SAMPLES * 2); // 2 bytes per sample
    NSUInteger temp;
    // initialize with room for RIFF chunk (36) + "data" header from data chunk + actual sound data
    NSMutableData *data = [NSMutableData dataWithCapacity:(length + 36 + 4)];
    
    [data appendData:[@"RIFF" dataUsingEncoding:NSASCIIStringEncoding]];
    temp = length + 36;
    [data appendData:[NSData dataWithBytes:&temp length:4]];
    [data appendData:[@"WAVE" dataUsingEncoding:NSASCIIStringEncoding]];
    [data appendData:[@"fmt " dataUsingEncoding:NSASCIIStringEncoding]];
    temp = 16;
    [data appendData:[NSData dataWithBytes:&temp length:4]];
    temp = 1;
    [data appendData:[NSData dataWithBytes:&temp length:2]];
    [data appendData:[NSData dataWithBytes:&temp length:2]];
    temp = SAMPLE_RATE;
    [data appendData:[NSData dataWithBytes:&temp length:4]];
    temp *= 2;
    [data appendData:[NSData dataWithBytes:&temp length:4]];
    temp = 2;
    [data appendData:[NSData dataWithBytes:&temp length:2]];
    temp = 16;
    [data appendData:[NSData dataWithBytes:&temp length:2]];
    [data appendData:[@"data" dataUsingEncoding:NSASCIIStringEncoding]];
    [data appendData:[NSData dataWithBytes:&length length:4]];
    temp = 0;
    
    NSData *nullByte = [NSData dataWithBytes:&temp length:1];
    
    for (NSUInteger i = 0; i < length; i++)
        [data appendData:nullByte];
    
    return [data writeToFile:soundFile options:NSDataWritingAtomic error:error];
}

@implementation SKMuteSwitchDetector

+ (void)checkSwitch:(SKMuteSwitchDetectorBlock)andPerform {
    if (!andPerform) return;

    NSString *soundFile = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/SKMuteSwitchDetector_Silence.wav"];
    
    NSError *createSoundFileError;
    if (!createSoundFileIfRequired(soundFile, &createSoundFileError)) {
        andPerform(NO, createSoundFileError);
        return;
    }
    
    SystemSoundID soundId;

    OSStatus osStatus = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundFile], &soundId);
    if (osStatus == kAudioServicesNoError){
        UInt32 yes = 1;
        AudioServicesSetProperty(kAudioServicesPropertyIsUISound, sizeof(soundId),&soundId,sizeof(yes), &yes);
        
        NSDictionary *clientData = @{@"andPerform" : [andPerform copy], @"soundId" : @(soundId), @"start" : @([NSDate timeIntervalSinceReferenceDate])};
        AudioServicesAddSystemSoundCompletion(soundId, CFRunLoopGetMain(), kCFRunLoopDefaultMode, MuteSoundPlaybackComplete,(void *)CFBridgingRetain(clientData));

        AudioServicesPlaySystemSound(soundId);
    } else {
        andPerform(NO, [NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil]);
    }
}

@end
