#import <Cocoa/Cocoa.h>


/* Event that is fired by a mapping sheme to signal that there have been changes that may cause
 * one or more file items to map to a different hash value.
 */
extern NSString  *MappingSchemeChangedEvent;


@class FileItemMapping;
@class DirectoryItem;
@class TreeDrawerBaseSettings;

/* A file item mapping scheme. It represents a particular algorithm for mapping file items to hash
 * values.
 *
 * File item mapping scheme can safely be used from multiple threads by multiple different views.
 */
@protocol FileItemMappingScheme

- (BOOL)dependsOnTreeDrawerSettings;

/* Returns a file item mapping instance that implements the scheme for the given tree. When the
 * implementation cannot be shared by multiple different views, a new instance is returned for each
 * invocation.
 *
 * The tree on which the mapping should operate is provided for mappings that depend on the tree
 * (e.g. to optimize the mapping).
 */
- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree;

/* Creates file item mapping instance that depends on tree drawer settings.
 *
 * This needs to be used instead of fileItemMappingForTree: when dependsOnTreeDrawerSettings
 * returns YES.
 */
- (FileItemMapping *)fileItemMappingForTree:(DirectoryItem *)tree
                                   settings:(TreeDrawerBaseSettings *)settings;

@end
