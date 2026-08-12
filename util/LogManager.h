#import <Cocoa/Cocoa.h>

@import os.log;

@interface LogManager : NSObject {
  os_log_t mainLog;
  os_log_t trustedLog;
}

@property (nonatomic, readonly) os_log_t mainLog;

// The trusted log should be used to log (potentially) private strings annotated as public
// (to avoid anonymization). This enables the log messages to be viewed without requiring
// users to grant explicit permissions (which is complex, and has the risk that it is not
// undone after it is not needed anymore).
//
// This log should only be used for debug messages (so that the messages are not persisted).
//
// By default this log is disabled. The log is only enabled via an explicit command-line
// parameter.
@property (nonatomic, readonly) os_log_t trustedLog;

@property (class, nonatomic, readonly) LogManager *defaultLogManager;

- (id)init;

@end
