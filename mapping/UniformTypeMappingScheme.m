#import "UniformTypeMappingScheme.h"

#import "FileItemMapping.h"
#import "PlainFileItem.h"
#import "UniformType.h"
#import "UniformTypeRanking.h"

@import UniformTypeIdentifiers;


@interface UniformTypeMappingScheme (PrivateMethods)

- (void) typeRankingChanged:(NSNotification *)notification;

@end


@interface MappingByUniformType : FileItemMapping {

  // Cache mapping UTIs (NSString) to integer values (NSNumber)
  NSMutableDictionary  *hashForUTICache;
  
  NSArray  *orderedTypes;
}

- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithUniformTypeRanking:(UniformTypeRanking *)typeRanking
  NS_DESIGNATED_INITIALIZER;

- (NSUInteger) findIndexForType:(UTType *)uniformType;

@end


@implementation UniformTypeMappingScheme

- (instancetype) init {
  return [self initWithUniformTypeRanking: UniformTypeRanking.defaultUniformTypeRanking];

}

- (instancetype) initWithUniformTypeRanking: (UniformTypeRanking *)typeRanking {
  if (self = [super init]) {
    _uniformTypeRanking = [typeRanking retain];
    
    NSNotificationCenter  *nc = NSNotificationCenter.defaultCenter;

    [nc addObserver: self
           selector: @selector(typeRankingChanged:)
               name: UniformTypeRankingChangedEvent
             object: typeRanking];
  }
  
  return self;
}

- (void) dealloc {
  [NSNotificationCenter.defaultCenter removeObserver: self];
  
  [_uniformTypeRanking release];
  
  [super dealloc];
}


//----------------------------------------------------------------------------
// Implementation of FileItemMappingScheme

- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree {
  return [[[MappingByUniformType alloc] initWithUniformTypeRanking: _uniformTypeRanking]
          autorelease];
}

@end // @implementation UniformTypeMappingScheme


@implementation UniformTypeMappingScheme (PrivateMethods)

- (void) typeRankingChanged: (NSNotification *)notification {
  NSNotificationCenter  *nc = NSNotificationCenter.defaultCenter;
  
  [nc postNotificationName: MappingSchemeChangedEvent object: self];
}

@end // @implementation UniformTypeMappingScheme (PrivateMethods)


@implementation MappingByUniformType

- (instancetype) initWithUniformTypeRanking:(UniformTypeRanking *)typeRanking {

  if (self = [super init]) {
    hashForUTICache = [[NSMutableDictionary dictionaryWithCapacity: 16] retain];
    orderedTypes = [typeRanking.undominatedRankedUniformTypes retain];
  }
  
  return self;
}

- (void) dealloc {
  [hashForUTICache release];
  [orderedTypes release];
  
  [super dealloc];
}


- (NSUInteger) findIndexForType:(UTType *)targetType {
  __block NSUInteger retVal = NSIntegerMax;

  NSSet *ancestorTypes = targetType.supertypes;

  [orderedTypes enumerateObjectsUsingBlock:^(UTType *type, NSUInteger idx, BOOL *stop) {
    if (type == targetType || [ancestorTypes containsObject: type]) {
      // Found the first type in the list that the file item conforms to.
      retVal = idx;
      *stop = YES;
    }
  }];

  return retVal;
}

//----------------------------------------------------------------------------
// Implementation of FileItemMapping protocol

- (NSUInteger) hashForFileItem:(FileItem *)item atDepth:(NSUInteger)depth {
  UTType  *type = item.isDirectory ? nil : ((PlainFileItem *)item).uniformType;

  if (type == nil) {
    // Unknown type
    return NSIntegerMax;
  }

  NSNumber  *hash = hashForUTICache[type.identifier];
  if (hash != nil) {
    return hash.intValue;
  }

  NSUInteger  utiIndex = [self findIndexForType: type];

  // Add it to the cache for next time.
  hashForUTICache[type.identifier] = @(utiIndex);
  return utiIndex;
}

- (NSUInteger) colorIndexForHash:(NSUInteger)hash numColors:(NSUInteger)numColors {
  return MIN(hash, numColors - 1);
}

- (BOOL)providesLegend {
  return YES;
}

- (NSString *)legendForColorIndex:(NSUInteger)colorIndex numColors:(NSUInteger)numColors {
  if (colorIndex >= orderedTypes.count) {
    return nil;
  }

  if (colorIndex == numColors - 1) {
    return NSLocalizedString(@"other file types",
                             @"Misc. description for File type mapping scheme.");
  }
  
  UTType  *type = orderedTypes[colorIndex];
  NSString  *descr = type.description;
   
  return (descr != nil) ? descr : type.identifier;
}

@end
