#import <Foundation/Foundation.h>

#import "StatefullFileItemMapping.h"

/* Mapping scheme that maps each file item to a hash based on its creation time.
 */
@interface CreationMappingScheme : StatefullFileItemMapping
@end

/* Mapping scheme that maps each file item to a hash based on its modification time.
 */
@interface ModificationMappingScheme : StatefullFileItemMapping
@end

/* Mapping scheme that maps each file item to a hash based on its last access time.
 */
@interface AccessMappingScheme : StatefullFileItemMapping
@end
