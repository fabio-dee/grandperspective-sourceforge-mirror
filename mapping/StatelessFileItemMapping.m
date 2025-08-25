#import "StatelessFileItemMapping.h"

@implementation StatelessFileItemMapping

- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree {
  return self;
}

@end
