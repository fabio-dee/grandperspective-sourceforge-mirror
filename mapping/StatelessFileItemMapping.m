#import "StatelessFileItemMapping.h"

@implementation StatelessFileItemMapping

- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree
                                   settings:(TreeDrawerBaseSettings *)settings {
  return self;
}

@end
