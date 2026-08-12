#import <Foundation/Foundation.h>

#import "CompressedInput.h"
#import "LogManager.h"

const NSUInteger COMPRESSED_BUFFER_SIZE = 2048;
const NSUInteger DECOMPRESSED_BUFFER_SIZE = 4096 * 32;

@interface CompressedInput (PrivateMethods)

- (void) process;
- (BOOL) processNewInput;
- (BOOL) writeNewOutput;
- (BOOL) decompress;
- (BOOL) finalize;
- (void) close;

@end

@implementation CompressedInput

- (instancetype) initWithSourceUrl:(NSURL *)sourceUrl
                      outputStream:(NSOutputStream *)outputStreamVal {
  if (self = [super init]) {
    outputStream = [outputStreamVal retain];

    compressionStream.zalloc = Z_NULL;
    compressionStream.zfree = Z_NULL;
    // Default window size with GZIP format enabled
    int result = inflateInit2(&compressionStream, 15 + 16);
    NSAssert(result == Z_OK, @"inflateInit2 failed");

    inputStream = [[NSInputStream alloc] initWithURL: sourceUrl];

    compressedDataBuffer = malloc(COMPRESSED_BUFFER_SIZE);
    decompressedDataBuffer = malloc(DECOMPRESSED_BUFFER_SIZE);

    logger = LogManager.defaultLogManager.mainLog;
  }

  return self;
}

- (void) dealloc {
  [inputStream release];
  [outputStream release];

  free(compressedDataBuffer);
  free(decompressedDataBuffer);

  inflateEnd(&compressionStream);

  [super dealloc];
}

- (void) open {
  compressionStream.avail_in = 0;

  [inputStream setDelegate: self];
  [outputStream setDelegate: self];

  inputDataAvailable = NO;
  inputEndEncountered = NO;
  decompressionDone = NO;
  numDecompressedBytesAvailable = 0;
  outputSpaceAvailable = NO;

  [inputStream scheduleInRunLoop: NSRunLoop.mainRunLoop forMode: NSDefaultRunLoopMode];
  [inputStream open];

  [outputStream scheduleInRunLoop: NSRunLoop.mainRunLoop forMode: NSDefaultRunLoopMode];
  [outputStream open];
}

// Stream event handler
- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
  switch (eventCode) {
    case NSStreamEventHasBytesAvailable:
      NSAssert(stream == inputStream, @"Unexpected stream has bytes available");
      inputDataAvailable = YES;
      break;
    case NSStreamEventHasSpaceAvailable:
      NSAssert(stream == outputStream, @"Unexpected stream has space available");
      outputSpaceAvailable = YES;
      break;
    case NSStreamEventEndEncountered:
      NSAssert(stream == inputStream, @"Unexpected stream end encountered");
      inputEndEncountered = YES;
      break;
    case NSStreamEventErrorOccurred:
      return [self close];
    case NSStreamEventOpenCompleted:
    case NSStreamEventNone:
      break;
  }

  [self process];
}

@end // @implementation CompressedInput

@implementation CompressedInput (PrivateMethods)

- (void) process {
  while (numDecompressedBytesAvailable == 0 && compressionStream.avail_in > 0) {
    // Consume lingering compressed data
    if (![self decompress]) {
      os_log(logger, "Error during decompression");
      return [self close];
    }
  }

  while (numDecompressedBytesAvailable == 0 && inputDataAvailable) {
    if (![self processNewInput]) {
      os_log(logger, "Error processing new input");
      return [self close];
    }
  }

  while (numDecompressedBytesAvailable > 0 && outputSpaceAvailable) {
    if (![self writeNewOutput]) {
      os_log(logger, "Error writing new output");
      return [self close];
    }

    if (numDecompressedBytesAvailable == 0 && inputEndEncountered) {
      // Finalize the stream. This may generate more decompressed data.
      if (![self finalize]) {
        os_log(logger, "Failed to finalize compressed input");
        return [self close];
      }
    }
  }

  if (numDecompressedBytesAvailable == 0 &&
      inputEndEncountered && (!isCompressed || decompressionDone)) {
    // All decompressed data has been processed
    [self close];
  }
}

- (BOOL) processNewInput {
  NSAssert(compressionStream.avail_in == 0, @"Not all compressed data has been consumed yet");

  unsigned long long readSofar = self.totalBytesRead;

  NSInteger numRead = [inputStream read: compressedDataBuffer
                              maxLength: COMPRESSED_BUFFER_SIZE];
  compressionStream.next_in = compressedDataBuffer;
  compressionStream.avail_in = (unsigned int)numRead;

  if (readSofar == 0) {
    isCompressed = (compressedDataBuffer[0] == 0x1f && compressedDataBuffer[1] == 0x8b);
  }
  readSofar += numRead;
  self.totalBytesRead = readSofar;

  if (![self decompress]) {
    return NO;
  }

  inputDataAvailable = inputStream.hasBytesAvailable;

  return YES;
}

- (BOOL) writeNewOutput {
  NSInteger numWritten = [outputStream write: decompressedDataP
                                   maxLength: numDecompressedBytesAvailable];
  if (numWritten < 0) {
    NSError  *error = outputStream.streamError;
    os_log(logger, "Error writing to stream: %@", error.localizedDescription);
    return NO;
  }

  decompressedDataP += numWritten;
  numDecompressedBytesAvailable -= numWritten;

  outputSpaceAvailable = outputStream.hasSpaceAvailable;

  return YES;
}

- (BOOL) finalize {
  NSAssert(inputEndEncountered, @"Finalizing without encountering input end");
  if (isCompressed) {
    compressionStream.next_in = compressedDataBuffer;
    compressionStream.avail_in = 0;

    return [self decompress];
  } else {
    return YES;
  }
}

- (void) close {
  [inputStream removeFromRunLoop: NSRunLoop.mainRunLoop forMode: NSDefaultRunLoopMode];
  [inputStream close];

  [outputStream removeFromRunLoop: NSRunLoop.mainRunLoop forMode: NSDefaultRunLoopMode];
  [outputStream close];
}

- (BOOL) decompress {
  NSAssert(numDecompressedBytesAvailable == 0,
           @"New decompress initiated while old data is still available");

  if (isCompressed) {
    int flush = inputEndEncountered ? Z_FINISH : Z_SYNC_FLUSH;

    compressionStream.next_out = decompressedDataBuffer;
    compressionStream.avail_out = DECOMPRESSED_BUFFER_SIZE;

    int result = inflate(&compressionStream, flush);
    if (result != Z_OK && result != Z_STREAM_END) {
      os_log(logger, "Unexpected return code for inflate: %d", result);
      return NO;
    }

    decompressionDone = (result == Z_STREAM_END);

    numDecompressedBytesAvailable = DECOMPRESSED_BUFFER_SIZE - compressionStream.avail_out;
    decompressedDataP = decompressedDataBuffer;
    if (compressionStream.avail_in > 0) {
      os_log(logger, "Warning: %d bytes remaining in input buffer after inflate",
             compressionStream.avail_in);
    }
  } else {
    numDecompressedBytesAvailable = compressionStream.avail_in;
    decompressedDataP = compressedDataBuffer;
    compressionStream.avail_in = 0;
  }

  if (numDecompressedBytesAvailable > 0 && outputSpaceAvailable) {
    if (! [self writeNewOutput]) {
      return NO;
    }
  }

  return YES;
}

@end
