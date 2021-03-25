//
//  main.m
//  WriteRawAudioSamples
//
//  Created by Panayotis Matsinopoulos on 25/3/21.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

// CD-qualiy sample rate
#define SAMPLE_RATE 44100
#define BITS_PER_SAMPLE 16
#define BYTES_PER_SAMPLE 16 / 8
// We use LPCM so the encoding does not use packets. Hence,
// we are going to have 1 frame per packet.
#define FRAMES_PER_PACKET 1

// number of seconds we want to capture
#define DURATION 5.0
#define FILENAME_FORMAT @"%0.3f-square.aif"

#define NUMBER_OF_CHANNELS 1

void buildFileURL(double hz, NSURL** fileURL) {
  NSString* fileName = [NSString stringWithFormat:FILENAME_FORMAT, hz];
  NSString* filePath = [[[NSFileManager defaultManager] currentDirectoryPath]
                        stringByAppendingPathComponent:fileName];
  *fileURL = [NSURL fileURLWithPath:filePath];
}

int main(int argc, const char * argv[]) {
  if (argc < 2) {
    printf("Usage: WriteRawAudioSamples n\n(where n is tone in Hz)\n");
    return -1;
  }

  @autoreleasepool {
    double hz = atof(argv[1]);
    assert(hz > 0);
    
    NSLog(@"generating %f hz tone...", hz);
    
    NSURL *fileURL = NULL;
    buildFileURL(hz, &fileURL);
    
    // Prepare the format
    AudioStreamBasicDescription audioStreamBasicDescription;
    memset(&audioStreamBasicDescription, 0, sizeof(audioStreamBasicDescription));
    
    audioStreamBasicDescription.mSampleRate = SAMPLE_RATE;
    audioStreamBasicDescription.mFormatID = kAudioFormatLinearPCM;
    audioStreamBasicDescription.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioStreamBasicDescription.mBitsPerChannel = BITS_PER_SAMPLE;
    audioStreamBasicDescription.mChannelsPerFrame = NUMBER_OF_CHANNELS;
    audioStreamBasicDescription.mFramesPerPacket = FRAMES_PER_PACKET;
    audioStreamBasicDescription.mBytesPerFrame = BYTES_PER_SAMPLE * NUMBER_OF_CHANNELS;
    audioStreamBasicDescription.mBytesPerPacket = audioStreamBasicDescription.mFramesPerPacket * audioStreamBasicDescription.mBytesPerFrame;
    
    // Set up the file
    AudioFileID audioFile;
    OSStatus error = noErr;
    
    error = AudioFileCreateWithURL((__bridge CFURLRef)fileURL,
                                   kAudioFileAIFFType,
                                   &audioStreamBasicDescription,
                                   kAudioFileFlags_EraseFile,
                                   &audioFile);
    assert(error == noErr);
    
    // Start writing samples;
    long maxSampleCount = SAMPLE_RATE * DURATION;
    
    long sampleCount = 0;
    UInt32 bytesToWrite = 2;
    double waveLengthInSamples = SAMPLE_RATE / hz;
    NSLog(@"wave (or cycle) length in samples: %.4f\n", waveLengthInSamples);
    
    while (sampleCount < maxSampleCount) {
      for(int i = 0; i < waveLengthInSamples; i++) {
        // Square wave
        SInt16 sample;
        if (i < waveLengthInSamples/2) {
          sample = CFSwapInt16HostToBig(SHRT_MAX);
        } else {
          sample = CFSwapInt16HostToBig(SHRT_MIN);
        }
        // note that we are using 2 bytes per sample, hence offset is +sampleCount * 2+
        error = AudioFileWriteBytes(audioFile, false, sampleCount * bytesToWrite, &bytesToWrite, &sample);
        assert(error == noErr);
        sampleCount++;
      }
    }
    error = AudioFileClose(audioFile);
    assert(error == noErr);
    NSLog(@"wrote %ld samples", sampleCount);
  }
  return 0;
}
