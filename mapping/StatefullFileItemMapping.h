#import <Cocoa/Cocoa.h>

#import "FileItemMappingScheme.h"

/* Base class for file item mapping implementations that maintain state, are therefore not thread-
 * safe, and cannot therefore be shared.
 */
@interface StatefullFileItemMapping : NSObject <FileItemMappingScheme>
@end
