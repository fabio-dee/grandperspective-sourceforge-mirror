#import "DrawTaskExecutor.h"

#import "TreeDrawer.h"
#import "TreeDrawerSettings.h"
#import "DrawTaskInput.h"
#import "TreeContext.h"


@implementation DrawTaskExecutor

- (instancetype) initWithTreeContext:(TreeContext *)treeContextVal {
  return [self initWithTreeContext: treeContextVal 
                   drawingSettings: [[[TreeDrawerSettings alloc] init] autorelease]];
}

- (instancetype) initWithTreeContext:(TreeContext *)treeContextVal
                     drawingSettings:(TreeDrawerSettings *)settings {
  if (self = [super init]) {
    treeContext = [treeContextVal retain];
  
    _treeDrawer = [[TreeDrawer alloc] initWithScanTree: treeContext.scanTree
                                    treeDrawerSettings: settings];
    _treeDrawerSettings = settings;

    settingsLock = [[NSLock alloc] init];
  }
  return self;
}

- (void) dealloc {
  [treeContext release];

  [settingsLock release];
  
  [super dealloc];
}


- (void) setTreeDrawerSettings:(TreeDrawerSettings *)settings {
  [settingsLock lock];
  _treeDrawerSettings = settings;
  [settingsLock unlock];
}


- (void) prepareToRunTask {
  [_treeDrawer clearAbortFlag];
}

- (id) runTaskWithInput:(id)input {
  [settingsLock lock];
  // Even though the settings are immutable, obtaining the settingsLock
  // ensures that it is not de-allocated while it is being used. 
  [_treeDrawer updateSettings: self.treeDrawerSettings];
  [settingsLock unlock];

  DrawTaskInput  *drawingInput = input;
    
  [treeContext obtainReadLock];
    
  NSImage  *image = [_treeDrawer drawImageOfVisibleTree: drawingInput.visibleTree
                                         startingAtTree: drawingInput.treeInView
                                     usingLayoutBuilder: drawingInput.layoutBuilder
                                                 inRect: drawingInput.bounds];

  [treeContext releaseReadLock];

  return image;
}

- (void) abortTask {
  [_treeDrawer abortDrawing];
}

@end
