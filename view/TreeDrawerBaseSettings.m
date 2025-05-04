#import "TreeDrawerBaseSettings.h"

#import "PreferencesPanelControl.h"

const unsigned MIN_DISPLAY_DEPTH_LIMIT = 1;
const unsigned MAX_DISPLAY_DEPTH_LIMIT = 8;
const unsigned NO_DISPLAY_DEPTH_LIMIT = 0xFFFF;

@implementation TreeDrawerBaseSettings

// Creates default settings.
- (instancetype) init {
  return [self initWithDisplayDepth: TreeDrawerBaseSettings.defaultDisplayDepth
                          drawItems: TreeDrawerBaseSettings.defaultDrawItems];
}

- (instancetype) initWithDisplayDepth:(unsigned)displayDepth
                            drawItems:(DrawItemsEnum)drawItems {
  if (self = [super init]) {
    _displayDepth = displayDepth;
    _drawItems = drawItems;
  }

  return self;
}


- (instancetype) settingsWithChangedDisplayDepth:(unsigned) displayDepth {
  return [[[TreeDrawerBaseSettings alloc] initWithDisplayDepth: displayDepth
                                                     drawItems: _drawItems] autorelease];
}

- (instancetype) settingsWithChangedDrawItems:(DrawItemsEnum) drawItems {
  return [[[TreeDrawerBaseSettings alloc] initWithDisplayDepth: _displayDepth
                                                     drawItems: drawItems] autorelease];
}

+ (DrawItemsEnum) defaultDrawItems {
  return ([NSUserDefaults.standardUserDefaults boolForKey: ShowPackageContentsByDefaultKey]
          ? DRAW_FILES : DRAW_PACKAGES_AND_FILES);
}

+ (unsigned) defaultDisplayDepth {
  NSString  *value = [NSUserDefaults.standardUserDefaults stringForKey: DefaultDisplayFocusKey];

  if ([value isEqualToString: UnlimitedDisplayFocusValue]) {
    return NO_DISPLAY_DEPTH_LIMIT;
  }

  int  depth = [value intValue];

  // Ensure the setting has a valid value (to avoid crashes/strange behavior should the user
  // manually change the preference)
  return (depth > MAX_DISPLAY_DEPTH_LIMIT
          ? NO_DISPLAY_DEPTH_LIMIT
          : (unsigned)MAX(depth, MIN_DISPLAY_DEPTH_LIMIT));
}

@end
