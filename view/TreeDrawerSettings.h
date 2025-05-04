#import "TreeDrawerBaseSettings.h"

@protocol FileItemMapping;
@class FileItemTest;


/* Settings for TreeDrawer objects. The settings are immutable, to facilitate use in multi-threading
 * context.
 */
@interface TreeDrawerSettings : TreeDrawerBaseSettings {
}

- (instancetype) initWithColorMapper:(NSObject <FileItemMapping> *)colorMapper
                        colorPalette:(NSColorList *)colorPalette
                       colorGradient:(float)colorGradient
                           drawItems:(DrawItemsEnum)drawItems
                            maskTest:(FileItemTest *)maskTest
                        displayDepth:(unsigned)displayDepth NS_DESIGNATED_INITIALIZER;

- (instancetype) settingsWithChangedColorMapper:(NSObject <FileItemMapping> *)colorMapper;
- (instancetype) settingsWithChangedColorPalette:(NSColorList *)colorPalette;
- (instancetype) settingsWithChangedColorGradient:(float)colorGradient;
- (instancetype) settingsWithChangedMaskTest:(FileItemTest *)maskTest;

@property (nonatomic, readonly, strong) NSObject<FileItemMapping> *colorMapper;
@property (nonatomic, readonly, strong) NSColorList *colorPalette;
@property (nonatomic, readonly) float colorGradient;
@property (nonatomic, readonly, strong) FileItemTest *maskTest;

@end
