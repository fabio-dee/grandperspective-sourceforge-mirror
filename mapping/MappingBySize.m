#import "MappingBySize.h"

#import "CompoundItem.h"
#import "DirectoryItem.h"
#import "PlainFileItem.h"
#import "FileItemMapping.h"
#import "TreeDrawerBaseSettings.h"
#import "LogManager.h"


@interface MaxItemSizeFinder : NSObject {
  BOOL  showPackageContents;
  BOOL  groupFiles;

  item_size_t  maxItemSize;
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithSettings:(TreeDrawerBaseSettings *)settings NS_DESIGNATED_INITIALIZER;

- (item_size_t) findMaximumItemSize:(DirectoryItem *)treeRoot;

- (void) visitItemToDetermineSizeBounds:(Item *)item;

@end // @interface MaxItemSizeFinder


/* Mapping scheme that maps each file item to a hash based on a time that is associated with the
 * file item.
 */
@interface SizeBasedMapping : FileItemMapping {
  // The lower size bound for the category containing the largest file items
  item_size_t maxItemSizeLimit;
}

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithTree:(DirectoryItem *)tree
                     settings:(TreeDrawerBaseSettings *)settings NS_DESIGNATED_INITIALIZER;

@end // @interface SizeBasedMapping


@interface SizeBasedMapping (PrivateMethods)

- (void) initSizeBounds:(DirectoryItem *)treeRoot settings:(TreeDrawerBaseSettings *)settings;

@end // @interface SizeBasedMapping (PrivateMethods)


@implementation SizeBasedMapping

// All items below this size map to the same hash
const item_size_t  minUpperBound = 1024;

- (instancetype) initWithTree:(DirectoryItem *)tree
                     settings:(TreeDrawerBaseSettings *)settings {
  if (self = [super init]) {
    [self initSizeBounds: tree settings: settings];
  }
  return self;
}


- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  item_size_t  itemSize = item.itemSize;
  item_size_t  limit = maxItemSizeLimit;
  NSUInteger  hash = 0;

  while (limit > minUpperBound) {
    if (itemSize > limit) {
      return hash;
    }
    hash++;
    limit /= 2;
  }

  return hash;
}

- (NSUInteger) colorIndexForHash:(NSUInteger)hash numColors:(NSUInteger)numColors {
  NSUInteger maxIndex = numColors - 1;

  return maxIndex - MIN(hash, maxIndex);
}

- (BOOL)providesLegend {
  return YES;
}

- (NSString *)legendForColorIndex:(NSUInteger)colorIndex numColors:(NSUInteger)numColors {
  NSUInteger maxIndex = numColors - 1;
  NSUInteger hash = maxIndex - colorIndex;

  if (hash == 0) {
    NSString *fmt = NSLocalizedString(@"Larger than %@",
                                      @"Legend for Size-based mapping scheme.");
    return [NSString stringWithFormat: fmt, [FileItem stringForFileItemSize: maxItemSizeLimit]];
  }

  item_size_t  lowerBound = maxItemSizeLimit;
  item_size_t  upperBound = 0;

  NSUInteger  i = hash;
  while (i > 0 && lowerBound >= minUpperBound) {
    upperBound = lowerBound;
    lowerBound /= 2;
    i--;
  }

  if (upperBound > minUpperBound) {
    if (colorIndex > 0) {
      NSString *fmt = NSLocalizedString(@"%@ - %@",
                                        @"Legend for Size-based mapping scheme.");
      return [NSString stringWithFormat: fmt,
              [FileItem stringForFileItemSize: lowerBound],
              [FileItem stringForFileItemSize: upperBound]];
    } else {
      return NSLocalizedString(@"Smallest",
                               @"Legend for Size-based mapping scheme.");
    }
  } else if (i == 0) {
    NSString *fmt = NSLocalizedString(@"Smaller than %@",
                                      @"Legend for Size-based mapping scheme.");
    return [NSString stringWithFormat: fmt,
            [FileItem stringForFileItemSize: upperBound]];
  } else {
    return nil;
  }
}

@end // @implementation TimeBasedMapping


@implementation SizeBasedMapping (PrivateMethods)

- (void) initSizeBounds:(DirectoryItem *)treeRoot settings:(TreeDrawerBaseSettings *)settings {
  MaxItemSizeFinder  *finder = [[[MaxItemSizeFinder alloc] initWithSettings: settings] autorelease];
  item_size_t maxItemSize = [finder findMaximumItemSize: treeRoot];

  os_log_info(LogManager.defaultLogManager.appLog,
              "maxItemSize = %lld", maxItemSize);

  // Round down towards clean boundary value
  item_size_t cleanLimit = minUpperBound;
  while (cleanLimit < maxItemSize) {
    cleanLimit *= 2;
  }

  maxItemSizeLimit = cleanLimit / 2;

  os_log_info(LogManager.defaultLogManager.appLog,
              "maxItemSizeLimit = %lld", maxItemSizeLimit);
}

@end // @implementation SizeBasedMapping (PrivateMethods)


@implementation MaxItemSizeFinder

- (instancetype) initWithSettings:(TreeDrawerBaseSettings *)settings {
  if (self = [super init]) {
    groupFiles = settings.drawItems == DRAW_FOLDERS;
    showPackageContents = settings.drawItems == DRAW_FILES;
  }

  return self;
}

- (item_size_t) findMaximumItemSize:(DirectoryItem *)treeRoot {
  maxItemSize = 0;

  [self visitItemToDetermineSizeBounds: treeRoot];

  return maxItemSize;
}

- (void) visitItemToDetermineSizeBounds:(Item *)item {
  if (item.itemSize <= maxItemSize) {
    // Abort recursive descend, as we cannot increase limit
    return;
  }

  if (item.isVirtual) {
    [self visitItemToDetermineSizeBounds: ((CompoundItem *)item).first];
    [self visitItemToDetermineSizeBounds: ((CompoundItem *)item).second];

    return;
  }

  FileItem  *fileItem = (FileItem *)item;

  if (fileItem.isDirectory) {
    if (fileItem.isPackage && !showPackageContents) {
      maxItemSize = MAX(maxItemSize, fileItem.itemSize);
    } else {
      [self visitItemToDetermineSizeBounds: ((DirectoryItem *)fileItem).directoryItems];

      if (groupFiles) {
        maxItemSize = MAX(maxItemSize, ((DirectoryItem *)fileItem).fileItems.itemSize);
      } else {
        [self visitItemToDetermineSizeBounds: ((DirectoryItem *)fileItem).fileItems];
      }
    }

    return;
  }

  if (fileItem.isPhysical) {
    maxItemSize = MAX(maxItemSize, fileItem.itemSize);
  }
}

@end // @implementation MaxItemSizeFinder


@implementation MappingBySize

- (BOOL)dependsOnTreeDrawerSettings {
  return YES;
}

- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree
                                   settings:(TreeDrawerBaseSettings *)settings {
  return [[[SizeBasedMapping alloc] initWithTree: tree
                                        settings:(TreeDrawerBaseSettings *)settings] autorelease];
}

@end // @implementation MappingBySize
