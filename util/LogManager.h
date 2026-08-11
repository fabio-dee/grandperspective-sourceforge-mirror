#import <Cocoa/Cocoa.h>

@import os.log;

@interface LogManager : NSObject {
  os_log_t appLog;
}

@property (nonatomic, readonly) os_log_t getAppLog;

+ (LogManager *)defaultLogManager;

- (id)init;

@end
