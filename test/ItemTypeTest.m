#import "ItemTypeTest.h"

#import "TestDescriptions.h"
#import "PlainFileItem.h"
#import "FileItemTestVisitor.h"
#import "UniformType.h"
#import "UniformTypeInventory.h"

@import UniformTypeIdentifiers;


@interface ItemTypeTest (PrivateMethods)

/* Note, this property constructs a new array on each invocation.
 */
@property (nonatomic, readonly, copy) NSArray *matchTargetsAsStrings;

@end


@implementation ItemTypeTest

- (instancetype) initWithMatchTargets:(NSArray *)matchTargets {
  return [self initWithMatchTargets: matchTargets strict: NO];
}

- (instancetype) initWithMatchTargets:(NSArray *)matchTargets strict:(BOOL)strict {
  if (self = [super init]) {
    // Make the array immutable
    _matchTargets = [[NSArray alloc] initWithArray: matchTargets];

    _strict = strict;
  }
  
  return self;
}

- (instancetype) initWithPropertiesFromDictionary:(NSDictionary *)dict {
  if (self = [super initWithPropertiesFromDictionary: dict]) {
    NSArray  *utis = dict[@"matches"];

    UniformTypeInventory  *typeInventory = UniformTypeInventory.defaultUniformTypeInventory;

    NSMutableArray  *tmpMatches = [NSMutableArray arrayWithCapacity: utis.count];

    for (NSString* uti in utis) {
      UTType  *type = [typeInventory uniformTypeForIdentifier: uti];

      if (!type.isUnknown || [uti isEqualToString: UTType.unknownType.uniformTypeIdentifier]) {
        [tmpMatches addObject: type];
      }
    }
    
    // Make the array immutable
    _matchTargets = [[NSArray alloc] initWithArray: tmpMatches];
    
    _strict = [dict[@"strict"] boolValue];
  }
  
  return self;
}

- (void) dealloc {
  [_matchTargets release];

  [super dealloc];
}


- (void) addPropertiesToDictionary:(NSMutableDictionary *)dict {
  [super addPropertiesToDictionary: dict];
  
  dict[@"class"] = @"ItemTypeTest";
  dict[@"matches"] = self.matchTargetsAsStrings;
  dict[@"strict"] = @(self.strict);
}


- (TestResult) testFileItem:(FileItem *)item context:(id) context {
  if (item.isDirectory) {
    // Test does not apply to directories
    return TestNotApplicable;
  }
  
  UTType  *type = ((PlainFileItem *)item).uniformType;
  NSSet  *ancestorTypes = self.isStrict ? nil : type.supertypes;

  for (UTType *matchType in self.matchTargets) {
    if (type == matchType || [ancestorTypes containsObject: matchType]) {
      return TestPassed;
    }
  }
  
  return TestFailed;
}

- (BOOL) appliesToDirectories {
  return NO;
}

- (void) acceptFileItemTestVisitor:(NSObject <FileItemTestVisitor> *)visitor {
  [visitor visitItemTypeTest: self];
}


- (NSString *)description {
  NSString  *matchTargetsDescr = descriptionForMatchTargets(self.matchTargetsAsStrings);
  NSString  *format = (self.isStrict
                       ? NSLocalizedStringFromTable(
                           @"type equals %@", @"Tests",
                           @"Filetype test with 1: match targets")
                       : NSLocalizedStringFromTable(
                           @"type conforms to %@", @"Tests",
                           @"Filetype test with 1: match targets"));
  
  return [NSString stringWithFormat: format, matchTargetsDescr];
}


+ (FileItemTest *)fileItemTestFromDictionary:(NSDictionary *)dict { 
  NSAssert([dict[@"class"] isEqualToString: @"ItemTypeTest"],
           @"Incorrect value for class in dictionary.");

  return [[[ItemTypeTest alloc] initWithPropertiesFromDictionary: dict] autorelease];
}

@end


@implementation ItemTypeTest (PrivateMethods)

- (NSArray *)matchTargetsAsStrings {
  NSMutableArray  *utis = [NSMutableArray arrayWithCapacity: self.matchTargets.count];

  for (UTType *type in self.matchTargets) {
    [utis addObject: type.uniformTypeIdentifier];
  }
  
  return utis;
}

@end // @implementation ItemTypeTest (PrivateMethods)
