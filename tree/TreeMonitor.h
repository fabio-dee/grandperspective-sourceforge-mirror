#import <Cocoa/Cocoa.h>

@import os.log;

@class TreeContext;

@interface TreeMonitor : NSObject {
@private
  // Cannot synthesize weak properties apparently
  __weak TreeContext *_treeContext;

  FSEventStreamRef eventStream;

  NSArray<NSString *> *rootPathComponents;

  os_log_t logger;
}

@property (nonatomic, readonly, weak) TreeContext *treeContext;
@property (nonatomic, readonly) int numChanges;

// Overrides designated initializer
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithTreeContext:(TreeContext *)treeContext
                             forPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

- (void) startMonitoring;

@end
