#import <Cocoa/Cocoa.h>


/* Very thin wrapper for "UTType". It is used to have a single type for all "unknown" types.
 *
 * Note: Instances are immutable (and therefore thread-safe).
 */
@interface UniformType : NSObject {
  // The wrapped type. It is nil when there is no type known.
  UTType  *type;
}

+ (UniformType *)unknownType;

// Overrides super's designated initialiser.
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithUTType:(UTType *)type NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) BOOL isUnknown;

@property (nonatomic, readonly, copy) UTType *utType;

@property (nonatomic, readonly, copy) NSString *uniformTypeIdentifier;

@property (nonatomic, readonly, copy) NSString *description;

@property (nonatomic, readonly, copy) NSSet *parentUTTypes;

@end
