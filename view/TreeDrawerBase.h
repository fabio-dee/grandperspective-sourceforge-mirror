#import <Foundation/Foundation.h>

#import "TreeLayoutTraverser.h"

NS_ASSUME_NONNULL_BEGIN

@class DirectoryItem;
@class FileItem;
@class PlainFileItem;
@class FilteredTreeGuide;
@class GradientRectangleDrawer;
@class TreeLayoutBuilder;
@class TreeDrawerBaseSettings;

@interface TreeDrawerBase : NSObject <TreeLayoutTraverser> {
  GradientRectangleDrawer  *rectangleDrawer;
  FilteredTreeGuide  *treeGuide;

  DirectoryItem  *scanTree;

  // All variables below are temporary variables used while building the path. They are not
  // retained, as they are only used during a single recursive invocation.

  FileItem  *visibleTree;
  DirectoryItem  *groupFilesDir;
  Item  *nextFilesToGroup;
  BOOL  insideVisibleTree;

  BOOL  abort;
}

// Overrides designated initialiser
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree;

- (instancetype) initWithScanTree:(DirectoryItem *)scanTree
                     colorPalette:(nullable NSColorList *)colorPalette NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) TreeDrawerBaseSettings *treeDrawerSettings;

@property (nonatomic) unsigned displayDepth;
@property (nonatomic) BOOL showPackageContents;

// Indicates if all files inside a directory should be drawn as a single item.
@property (nonatomic) BOOL groupFiles;

// Updates the drawer according to the given settings.
- (void) updateSettings:(TreeDrawerBaseSettings *)settings;

/* Draws the visible tree. Drawing typically also starts there, but can start at the volume tree
 * root when the entire volume is drawn.
 *
 * Note: The tree starting at "treeRoot" should be immutable.
 *
 * Returns nil when the drawing was aborted.
 */
- (nullable NSImage *)drawImageOfVisibleTree:(FileItem *)visibleTree
                              startingAtTree:(FileItem *)treeRoot
                          usingLayoutBuilder:(TreeLayoutBuilder *)layoutBuilder
                                      inRect:(NSRect)bounds;

/* Any outstanding request to abort Drawing is cancelled.
 */
- (void) clearAbortFlag;

/* Cancels any ongoing drawing task. Note: It is possible that the ongoing task is just finishing,
 * in which case it may still finish normally. Therefore, -clearAbortFlag should be invoked before
 * initiating a new drawing task, otherwise the next drawing task will be aborted immediately.
 */
- (void) abortDrawing;

@end

@interface TreeDrawerBase (ProtectedMethods)

- (void) drawVisibleTreeAtRect:(NSRect) rect;
- (void) drawUsedSpaceAtRect:(NSRect) rect;
- (void) drawFreeSpaceAtRect:(NSRect) rect;
- (void) drawFreedSpaceAtRect:(NSRect) rect;
- (void) drawFileItem:(FileItem *)fileItem atRect:(NSRect) rect depth:(int) depth;

@end

NS_ASSUME_NONNULL_END
