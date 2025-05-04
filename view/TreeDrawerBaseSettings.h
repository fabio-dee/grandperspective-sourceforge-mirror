#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern const unsigned MIN_DISPLAY_DEPTH_LIMIT;

// The maximum depth limit, when a limit is applied
extern const unsigned MAX_DISPLAY_DEPTH_LIMIT;

// The depth limit value when there is no depth limiting
extern const unsigned NO_DISPLAY_DEPTH_LIMIT;

typedef NS_ENUM(NSInteger, DrawItemsEnum) {
  DRAW_NONE, // To be used when not set
  DRAW_FILES,
  DRAW_PACKAGES,
  DRAW_FOLDERS,
};

extern NSString* DrawFilesKey;
extern NSString* DrawPackagesKey;
extern NSString* DrawFoldersKey;


@interface TreeDrawerBaseSettings : NSObject {
}

+ (NSArray *)drawItemsNames;
+ (DrawItemsEnum) enumForDrawItemsName:(NSString *)name;
+ (NSString *)nameForDrawItemsEnum:(DrawItemsEnum) value;

// Creates default settings.
- (instancetype) init;

- (instancetype) initWithDisplayDepth:(unsigned)displayDepth
                            drawItems:(DrawItemsEnum)drawItems NS_DESIGNATED_INITIALIZER;

- (instancetype) settingsWithChangedDisplayDepth:(unsigned)displayDepth;
- (instancetype) settingsWithChangedDrawItems:(DrawItemsEnum)drawItems;

// The maximum depth that the drawer visits when drawing the tree. Directories at this depth are
// displayed a single blocks.
@property (nonatomic, readonly) unsigned displayDepth;

@property (nonatomic, readonly) DrawItemsEnum drawItems;

@property (class, nonatomic, readonly) DrawItemsEnum defaultDrawItems;
@property (class, nonatomic, readonly) unsigned defaultDisplayDepth;

@end

NS_ASSUME_NONNULL_END
