#import "UniformTypeRanking.h"

#import "UniformType.h"
#import "UniformTypeInventory.h"

@import UniformTypeIdentifiers;


NSString  *UniformTypeRankingChangedEvent = @"uniformTypeRankingChanged";

NSString  *UniformTypesRankingKey = @"uniformTypesRanking";

@interface UniformTypeRanking (PrivateMethods) 

- (void) uniformTypeAdded:(NSNotification *)notification;

@end


@implementation UniformTypeRanking

+ (UniformTypeRanking *)defaultUniformTypeRanking {
  static UniformTypeRanking  *defaultUniformTypeRankingInstance = nil;
  static dispatch_once_t  onceToken;

  dispatch_once(&onceToken, ^{
    defaultUniformTypeRankingInstance = [[UniformTypeRanking alloc] init];
  });
  
  return defaultUniformTypeRankingInstance;
}


- (instancetype) init {
  if (self = [super init]) {
    rankedTypes = [[NSMutableArray alloc] initWithCapacity: 32];
  }
  
  return self;
}

- (void) dealloc {
  [NSNotificationCenter.defaultCenter removeObserver: self];

  [rankedTypes release];
  
  [super dealloc];
}


- (void) loadRanking:(UniformTypeInventory *)typeInventory {
  NSAssert(rankedTypes.count == 0, @"List must be empty before load.");
  
  NSArray  *rankedUTIs = [NSUserDefaults.standardUserDefaults arrayForKey: UniformTypesRankingKey];

  for (NSString *uti in [rankedUTIs objectEnumerator]) {
    UTType  *type = [typeInventory uniformTypeForIdentifier: uti];
    
    if (!type.isUnknown || [uti isEqualToString: UTType.unknownType.identifier]) {
      [rankedTypes addObject: type];
    }
  }
}

- (void) storeRanking {
  NSMutableArray  *rankedUTIs = [NSMutableArray arrayWithCapacity: rankedTypes.count];
  NSMutableSet  *encountered = [NSMutableSet setWithCapacity: rankedUTIs.count];

  for (UTType *type in rankedTypes) {
    NSString  *uti = type.identifier;

    if (! [encountered containsObject: uti]) {
      // Should the ranked list contain duplicate UTIs, only add the first.
      [encountered addObject: uti];
     
      [rankedUTIs addObject: uti];
    }
  }

  [NSUserDefaults.standardUserDefaults setObject: rankedUTIs forKey: UniformTypesRankingKey];
}


- (void) observeUniformTypeInventory:(UniformTypeInventory *)typeInventory {
  // Observe the inventory to for newly added types so that these can be added
  // to (the end of) the ranked list. 
  [NSNotificationCenter.defaultCenter addObserver: self
                                         selector: @selector(uniformTypeAdded:)
                                             name: UniformTypeAddedEvent
                                           object: typeInventory];
        
  // Also add any types in the inventory that are not yet in the ranking
  NSMutableSet  *typesInRanking = [NSMutableSet setWithCapacity: (rankedTypes.count + 16)];
  [typesInRanking addObjectsFromArray: rankedTypes];

  for (UTType *type in [typeInventory uniformTypeEnumerator]) {
    if (! [typesInRanking containsObject: type]) {
      [rankedTypes addObject: type];
      [typesInRanking addObject: type]; 
    }
  }
}


- (NSArray *)rankedUniformTypes {
  // Return an immutable copy of the array.
  return [NSArray arrayWithArray: rankedTypes]; 
}

- (void) updateRankedUniformTypes:(NSArray *)ranking {
  // Updates the ranking while keeping new types that may have appeared in the meantime.
  [rankedTypes replaceObjectsInRange: NSMakeRange(0, ranking.count)
                withObjectsFromArray: ranking];
  
  // Notify any observers.
  [NSNotificationCenter.defaultCenter postNotificationName: UniformTypeRankingChangedEvent
                                                    object: self];
}


- (BOOL) isUniformTypeDominated:(UTType *)type {
  NSSet  *ancestors = type.supertypes;

  for (UTType* higherType in rankedTypes) {
    if (higherType == type) {
      // Found the type in the list, without encountering any type that dominates it.
      return NO;
    }

    if ([ancestors containsObject: higherType]) {
      // Found a type that dominates this one.
      return YES;
    }
  }

  NSAssert(NO, @"Unexpected termination");
  return NO;
}

- (NSArray *)undominatedRankedUniformTypes {
  NSMutableArray  *undominatedTypes = [NSMutableArray arrayWithCapacity: rankedTypes.count];

  for (UTType* type in rankedTypes) {
    if (! [self isUniformTypeDominated: type]) {
      [undominatedTypes addObject: type];
    }
  }
  
  return undominatedTypes;
}

@end // @implementation UniformTypeRanking


@implementation UniformTypeRanking (PrivateMethods) 

- (void) uniformTypeAdded:(NSNotification *)notification {
  UTType  *type = notification.userInfo[UniformTypeKey];

  [rankedTypes addObject: type];
}

@end // @implementation UniformTypeRanking (PrivateMethods) 
