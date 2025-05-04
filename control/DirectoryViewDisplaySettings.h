#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DirectoryViewDisplaySettings : NSObject<NSCopying>

- (instancetype) initWithColorMappingKey:(NSString *)colorMappingKey
                         colorPaletteKey:(NSString *)colorPaletteKey
                            drawItemsKey:(NSString *)drawItemsKey
                                maskName:(NSString *)maskName
                             maskEnabled:(BOOL)maskEnabled
                        showEntireVolume:(BOOL)showEntireVolume NS_DESIGNATED_INITIALIZER;

+ (DirectoryViewDisplaySettings *)defaultSettings;

@property (nonatomic, copy) NSString *colorMappingKey;

@property (nonatomic, copy) NSString *colorPaletteKey;

@property (nonatomic, copy) NSString *drawItemsKey;

@property (nonatomic, copy, nullable) NSString *maskName;

@property (nonatomic) BOOL fileItemMaskEnabled;

@property (nonatomic) BOOL showEntireVolume;

@property (nonatomic) BOOL packagesAsFiles;

@end

NS_ASSUME_NONNULL_END
