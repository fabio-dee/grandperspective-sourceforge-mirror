#import "StatefullFileItemMapping.h"

@implementation StatefullFileItemMapping

- (BOOL)dependsOnTreeDrawerSettings {
  return NO;
}

- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree {
  NSAssert(NO, @"Abstract method invoked");
  return nil;
}

// Default implementation
- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree
                                   settings:(TreeDrawerBaseSettings *)settings {
  NSAssert(NO, @"Abstract method invoked");
  return nil;
}

@end
