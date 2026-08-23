#import "UniformType.h"

@import UniformTypeIdentifiers;


// The UTI that is used when the type is unknown (i.e. when there is no proper UTI associated with
// a given file or extension).
//
// It is only used as an internal UTI and not exported/visible outside the application.
NSString  *UnknownTypeUTI = @"unknown";


@implementation UniformType

+ (UniformType *)unknownType {
  static UniformType*  unknownType;
  static dispatch_once_t  onceToken;

  dispatch_once(&onceToken, ^{
    unknownType = [[UniformType alloc] initWithUTType: nil];
  });

  return unknownType;
}

- (instancetype) initWithUTType:(UTType *)typeVal {
  if (self = [super init]) {
    type = [typeVal retain];
  }
  
  return self;
}

- (void) dealloc {
  [type release];

  [super dealloc];
}

- (BOOL) isUnknown {
  return (self == UniformType.unknownType);
}

- (UTType *)utType {
  return type;
}

- (NSString *)uniformTypeIdentifier {
  return type ? type.identifier : UnknownTypeUTI;
}

- (NSString *)description {
  return (type
          ? type.localizedDescription
          : NSLocalizedString(@"unknown file type", @"Description for 'unknown' UTI."));
}

- (NSSet *)parentUTTypes {
  if (type == nil) {
    return [NSSet set];
  }

  NSSet*  ancestors = type.supertypes;
  NSMutableSet*  parents = [NSMutableSet setWithSet: ancestors];

  for (UTType* tp in ancestors) {
    [parents minusSet: tp.supertypes];
  }

  return parents;
}

@end
