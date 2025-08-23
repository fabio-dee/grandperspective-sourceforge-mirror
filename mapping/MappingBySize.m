#import "MappingBySize.h"

#import "CompoundItem.h"
#import "DirectoryItem.h"
#import "PlainFileItem.h"
#import "StatefulFileItemMapping.h"


/* Mapping scheme that maps each file item to a hash based on a time that is associated with the
 * file item.
 */
@interface SizeBasedMapping : StatefulFileItemMapping {
  // The lower size bound for the category containing the largest file items
  item_size_t maxItemSizeLimit;
}

// Overrides designated initialiser
- (instancetype) initWithFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)schemeVal NS_UNAVAILABLE;

- (instancetype) initWithFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)scheme
                                          tree:(DirectoryItem *)tree NS_DESIGNATED_INITIALIZER;

@end // @interface SizeBasedMapping


@interface SizeBasedMapping (PrivateMethods)

- (void) initSizeBounds:(DirectoryItem *)treeRoot;
- (void) visitItemToDetermineSizeBounds:(Item *)item;

@end // @interface SizeBasedMapping (PrivateMethods)


@implementation SizeBasedMapping

// All items below this size map to the same hash
const item_size_t  minUpperBound = 1024;

- (instancetype) initWithFileItemMappingScheme:(NSObject <FileItemMappingScheme> *)schemeVal
                                          tree:(DirectoryItem *)tree {
  if (self = [super initWithFileItemMappingScheme: schemeVal]) {
    [self initSizeBounds: tree];
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


- (BOOL) canProvideLegend {
  return YES;
}


//----------------------------------------------------------------------------
// Implementation of LegendProvidingFileItemMapping

- (NSString *)descriptionForHash: (NSUInteger)hash {
  CFAbsoluteTime  lowerBound = maxItemSizeLimit;
  CFAbsoluteTime  upperBound = 0;

  NSUInteger  i = hash;
  while (i > 0) {
    upperBound = lowerBound;
    lowerBound /= 2;
    i--;
  }

  if (hash == 0) {
    NSString *fmt = NSLocalizedString(@"More than %@",
                                      @"Legend for Size-based mapping scheme.");
    return [NSString stringWithFormat: fmt, [FileItem stringForFileItemSize: lowerBound]];
  } else {
    NSString *fmt = NSLocalizedString(@"%@ - %@",
                                      @"Legend for Size-based mapping scheme.");
    return [NSString stringWithFormat: fmt,
            [FileItem stringForFileItemSize: upperBound],
            [FileItem stringForFileItemSize: lowerBound]];
  }
}

- (NSString *) descriptionForRemainingHashes {
  return NSLocalizedString(@"Smaller",
                           @"Legend for Size-based mapping scheme.");
}

@end // @implementation TimeBasedMapping


@implementation SizeBasedMapping (PrivateMethods)

- (void) initSizeBounds:(DirectoryItem *)treeRoot {
  maxItemSizeLimit = 0;

  [self visitItemToDetermineSizeBounds: treeRoot];

  NSLog(@"maxSize (before) = %lld", maxItemSizeLimit);

  // Round down towards clean boundary value
  item_size_t cleanLimit = minUpperBound;
  while (cleanLimit < maxItemSizeLimit) {
    cleanLimit *= 2;
  }

  maxItemSizeLimit = cleanLimit / 2;

  NSLog(@"maxSize (after) = %lld", maxItemSizeLimit);
}


- (void) visitItemToDetermineSizeBounds:(Item *)item {
  if (item.isVirtual) {
    [self visitItemToDetermineSizeBounds: ((CompoundItem *)item).first];
    [self visitItemToDetermineSizeBounds: ((CompoundItem *)item).second];
  }
  else {
    FileItem  *fileItem = (FileItem *)item;

    if (fileItem.isDirectory) {
      if (fileItem.itemSize > maxItemSizeLimit) {
        [self visitItemToDetermineSizeBounds: ((DirectoryItem *)fileItem).fileItems];
        [self visitItemToDetermineSizeBounds: ((DirectoryItem *)fileItem).directoryItems];
      }
    } else if (fileItem.isPhysical) {
      maxItemSizeLimit = MAX(maxItemSizeLimit, fileItem.itemSize);
    }
  }
}

@end // @implementation SizeBasedMapping (PrivateMethods)


@implementation MappingBySize

//----------------------------------------------------------------------------
// Implementation of FileItemMappingScheme protocol

- (NSObject <FileItemMapping> *)fileItemMappingForTree:(DirectoryItem *)tree {
  return [[[SizeBasedMapping alloc] initWithFileItemMappingScheme: self tree: tree] autorelease];
}

@end // @implementation MappingBySize
