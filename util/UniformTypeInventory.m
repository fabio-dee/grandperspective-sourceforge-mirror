#import "UniformTypeInventory.h"

@import UniformTypeIdentifiers;

#import "FileItem.h"
#import "UniformType.h"
#import "LogManager.h"


NSString  *UniformTypeAddedEvent = @"uniformTypeAdded";

NSString  *UniformTypeKey = @"uniformType";

@interface UniformTypeInventory (PrivateMethods) 

- (void) postNotification:(NSNotification *)notification;

- (UniformType *)createUniformTypeForIdentifier:(NSString *)uti;

@end


@implementation UniformTypeInventory

+ (UniformTypeInventory *)defaultUniformTypeInventory {
  static UniformTypeInventory  *defaultUniformTypeInventoryInstance = nil;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    defaultUniformTypeInventoryInstance = [[UniformTypeInventory alloc] init];
  });
  
  return defaultUniformTypeInventoryInstance;
}


// Overrides super's designated initialiser.
- (instancetype) init {
  if (self = [super init]) {
    typeForExtension = [[NSMutableDictionary alloc] initWithCapacity: 32];
    typeForUTI = [[NSMutableDictionary alloc] initWithCapacity: 32];

    UniformType*  unknownType = UniformType.unknownType;
    typeForUTI[unknownType.uniformTypeIdentifier] = unknownType;
  }
  
  return self;
}

- (void) dealloc {

  [typeForExtension release];
  [typeForUTI release];
    
  [super dealloc];
}


- (NSUInteger) count {
  return typeForUTI.count;
}


- (NSEnumerator *)uniformTypeEnumerator {
  return [typeForUTI objectEnumerator];
}


- (UniformType *)uniformTypeForExtension:(NSString *)ext {
  UniformType  *type = typeForExtension[ext];
  if (type != nil) {
    // The extension was already encountered.
    return type;
  }

  UTType  *uttype = [UTType typeWithFilenameExtension: ext];
  if (uttype.isPublicType || uttype.isDeclared) {
    // Only create types for declared types (not for dynamically created ones).
    //
    // Note: The below method may return nil. This can happen when an UTI has been registered for
    // an extension without additional information describing the type.

    type = [self uniformTypeForIdentifier: uttype.identifier];
  }

  if (type == nil) {
    type = UniformType.unknownType;
  }

  typeForExtension[ext] = type;
  return type;
}

- (UniformType *)uniformTypeForIdentifier:(NSString *)uti {
  UniformType  *type = typeForUTI[uti];

  if (type != nil) {
    // It has already been registered
    return type;
  }

  // Temporarily associate "unknown" with the UTI to mark that the type is currently being created.
  // This is done to guard against infinite recursion should there be a cycle in the
  // type-conformance relationships.
  typeForUTI[uti] = UniformType.unknownType;

  type = [self createUniformTypeForIdentifier: uti];

  if (type == nil) {
    // No uniform type could be created for the UTI

    os_log_info(LogManager.defaultLogManager.mainLog, "Failed to create type for %{public}@", uti);

    return UniformType.unknownType;
  }
  
  typeForUTI[uti] = type;

  // Notify interested observers
  NSNotification  *notification = 
    [NSNotification notificationWithName: UniformTypeAddedEvent 
                                  object: self
                                userInfo: @{UniformTypeKey: type}];
  [self performSelectorOnMainThread: @selector(postNotification:)
                         withObject: notification
                      waitUntilDone: NO];
  
  return type;
}

@end // @implementation UniformTypeInventory


@implementation UniformTypeInventory (PrivateMethods)

- (void) postNotification:(NSNotification *)notification {
  [NSNotificationCenter.defaultCenter postNotification: notification];
}

- (UniformType *)createUniformTypeForIdentifier:(NSString *)uti {
  UTType  *uttype = [UTType typeWithIdentifier: uti];
    
  if (uttype == nil) {
    // The UTI is not recognized.
    return nil;
  }

  // Ensure all ancestor types are also created
  for (UTType* ancestor in uttype.supertypes) {
    [self uniformTypeForIdentifier: ancestor.identifier];
  }

  return [[[UniformType alloc] initWithUTType: uttype] autorelease];
}

@end // @implementation UniformTypeInventory (PrivateMethods)
