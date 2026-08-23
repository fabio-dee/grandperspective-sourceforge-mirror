#import <Cocoa/Cocoa.h>

#import <UniformTypeIdentifiers/UTType.h>

@interface UTType (HelperMethods)

/* Creates a shared file type instance that should be used for all unknown file types
 * (irrespective of their file extension).
 */
+ (UTType *)unknownType;

@property (nonatomic, readonly) BOOL isUnknown;

/* Thin wrapper around UTType.identifier. For the unknown type, it returns a fixed, human-readable
 * identifier.
 */
@property (nonatomic, readonly, copy) NSString *uniformTypeIdentifier;

/* Convenience method that constructs a set of all direct parents from the set of all ancestors.
 */
@property (nonatomic, readonly, copy) NSSet *parentUTTypes;

@end
