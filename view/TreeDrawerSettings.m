#import <Cocoa/Cocoa.h>

#import "TreeDrawerSettings.h"

#import "StatelessFileItemMapping.h"
#import "PreferencesPanelControl.h"


@interface TreeDrawerSettings (PrivateMethods)

@property (class, nonatomic, readonly) NSColorList *defaultColorPalette;

@end


@implementation TreeDrawerSettings

- (instancetype) initWithDisplayDepth:(unsigned)displayDepth
                            drawItems:(DrawItemsEnum)drawItems {
  NSUserDefaults  *userDefaults = NSUserDefaults.standardUserDefaults;

  return [self initWithColorMapper: [[[StatelessFileItemMapping alloc] init] autorelease]
                      colorPalette: TreeDrawerSettings.defaultColorPalette
                     colorGradient: [userDefaults floatForKey: DefaultColorGradient]
                         drawItems: drawItems
                          maskTest: nil
                      displayDepth: displayDepth];
}


- (instancetype) initWithColorMapper:(NSObject <FileItemMapping> *)colorMapper
                        colorPalette:(NSColorList *)colorPalette
                       colorGradient:(float)colorGradient
                           drawItems:(DrawItemsEnum)drawItems
                            maskTest:(FileItemTest *)maskTest
                        displayDepth:(unsigned)displayDepth {
  if (self = [super initWithDisplayDepth: displayDepth drawItems: drawItems]) {
    _colorMapper = [colorMapper retain];
    _colorPalette = [colorPalette retain];
    _colorGradient = colorGradient;
    _maskTest = [maskTest retain];
  }
  
  return self;
}

- (void) dealloc {
  [_colorMapper release];
  [_colorPalette release];
  [_maskTest release];
  
  [super dealloc];
}


- (instancetype) settingsWithChangedColorMapper:(NSObject <FileItemMapping> *)colorMapper {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: self.colorGradient
                                                drawItems: self.drawItems
                                                 maskTest: self.maskTest
                                             displayDepth: self.displayDepth] autorelease];
}

- (instancetype) settingsWithChangedColorPalette:(NSColorList *)colorPalette {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: colorPalette
                                            colorGradient: self.colorGradient
                                                drawItems: self.drawItems
                                                 maskTest: self.maskTest
                                             displayDepth: self.displayDepth] autorelease];
}

- (instancetype) settingsWithChangedColorGradient:(float) colorGradient {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: colorGradient
                                                drawItems: self.drawItems
                                                 maskTest: self.maskTest
                                             displayDepth: self.displayDepth] autorelease];
}

- (instancetype) settingsWithChangedMaskTest:(FileItemTest *)maskTest {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: self.colorGradient
                                                drawItems: self.drawItems
                                                 maskTest: maskTest
                                             displayDepth: self.displayDepth] autorelease];
}

- (instancetype) settingsWithChangedDisplayDepth:(unsigned) displayDepth {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: self.colorGradient
                                                drawItems: self.drawItems
                                                 maskTest: self.maskTest
                                             displayDepth: displayDepth] autorelease];
}

- (instancetype) settingsWithChangedShowPackageContents:(BOOL) showPackageContents {
  return [[[TreeDrawerSettings alloc] initWithColorMapper: self.colorMapper
                                             colorPalette: self.colorPalette
                                            colorGradient: self.colorGradient
                                                drawItems: self.drawItems
                                                 maskTest: self.maskTest
                                             displayDepth: self.displayDepth] autorelease];
}

@end // @implementation TreeDrawerSettings


NSColorList  *defaultColorPalette = nil;

@implementation TreeDrawerSettings (PrivateMethods)

+ (NSColorList *)defaultColorPalette {
  if (defaultColorPalette == nil) {
    NSColorList  *colorList = [[NSColorList alloc] initWithName: @"DefaultTreeDrawerPalette"];

    [colorList insertColor: NSColor.blueColor    key: @"blue"    atIndex: 0];
    [colorList insertColor: NSColor.redColor     key: @"red"     atIndex: 1];
    [colorList insertColor: NSColor.greenColor   key: @"green"   atIndex: 2];
    [colorList insertColor: NSColor.cyanColor    key: @"cyan"    atIndex: 3];
    [colorList insertColor: NSColor.magentaColor key: @"magenta" atIndex: 4];
    [colorList insertColor: NSColor.orangeColor  key: @"orange"  atIndex: 5];
    [colorList insertColor: NSColor.yellowColor  key: @"yellow"  atIndex: 6];
    [colorList insertColor: NSColor.purpleColor  key: @"purple"  atIndex: 7];

    defaultColorPalette = colorList;
  }

  return defaultColorPalette;
}

@end // @implementation TreeDrawerSettings (PrivateMethods)
