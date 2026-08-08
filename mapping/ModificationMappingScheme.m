#import "ModificationMappingScheme.h"

#import "FileItem.h"
#import "TimeBasedMapping.h"

@interface MappingByModification : TimeBasedMapping
@end // @interface MappingByModification


@implementation ModificationMappingScheme

//----------------------------------------------------------------------------
// Implementation of FileItemMappingScheme protocol

- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree
                                   settings:(TreeDrawerBaseSettings *)settings {
  return [[[MappingByModification alloc] initWithTree: tree] autorelease];
}

@end // @implementation ModificationMappingScheme


@implementation MappingByModification

- (CFAbsoluteTime) timeForFileItem:(FileItem *)fileItem {
  return fileItem.modificationTime;
}

@end // @implementation MappingByModification
