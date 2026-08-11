#import "LogManager.h"

@implementation LogManager

+ (LogManager *)defaultLogManager {
  static LogManager  *defaultLogManagerInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    defaultLogManagerInstance = [[LogManager alloc] init];
  });

  return defaultLogManagerInstance;
}

- (id) init {
  if (self = [super init]) {
    appLog = os_log_create("net.sf.grandperspectiv", "app");
  }

  return self;
}

- (os_log_t)getAppLog {
  return appLog;
}

@end // @implementation LogManager
