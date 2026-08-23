#import "UniformType.h"

// The UTI that is used when the type is unknown (i.e. when there is no proper UTI associated with
// a given file or extension).
//
// It is only used as an internal UTI and not exported/visible outside the application.
NSString  *UnknownTypeUTI = @"unknown";


@implementation UTType (HelperMethods)

+ (UTType *)unknownType {
  static UTType*  unknownType;
  static dispatch_once_t  onceToken;

  dispatch_once(&onceToken, ^{
    unknownType = [[UTType typeWithFilenameExtension: @"gp-unknown-filetype"] retain];
  });

  return unknownType;
}

- (BOOL) isUnknown {
  return (self == UTType.unknownType);
}

- (NSString *)description {
  return (self.isUnknown
          ? NSLocalizedString(@"unknown file type", @"Description for 'unknown' UTI.")
          : self.localizedDescription);
}

- (NSString *)uniformTypeIdentifier {
  return (self.isUnknown ? UnknownTypeUTI : self.identifier);
}

- (NSSet *)parentUTTypes {
  if (self.isUnknown) {
    return [NSSet set];
  }

  NSSet*  ancestors = self.supertypes;
  NSMutableSet*  parents = [NSMutableSet setWithSet: ancestors];

  for (UTType* tp in ancestors) {
    [parents minusSet: tp.supertypes];
  }

  return parents;
}

@end
