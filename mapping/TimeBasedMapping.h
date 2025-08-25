#import <Foundation/Foundation.h>

#import "FileItemMapping.h"

@class DirectoryItem;
@class FileItem;

/* Mapping scheme that maps each file item to a hash based on a time that is associated with the
 * file item.
 */
@interface TimeBasedMapping : FileItemMapping {
  CFAbsoluteTime  minTime;
  CFAbsoluteTime  maxTime;
  CFAbsoluteTime  nowTime;
}

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithTree:(DirectoryItem *)tree NS_DESIGNATED_INITIALIZER;

@end // @interface TimeBasedMapping


@interface TimeBasedMapping (ProtectedMethods)

- (CFAbsoluteTime) timeForFileItem:(FileItem *)fileItem;

@end // @interface TimeBasedMapping (ProtectedMethods)
