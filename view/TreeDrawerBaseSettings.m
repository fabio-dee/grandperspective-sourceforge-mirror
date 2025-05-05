#import "TreeDrawerBaseSettings.h"

#import "PreferencesPanelControl.h"

const unsigned MIN_DISPLAY_DEPTH_LIMIT = 1;
const unsigned MAX_DISPLAY_DEPTH_LIMIT = 8;
const unsigned NO_DISPLAY_DEPTH_LIMIT = 0xFFFF;

NSString* DrawFilesKey = @"files";
NSString* DrawPackagesKey = @"packages and files";
NSString* DrawFoldersKey = @"folders";

@interface TreeDrawerBaseSettings (PrivateMethods)
+ (NSDictionary *)drawItemsMapping;
@end

@implementation TreeDrawerBaseSettings

+ (NSArray *)drawItemsNames {
  // Not return keys from mapping but constructing array to control order. This ensures that the
  // options appear in a logical order in the pop-up
  static NSArray *drawItemsNames = nil;
  static dispatch_once_t  onceToken;

  dispatch_once(&onceToken, ^{
    drawItemsNames = [@[DrawFilesKey, DrawPackagesKey, DrawFoldersKey] retain];
  });

  return drawItemsNames;
}

+ (DrawItemsEnum) enumForDrawItemsName:(NSString *)name {
  id value = [TreeDrawerBaseSettings.drawItemsMapping valueForKey: name];

  if (value != nil) {
    return ((NSNumber *)value).integerValue;
  }

  return DRAW_NONE;
}

+ (NSString *)nameForDrawItemsEnum:(DrawItemsEnum) value {
  id mapping = TreeDrawerBaseSettings.drawItemsMapping;
  for (NSString* key in mapping) {
    if (((NSNumber *)mapping[key]).integerValue == value) {
      return key;
    }
  }

  return DrawFilesKey;
}

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
          ? DRAW_FILES : DRAW_PACKAGES);
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

@implementation TreeDrawerBaseSettings (PrivateMethods)

+ (NSDictionary *)drawItemsMapping {
  static NSDictionary *drawItemsMapping = nil;
  static dispatch_once_t  onceToken;

  dispatch_once(&onceToken, ^{
    drawItemsMapping = [@{
      DrawFilesKey: [NSNumber numberWithInteger: DRAW_FILES],
      DrawPackagesKey: [NSNumber numberWithInteger: DRAW_PACKAGES],
      DrawFoldersKey: [NSNumber numberWithInteger: DRAW_FOLDERS]
    } retain];
  });

  return drawItemsMapping;
}

@end
