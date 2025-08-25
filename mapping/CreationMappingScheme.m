#import "CreationMappingScheme.h"

#import "FileItem.h"
#import "TimeBasedMapping.h"

@interface MappingByCreation : TimeBasedMapping
@end // @interface MappingByCreation


@implementation CreationMappingScheme

//----------------------------------------------------------------------------
// Implementation of FileItemMappingScheme protocol

- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree {
  return [[[MappingByCreation alloc] initWithTree: tree] autorelease];
}

@end // @implementation CreationMappingScheme


@implementation MappingByCreation

- (CFAbsoluteTime) timeForFileItem:(FileItem *)fileItem {
  return fileItem.creationTime;
}

@end // @implementation MappingByCreation
