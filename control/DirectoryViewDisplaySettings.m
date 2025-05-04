#import "DirectoryViewDisplaySettings.h"

#import "TreeDrawerBaseSettings.h"
#import "PreferencesPanelControl.h"

@implementation DirectoryViewDisplaySettings

- (instancetype) init {
  NSUserDefaults  *ud = NSUserDefaults.standardUserDefaults;

  return [self initWithColorMappingKey: [ud stringForKey: DefaultColorMappingKey]
                       colorPaletteKey: [ud stringForKey: DefaultColorPaletteKey]
                          drawItemsKey: [ud stringForKey: DefaultDrawItemsKey]
                              maskName: [ud stringForKey: MaskFilterKey]
                           maskEnabled: NO
                      showEntireVolume: [ud boolForKey: ShowEntireVolumeByDefaultKey]];
}

- (instancetype) initWithColorMappingKey:(NSString *)colorMappingKey
                         colorPaletteKey:(NSString *)colorPaletteKey
                            drawItemsKey:(NSString *)drawItemsKey
                                maskName:(NSString *)maskName
                             maskEnabled:(BOOL)maskEnabled
                        showEntireVolume:(BOOL)showEntireVolume {
  if (self = [super init]) {
    _colorMappingKey = [colorMappingKey retain];
    _colorPaletteKey = [colorPaletteKey retain];
    _drawItemsKey = [drawItemsKey retain];
    _maskName = [maskName retain];
    _fileItemMaskEnabled = maskEnabled;
    _showEntireVolume = showEntireVolume;
  }

  return self;
}

- (void) dealloc {
  [_colorMappingKey release];
  [_colorPaletteKey release];
  [_drawItemsKey release];
  [_maskName release];

  [super dealloc];
}

- (id) copyWithZone:(NSZone *)zone {
  return [[[self class] allocWithZone: zone] initWithColorMappingKey: _colorMappingKey
                                                     colorPaletteKey: _colorPaletteKey
                                                        drawItemsKey: _drawItemsKey
                                                            maskName: _maskName
                                                         maskEnabled: _fileItemMaskEnabled
                                                    showEntireVolume: _showEntireVolume];
}

+ (DirectoryViewDisplaySettings *)defaultSettings {
  return [[[DirectoryViewDisplaySettings alloc] init] autorelease];
}

- (BOOL) packagesAsFiles {
  return ![_drawItemsKey isEqualToString: DrawFilesKey];
}

@end
