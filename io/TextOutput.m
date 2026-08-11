#import <Foundation/Foundation.h>

#import "TextOutput.h"
#import "LogManager.h"

const NSUInteger TEXT_OUTPUT_BUFFER_SIZE = 4096 * 16;


@implementation TextOutput

- (void) dealloc {
  if (file) {
    fclose(file);
    file = NULL;
  }
  [_path release];

  free(dataBuffer);

  [super dealloc];
}

- (instancetype) initWithPath:(NSURL *)pathVal {
  if (self = [super init]) {
    _path = [pathVal retain];
    file = NULL;
    dataBuffer = malloc(TEXT_OUTPUT_BUFFER_SIZE);
  }
  return self;
}

- (BOOL) open {
  file = fopen(self.path.path.UTF8String, "w");

  return file != NULL;
}

- (BOOL) close {
  BOOL ok = fclose(file) == 0;

  file = NULL;

  return ok;
}

- (BOOL) appendString:(NSString *)s {
  NSData  *newData = [s dataUsingEncoding: NSUTF8StringEncoding];
  const void  *newDataBytes = newData.bytes;
  NSUInteger  numToAppend = newData.length;
  NSUInteger  newDataPos = 0;

  while (numToAppend > 0) {
    NSUInteger  numToCopy = (dataBufferPos + numToAppend <= TEXT_OUTPUT_BUFFER_SIZE
                             ? numToAppend
                             : TEXT_OUTPUT_BUFFER_SIZE - dataBufferPos);

    memcpy(dataBuffer + dataBufferPos, newDataBytes + newDataPos, numToCopy);
    dataBufferPos += numToCopy;
    newDataPos += numToCopy;
    numToAppend -= numToCopy;

    if (dataBufferPos == TEXT_OUTPUT_BUFFER_SIZE && ![self flush]) {
      return NO;
    }
  }

  return YES;
}

- (BOOL) flush {
  if (dataBufferPos > 0) {
    // Write remaining characters in buffer
    NSUInteger  numWritten = fwrite(dataBuffer, 1, dataBufferPos, file);

    if (numWritten != dataBufferPos) {
      os_log(LogManager.defaultLogManager.appLog,
             "Failed to write text data: %lu bytes written out of %lu.",
             (unsigned long)numWritten, (unsigned long)dataBufferPos);
      return NO;
    }

    dataBufferPos = 0;
  }

  return YES;
}

@end // @implementation TextOutput
