#import "FileItemMapping.h"

@implementation FileItemMapping

- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  return 0;
}

- (NSUInteger) hashForFileItem:(FileItem *)item inTree:(FileItem *)treeRoot {
  // By default assuming that "depth" is not used in the hash calculation. If it is, this method
  // needs to be overridden.
  return [self hashForFileItem: item atDepth: 0];
}

- (NSUInteger) colorIndexForHash:(NSUInteger)hash numColors:(NSUInteger)numColors {
  // By default use modulus. More complex mappings can override this method so that all colors
  // except one (typically the last but not necessarily) represent only a single hash.
  return hash % numColors;
}

- (BOOL)providesLegend {
  return NO;
}

- (NSString *)legendForColorIndex:(NSUInteger)colorIndex numColors:(NSUInteger)numColors {
  // By default, no description
  return nil;
}

@end
