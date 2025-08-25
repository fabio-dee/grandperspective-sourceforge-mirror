#import "TreeDrawer.h"

#import "DirectoryItem.h"
#import "FileItemMapping.h"
#import "FileItemMappingScheme.h"
#import "FilteredTreeGuide.h"
#import "GradientRectangleDrawer.h"
#import "TreeDrawerSettings.h"


@interface TreeDrawer (PrivateMethod)

- (void) colorSchemeChanged:(NSNotification *)notification;

@end // @interface TreeDrawer (PrivateMethod)

@implementation TreeDrawer

// Overrides designated initialiser of base class
- (instancetype) initWithScanTree:(DirectoryItem *)scanTreeVal
                     colorPalette:(NSColorList *)colorPalette {
  TreeDrawerSettings  *settings = [[[TreeDrawerSettings alloc] init] autorelease];
  if (colorPalette) {
    settings = [settings settingsWithChangedColorPalette: colorPalette];
  }

  return [self initWithScanTree: scanTreeVal treeDrawerSettings: settings];
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTreeVal
               treeDrawerSettings:(TreeDrawerSettings *)settings {
  if (self = [super initWithScanTree: scanTreeVal
                        colorPalette: settings.colorPalette]) {
    [self updateSettings: settings];
    
    freeSpaceColor = [rectangleDrawer intValueForColor: NSColor.blackColor];
    usedSpaceColor = [rectangleDrawer intValueForColor: NSColor.darkGrayColor];
    visibleTreeBackgroundColor = [rectangleDrawer intValueForColor: NSColor.grayColor];
  }
  return self;
}

- (void) dealloc {
  [NSNotificationCenter.defaultCenter removeObserver: self];

  [super dealloc];
}


- (void) setColorScheme:(NSObject <FileItemMappingScheme> *)colorScheme {
  if (colorScheme != _colorScheme) {
    NSNotificationCenter  *nc = NSNotificationCenter.defaultCenter;

    [nc removeObserver: self
                  name: MappingSchemeChangedEvent
                object: _colorScheme];

    _colorScheme = colorScheme;

    [nc addObserver: self
           selector: @selector(colorSchemeChanged:)
               name: MappingSchemeChangedEvent
             object: _colorScheme];

    [self colorSchemeChanged: nil];
  }
}


- (void) setMaskTest:(FileItemTest *)maskTest {
  [treeGuide setFileItemTest: maskTest];
}

- (FileItemTest *)maskTest {
  return treeGuide.fileItemTest;
}


- (void) updateSettings:(TreeDrawerSettings *)settings {
  [super updateSettings: settings];

  self.colorScheme = settings.colorScheme;

  [rectangleDrawer setColorPalette: settings.colorPalette];
  [rectangleDrawer setColorGradient: settings.colorGradient];
  [self setMaskTest: settings.maskTest];
}


// Overrides of protected methods

- (void) drawVisibleTreeAtRect:(FileItem *)visibleTree rect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: visibleTreeBackgroundColor];
}

- (void) drawUsedSpaceAtRect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: usedSpaceColor];
}

- (void) drawFreeSpaceAtRect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: freeSpaceColor];
}

- (void) drawFreedSpaceAtRect:(NSRect) rect {
  [rectangleDrawer drawBasicFilledRect: rect intColor: freeSpaceColor];
}

- (void) drawFileItem:(FileItem *)fileItem atRect:(NSRect) rect depth:(int) depth {
  NSUInteger  hash = [_colorMapper hashForFileItem: fileItem atDepth: depth];
  NSUInteger  colorIndex = [_colorMapper colorIndexForHash: hash
                                                 numColors: rectangleDrawer.numGradientColors];

  [rectangleDrawer drawGradientFilledRect: rect colorIndex: colorIndex];
}

@end // @implementation TreeDrawer

@implementation TreeDrawer (PrivateMethod)

- (void) colorSchemeChanged:(NSNotification *)notification {
  _colorMapper = [self.colorScheme fileItemMappingForTree: scanTree];

  [NSNotificationCenter.defaultCenter postNotificationName: ColorMappingChangedEvent
                                                    object: self];
}

@end // @implementation TreeDrawer (PrivateMethod)
