#import "TreeDrawer.h"

#import "DirectoryItem.h"
#import "FileItemMapping.h"
#import "FilteredTreeGuide.h"
#import "GradientRectangleDrawer.h"
#import "TreeDrawerSettings.h"


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
    // Make sure values are set before calling updateSettings.
    colorMapper = nil;

    [self updateSettings: settings];
    
    freeSpaceColor = [rectangleDrawer intValueForColor: NSColor.blackColor];
    usedSpaceColor = [rectangleDrawer intValueForColor: NSColor.darkGrayColor];
    visibleTreeBackgroundColor = [rectangleDrawer intValueForColor: NSColor.grayColor];
  }
  return self;
}

- (void) dealloc {
  [colorMapper release];

  [super dealloc];
}


- (void) setColorMapper:(NSObject <FileItemMapping> *)colorMapperVal {
  NSAssert(colorMapperVal != nil, @"Cannot set an invalid color mapper.");

  if (colorMapperVal != colorMapper) {
    [colorMapper release];
    colorMapper = [colorMapperVal retain];
  }
}

- (NSObject <FileItemMapping> *)colorMapper {
  return colorMapper;
}


- (void) setMaskTest:(FileItemTest *)maskTest {
  [treeGuide setFileItemTest: maskTest];
}

- (FileItemTest *)maskTest {
  return treeGuide.fileItemTest;
}


- (void) updateSettings:(TreeDrawerSettings *)settings {
  [super updateSettings: settings];

  [self setColorMapper: settings.colorMapper];
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
  NSUInteger  colorIndex = [colorMapper hashForFileItem: fileItem atDepth: depth];
  if (colorMapper.canProvideLegend) {
    LegendProvidingFileItemMapping  *legendProvider = (LegendProvidingFileItemMapping *)colorMapper;

    NSUInteger  maxIndex = rectangleDrawer.numGradientColors - 1;
    colorIndex = MIN(colorIndex, maxIndex);
    if (legendProvider.reverseOrder) {
      colorIndex = maxIndex - colorIndex;
    }
  }
  else {
    colorIndex = colorIndex % rectangleDrawer.numGradientColors;
  }

  [rectangleDrawer drawGradientFilledRect: rect colorIndex: colorIndex];
}

@end // @implementation TreeDrawer
