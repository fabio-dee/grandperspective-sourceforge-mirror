#import "ScanTreeRoot.h"

#import "LogManager.h"

@implementation ScanTreeRoot

- (void) dealloc {
  os_log_info(LogManager.defaultLogManager.appLog, "ScanTreeRoot-dealloc");

  [super dealloc];
}

@end // @implementation ScanTreeRoot
