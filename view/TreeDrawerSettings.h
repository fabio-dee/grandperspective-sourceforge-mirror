#import "TreeDrawerBaseSettings.h"

@protocol FileItemMappingScheme;
@class FileItemTest;


/* Settings for TreeDrawer objects. The settings are immutable, to facilitate use in multi-threading
 * context.
 */
@interface TreeDrawerSettings : TreeDrawerBaseSettings {
}

- (instancetype) initWithColorScheme:(NSObject <FileItemMappingScheme> *)colorScheme
                        colorPalette:(NSColorList *)colorPalette
                       colorGradient:(float)colorGradient
                           drawItems:(DrawItemsEnum)drawItems
                            maskTest:(FileItemTest *)maskTest
                        displayDepth:(unsigned)displayDepth NS_DESIGNATED_INITIALIZER;

- (instancetype) settingsWithChangedColorScheme:(NSObject <FileItemMappingScheme> *)colorScheme;
- (instancetype) settingsWithChangedColorPalette:(NSColorList *)colorPalette;
- (instancetype) settingsWithChangedColorGradient:(float)colorGradient;
- (instancetype) settingsWithChangedMaskTest:(FileItemTest *)maskTest;

@property (nonatomic, readonly, strong) NSObject<FileItemMappingScheme> *colorScheme;
@property (nonatomic, readonly, strong) NSColorList *colorPalette;
@property (nonatomic, readonly) float colorGradient;
@property (nonatomic, readonly, strong) FileItemTest *maskTest;

@end
