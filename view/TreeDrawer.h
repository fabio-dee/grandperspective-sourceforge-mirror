#import <Cocoa/Cocoa.h>

#include "TreeDrawerBase.h"

@class TreeDrawerSettings;
@class FileItemTest;
@class FileItemMapping;
@protocol FileItemMappingScheme;

/* Event fired when the color mapper has changed. This is the case when the color mapping scheme
 * changed, or when the scheme changed the way it maps file items to hash values.
 */
extern NSString  *ColorMappingChangedEvent;

@interface TreeDrawer : TreeDrawerBase {
//  NSObject <FileItemMappingScheme>  *colorScheme;
  
  UInt32  freeSpaceColor;
  UInt32  usedSpaceColor;
  UInt32  visibleTreeBackgroundColor;
}

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree
               treeDrawerSettings:(TreeDrawerSettings *)settings NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) FileItemTest *maskTest;

@property (nonatomic, strong) NSObject<FileItemMappingScheme> *colorScheme;
@property (nonatomic, strong) FileItemMapping *colorMapper;

@end
