#import <Quartz/Quartz.h>

#import "DirectoryView.h"

#import "DirectoryViewControl.h"

#import "DirectoryItem.h"
#import "TreeContext.h"

#import "TreeLayoutBuilder.h"
#import "TreeDrawer.h"
#import "TreeDrawerSettings.h"
#import "ItemPathDrawer.h"
#import "ItemPathModel.h"
#import "ItemPathModelView.h"
#import "ItemLocator.h"

#import "OverlayDrawer.h"

#import "TreeLayoutTraverser.h"

#import "AsynchronousTaskManager.h"
#import "DrawTaskExecutor.h"
#import "DrawTaskInput.h"
#import "OverlayDrawTaskExecutor.h"
#import "OverlayDrawTaskInput.h"

#import "FileItemMapping.h"
#import "FileItemMappingScheme.h"

#import "LocalizableStrings.h"

#define SCROLL_WHEEL_SENSITIVITY  6.0


#define ZOOM_ANIMATION_SKIP_THRESHOLD  0.99
#define ZOOM_ANIMATION_MAXLEN_THRESHOLD  0.80

NSString  *ColorPaletteChangedEvent = @"colorPaletteChanged";
NSString  *ColorMappingChangedEvent = @"colorMappingChanged";

CGFloat rectArea(NSRect rect) {
  return rect.size.width * rect.size.height;
}

// Returns 0 when x <= minX, 1 when x >= maxX, and interpolates lineairly when minX < x < maxX.
CGFloat ramp(CGFloat x, CGFloat minX, CGFloat maxX) {
  return MIN(1, MAX(0, x - minX) / (maxX - minX));
}

@interface DirectoryView (PrivateMethods)

- (BOOL) validateAction:(SEL)action;

- (void) forceRedraw;
- (void) forceOverlayRedraw;

- (void) startTreeDrawTask;
- (void) itemTreeImageReady:(id)image;

- (void) startOverlayDrawTask;
- (void) overlayImageReady:(id)image;

@property (nonatomic, readonly) float animatedOverlayStrength;
- (void) refreshDisplay;
- (void) enablePeriodicRedraw:(BOOL) enable;

- (void) startZoomAnimation;
- (void) drawZoomAnimation;
- (void) releaseZoomImages;
- (void) abortZoomAnimation;
- (void) addZoomAnimationCompletionHandler;
- (void) drawScaledImages;

- (void) postColorPaletteChanged;
- (void) postColorMappingChanged;

- (void) selectedItemChanged:(NSNotification *)notification;
- (void) visibleTreeChanged:(NSNotification *)notification;
- (void) visiblePathLockingChanged:(NSNotification *)notification;
- (void) windowMainStatusChanged:(NSNotification *)notification;
- (void) windowKeyStatusChanged:(NSNotification *)notification;

- (void) updateAcceptMouseMovedEvents;

- (void) observeColorMapping;
- (void) colorMappingChanged:(NSNotification *)notification;

- (void) updateSelectedItem:(NSPoint)point;
- (void) moveSelectedItem:(DirectionEnum)direction;

@end 


@implementation DirectoryView

- (instancetype) initWithFrame:(NSRect)frame {
  if (self = [super initWithFrame:frame]) {
    layoutBuilder = [[TreeLayoutBuilder alloc] init];
    pathDrawer = [[ItemPathDrawer alloc] init];
    selectedItemLocator = [[ItemLocator alloc] init];

    scrollWheelDelta = 0;
  }

  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  
  [drawTaskManager dispose];
  [drawTaskManager release];

  [overlayDrawTaskManager dispose];
  [overlayDrawTaskManager release];

  [redrawTimer invalidate];

  [layoutBuilder release];
  [overlayTest release];
  [pathDrawer release];
  [selectedItemLocator release];
  
  [observedColorMapping release];
  
  [pathModelView release];
  
  [treeImage release];
  [zoomImage release];
  [zoomBackgroundImage release];
  [overlayImage release];
  
  [super dealloc];
}


- (void) postInitWithPathModelView:(ItemPathModelView *)pathModelViewVal {
  NSAssert(pathModelView == nil, @"The path model view should only be set once.");

  pathModelView = [pathModelViewVal retain];
  TreeContext *treeContext = pathModelView.pathModel.treeContext;
  
  DrawTaskExecutor  *drawTaskExecutor =
    [[[DrawTaskExecutor alloc] initWithTreeContext: treeContext] autorelease];
  drawTaskManager = [[AsynchronousTaskManager alloc] initWithTaskExecutor: drawTaskExecutor];

  OverlayDrawTaskExecutor  *overlayDrawTaskExecutor =
    [[[OverlayDrawTaskExecutor alloc] initWithScanTree: treeContext.scanTree] autorelease];
  overlayDrawTaskManager =
    [[AsynchronousTaskManager alloc] initWithTaskExecutor: overlayDrawTaskExecutor];

  [self observeColorMapping];
  
  NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];

  [nc addObserver: self
         selector: @selector(selectedItemChanged:)
             name: SelectedItemChangedEvent
           object: pathModelView];
  [nc addObserver: self
         selector: @selector(visibleTreeChanged:)
             name: VisibleTreeChangedEvent
           object: pathModelView];
  [nc addObserver: self
         selector: @selector(visiblePathLockingChanged:)
             name: VisiblePathLockingChangedEvent
           object: pathModelView.pathModel];

  [nc addObserver: self
         selector: @selector(windowMainStatusChanged:)
             name: NSWindowDidBecomeMainNotification
           object: self.window];
  [nc addObserver: self
         selector: @selector(windowMainStatusChanged:)
             name: NSWindowDidResignMainNotification
           object: self.window];
  [nc addObserver: self
         selector: @selector(windowKeyStatusChanged:)
             name: NSWindowDidBecomeKeyNotification
           object: self.window];
  [nc addObserver: self
         selector: @selector(windowKeyStatusChanged:)
             name: NSWindowDidResignKeyNotification
           object: self.window];
          
  [self visiblePathLockingChanged: nil];
  [self setNeedsDisplay: YES];
}


- (ItemPathModelView *)pathModelView {
  return pathModelView;
}

- (FileItem *)treeInView {
  return showEntireVolume ? pathModelView.volumeTree : pathModelView.visibleTree;
}

- (NSRect) locationInViewForItem:(FileItem *)item onPath:(NSArray *)itemPath {
  return [selectedItemLocator locationForItem: item
                                       onPath: itemPath
                               startingAtTree: self.treeInView
                           usingLayoutBuilder: layoutBuilder
                                       bounds: self.bounds];
}

- (NSImage *)imageInViewForItem:(FileItem *)item onPath:(NSArray *)itemPath {
  NSRect sourceRect = [self locationInViewForItem: item onPath: itemPath];
  CGFloat x = ceil(sourceRect.origin.x);
  CGFloat y = ceil(sourceRect.origin.y);
  CGFloat w = floor(sourceRect.origin.x + sourceRect.size.width) - x;
  CGFloat h = floor(sourceRect.origin.y + sourceRect.size.height) - y;

  NSImage  *targetImage = [[[NSImage alloc] initWithSize: NSMakeSize(w, h)] autorelease];

  [targetImage lockFocus];
  [treeImage drawInRect: NSMakeRect(0, 0, w, h)
               fromRect: NSMakeRect(x, y, w, h)
              operation: NSCompositeCopy
               fraction: 1.0];
  [targetImage unlockFocus];

  return targetImage;
}

- (NSRect) locationInViewForItemAtEndOfPath:(NSArray *)itemPath {
  return [self locationInViewForItem: itemPath.lastObject onPath: itemPath];
}

- (NSImage *)imageInViewForItemAtEndOfPath:(NSArray *)itemPath {
  return [self imageInViewForItem: itemPath.lastObject onPath: itemPath];
}


- (TreeDrawerSettings *)treeDrawerSettings {
  DrawTaskExecutor  *drawTaskExecutor = (DrawTaskExecutor*)drawTaskManager.taskExecutor;

  return drawTaskExecutor.treeDrawerSettings;
}

- (void) setTreeDrawerSettings:(TreeDrawerSettings *)settings {
  DrawTaskExecutor  *drawTaskExecutor = (DrawTaskExecutor*)drawTaskManager.taskExecutor;

  TreeDrawerSettings  *oldSettings = drawTaskExecutor.treeDrawerSettings;
  if (settings != oldSettings) {
    [oldSettings retain];

    [drawTaskExecutor setTreeDrawerSettings: settings];
    
    if (settings.colorPalette != oldSettings.colorPalette) {
      [self postColorPaletteChanged]; 
    }
    
    if (settings.colorMapper != oldSettings.colorMapper) {
      [self postColorMappingChanged]; 

      // Observe the color mapping (for possible changes to its hashing
      // implementation)
      [self observeColorMapping];
    }
    
    if (settings.showPackageContents != oldSettings.showPackageContents) {
      pathModelView.showPackageContents = settings.showPackageContents;
    }

    [oldSettings release];

    [self forceRedraw];
  }
}


- (FileItemTest *)overlayTest {
  return overlayTest;
}

- (void)setOverlayTest:(FileItemTest *)overlayTestVal {
  if (overlayTestVal != overlayTest) {
    [overlayTest release];
    overlayTest = [overlayTestVal retain];

    [self forceOverlayRedraw];
  }
}


- (NSRect) zoomBounds {
  return zoomBounds;
}

- (void) setZoomBounds:(NSRect)bounds {
  zoomBounds = bounds;
  [self setNeedsLayout: YES];
}


- (BOOL) showEntireVolume {
  return showEntireVolume;
}

- (void) setShowEntireVolume:(BOOL)flag {
  if (flag != showEntireVolume) {
    showEntireVolume = flag;
    [self forceRedraw];
  }
}


- (TreeLayoutBuilder *)layoutBuilder {
  return layoutBuilder;
}


- (BOOL) canZoomIn {
  return (pathModelView.pathModel.isVisiblePathLocked &&
          pathModelView.canMoveVisibleTreeDown);
}

- (BOOL) canZoomOut {
  return pathModelView.canMoveVisibleTreeUp;
}


- (void) zoomIn {
  // Initiate zoom animation
  ItemPathModel  *pathModel = pathModelView.pathModel;

  NSLog(@"starting zoom-in animation");

  // If an animation is ongoing, abort it so it won't interfere
  [self abortZoomAnimation];

  zoomImage = [[self imageInViewForItem: pathModel.itemBelowVisibleTree
                                 onPath: pathModel.itemPath] retain];
  zoomBackgroundImage = [treeImage retain];
  zoomBoundsStart = [self locationInViewForItem: pathModel.itemBelowVisibleTree
                                         onPath: pathModel.itemPath];
  zoomBounds = zoomBoundsStart;
  zoomBoundsEnd = self.bounds;
  zoomingIn = YES;

  [self startZoomAnimation];

  [pathModelView moveVisibleTreeDown];
}

- (void) zoomOut {
  // Initiate zoom animation
  ItemPathModel  *pathModel = pathModelView.pathModel;

  // If an animation is ongoing, abort it so it won't interfere
  [self abortZoomAnimation];

  zoomImage = [treeImage retain];
  // The background image is not yet known. It will be set when the zoomed out image is drawn.
  NSAssert(zoomBackgroundImage == nil, @"zoomBackgroundImage should be nil");
  zoomBoundsStart = self.bounds;
  zoomBounds = zoomBoundsStart;
  zoomingIn = NO;

  [pathModelView moveVisibleTreeUp];

  zoomBoundsEnd = [self locationInViewForItem: pathModel.itemBelowVisibleTree
                                       onPath: pathModel.itemPath];
  [self startZoomAnimation];

  // Automatically lock path as well.
  [pathModelView.pathModel setVisiblePathLocking: YES];
}


- (BOOL) canMoveFocusUp {
  return pathModelView.canMoveSelectionUp;
}

- (BOOL) canMoveFocusDown {
  return !pathModelView.selectionSticksToEndPoint;
}


- (void) moveFocusUp {
  [pathModelView moveSelectionUp]; 
}

- (void) moveFocusDown {
  if (pathModelView.canMoveSelectionDown) {
    [pathModelView moveSelectionDown];
  }
  else {
    [pathModelView setSelectionSticksToEndPoint: YES];
  }
}


- (void) drawRect:(NSRect)rect {
  [self drawScaledImages];
  return;

  if (pathModelView == nil) {
    return;
  }

  if (treeImage != nil && !NSEqualSizes(treeImage.size, self.bounds.size)) {
    // Handle resizing of the view

    // Scale the existing image(s) for the new size. They will be used until redrawn images are
    // available.
    treeImageIsScaled = YES;
    overlayImageIsScaled = YES;

    // Abort any ongoing drawing tasks
    isTreeDrawInProgress = NO;
    isOverlayDrawInProgress = NO;
  }

  // Initiate background draw tasks if needed
  if ((treeImage == nil || treeImageIsScaled) && !isTreeDrawInProgress) {
    [self startTreeDrawTask];
  } else if ((overlayImage == nil || overlayImageIsScaled) &&
             overlayTest != nil && !isOverlayDrawInProgress) {
    [self startOverlayDrawTask];
  }

  if (zoomImage != nil) {
    [self drawZoomAnimation];
  } else if (treeImage != nil) {
    [treeImage drawInRect: self.bounds
                 fromRect: NSZeroRect
                operation: NSCompositeCopy
                 fraction: 1.0f];

    if (overlayImage != nil) {
      [overlayImage drawInRect: self.bounds
                      fromRect: NSZeroRect
                     operation: NSCompositingOperationColorDodge
                      fraction: self.animatedOverlayStrength];
    }

    if (!treeImageIsScaled) {
      if ([pathModelView isSelectedFileItemVisible]) {
        [pathDrawer drawVisiblePath: pathModelView
                     startingAtTree: self.treeInView
                 usingLayoutBuilder: layoutBuilder
                             bounds: self.bounds];
      }
    }
  }
}


- (BOOL) isOpaque {
  return YES;
}

- (BOOL) acceptsFirstResponder {
  return YES;
}

- (BOOL) becomeFirstResponder {
  return YES;
}

- (BOOL) resignFirstResponder {
  return YES;
}


- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
  int  flags = theEvent.modifierFlags & NSDeviceIndependentModifierFlagsMask;
  NSString  *chars = theEvent.characters;
  unichar const  code = [chars characterAtIndex: 0];
  
  if ([chars isEqualToString: @"]"]) {
    if (flags == NSCommandKeyMask) {
      if ([self canMoveFocusDown]) {
        [self moveFocusDown];
      }
      return YES;
    }
  }
  else if ([chars isEqualToString: @"["]) {
    if (flags == NSCommandKeyMask) {
      if ([self canMoveFocusUp]) {
        [self moveFocusUp];
      }
      return YES;
    }
  }
  else if ([chars isEqualToString: @"="]) {
    // Accepting this with or without the Shift key-pressed, as having to use 
    // the Shift key is a bit of a pain.
    if ((flags | NSShiftKeyMask) == (NSCommandKeyMask | NSShiftKeyMask)) {
      if ([self canZoomIn]) {
        [self zoomIn];
      }
      return YES;
    }
  }
  else if ([chars isEqualToString: @"-"]) {
    if (flags == NSCommandKeyMask) {
      if ([self canZoomOut]) {
        [self zoomOut];
      }
      return YES;
    }
  }
  else if ([chars isEqualToString: @" "]) {
    if (flags == 0) {
      SEL  action = @selector(previewFile:);
      if ([self validateAction: action]) {
        DirectoryViewControl*  target = (DirectoryViewControl*)
          [[NSApplication sharedApplication] targetForAction: action];
        [target previewFile: self];
      }
      return YES;
    }
  }
  else if (pathModelView.pathModel.isVisiblePathLocked) {
    // Navigation via arrow keys is active when the path is locked (so that mouse movement does not
    // interfere).
    BOOL handled = YES;
    switch (code) {
      case NSUpArrowFunctionKey: [self moveSelectedItem: DirectionUp]; break;
      case NSDownArrowFunctionKey: [self moveSelectedItem: DirectionDown]; break;
      case NSRightArrowFunctionKey: [self moveSelectedItem: DirectionRight]; break;
      case NSLeftArrowFunctionKey: [self moveSelectedItem: DirectionLeft]; break;
      default: handled = NO;
    }
    if (handled) {
      return YES;
    }
  }

  return NO;
}


- (void) scrollWheel: (NSEvent *)theEvent {
  scrollWheelDelta += theEvent.deltaY;
  
  if (scrollWheelDelta > 0) {
    if (! [self canMoveFocusDown]) {
      // Keep it at zero, to make moving up not unnecessarily cumbersome.
      scrollWheelDelta = 0;
    }
    else if (scrollWheelDelta > SCROLL_WHEEL_SENSITIVITY + 0.5f) {
      [self moveFocusDown];

      // Make it easy to move up down again.
      scrollWheelDelta = - SCROLL_WHEEL_SENSITIVITY;
    }
  }
  else {
    if (! [self canMoveFocusUp]) {
      // Keep it at zero, to make moving up not unnecessarily cumbersome.
      scrollWheelDelta = 0;
    }
    else if (scrollWheelDelta < - (SCROLL_WHEEL_SENSITIVITY + 0.5f)) {
      [self moveFocusUp];

      // Make it easy to move back down again.
      scrollWheelDelta = SCROLL_WHEEL_SENSITIVITY;
    }
  }
}


- (void) mouseDown:(NSEvent *)theEvent {
  ItemPathModel  *pathModel = pathModelView.pathModel;

  if (self.window.acceptsMouseMovedEvents && pathModel.lastFileItem == pathModel.visibleTree) {
    // Although the visible path is following the mouse, the visible path is empty. This can either
    // mean that the view only shows a single file item or, more likely, the view did not yet
    // receive the mouse moved events that are required to update the visible path because it was
    // not yet the first responder.
    
    // Force building (and drawing) of the visible path.
    [self mouseMoved: theEvent];
    
    if (pathModel.lastFileItem != pathModel.visibleTree) {
      // The path changed. Do not toggle the locking. This mouse click was used to make the view the
      // first responder, ensuring that the visible path is following the mouse pointer.
      return;
    }
  }

  // Toggle the path locking.

  BOOL  wasLocked = pathModel.isVisiblePathLocked;
  if (wasLocked) {
    // Unlock first, then build new path.
    [pathModel setVisiblePathLocking: NO];
  }

  NSPoint  loc = theEvent.locationInWindow;
  [self updateSelectedItem: [self convertPoint: loc fromView: nil]];

  if (!wasLocked) {
    // Now lock, after having updated path.

    if (pathModelView.isSelectedFileItemVisible) {
      // Only lock the path if it contains the selected item, i.e. if the mouse click was inside the
      // visible tree.
      [pathModel setVisiblePathLocking: YES];
    }
  }
}


- (void) mouseMoved:(NSEvent *)theEvent {
  if (pathModelView.pathModel.isVisiblePathLocked) {
    // Ignore mouseMoved events when the item path is locked.
    //
    // Note: Although this view stops accepting mouse moved events when the path becomes locked,
    // these may be generated later on anyway, requested by other components.
    return;
  }
  
  if (! (self.window.mainWindow && self.window.keyWindow)) {
    // Only handle mouseMoved events when the window is main and key. 
    return;
  }
  
  NSPoint  loc = self.window.mouseLocationOutsideOfEventStream;
  // Note: not using the location returned by [theEvent locationInWindow] as this is not fully
  // accurate.

  NSPoint  mouseLoc = [self convertPoint: loc fromView: nil];
  BOOL isInside = [self mouse: mouseLoc inRect: self.bounds];

  if (isInside) {
    [self updateSelectedItem: mouseLoc];
  }
  else {
    [pathModelView.pathModel clearVisiblePath];
  }
}


- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
  NSMenu  *popUpMenu = [[[NSMenu alloc] initWithTitle: LocalizationNotNeeded(@"Contextual Menu")]
                        autorelease];
  int  itemCount = 0;


  if ( [self validateAction: @selector(revealFileInFinder:)] ) {
    [popUpMenu insertItemWithTitle: 
                 NSLocalizedStringFromTable( @"Reveal in Finder", @"PopUpMenu", @"Menu item" )
                            action: @selector(revealFileInFinder:) 
                     keyEquivalent: @""
                           atIndex: itemCount++];
  }

  if ( [self validateAction: @selector(previewFile:)] ) {
    NSMenuItem  *menuItem = [[[NSMenuItem alloc] initWithTitle:
                            NSLocalizedStringFromTable( @"Quick Look", @"PopUpMenu", @"Menu item" )
                                                        action: @selector(previewFile:)
                                                 keyEquivalent: @" "]
                             autorelease];
    menuItem.keyEquivalentModifierMask = 0; // No modifiers
    [popUpMenu insertItem: menuItem atIndex: itemCount++];
  }
  
  if ( [self validateAction: @selector(openFile:)] ) {
    [popUpMenu insertItemWithTitle: 
     NSLocalizedStringFromTable( @"Open with Finder", @"PopUpMenu", @"Menu item" )
                            action: @selector(openFile:) 
                     keyEquivalent: @"" 
                           atIndex: itemCount++];
  }
  
  if ( [self validateAction: @selector(copy:)] ) {
    [popUpMenu insertItemWithTitle:
     NSLocalizedStringFromTable(@"Copy path", @"PopUpMenu", @"Menu item" )
                            action: @selector(copy:) 
                     keyEquivalent: @"c"
                           atIndex: itemCount++];
  }
  
  if ( [self validateAction: @selector(deleteFile:)] ) {
    [popUpMenu insertItemWithTitle: 
     NSLocalizedStringFromTable( @"Delete file", @"PopUpMenu", @"Menu item" )
                            action: @selector(deleteFile:) 
                     keyEquivalent: @""
                           atIndex: itemCount++];
  }
  
  return (itemCount > 0) ? popUpMenu : nil;
}

+ (id)defaultAnimationForKey:(NSString *)key {
  if ([key isEqualToString: @"zoomBounds"]) {
    return [CABasicAnimation animation];
  }

  return [super defaultAnimationForKey: key];
}

@end // @implementation DirectoryView


@implementation DirectoryView (PrivateMethods)

/* Checks with the target that will execute the action if it should be enabled. It assumes that the
 * target has implemented validateAction:, which is the case when the target is
 * DirectoryViewControl.
 */
- (BOOL) validateAction:(SEL)action {
  DirectoryViewControl*  target =
    (DirectoryViewControl *)[[NSApplication sharedApplication] targetForAction: action];
  return [target validateAction: action];
}

- (void) forceRedraw {
  NSLog(@"Forcing redraw");
  [self setNeedsDisplay: YES];

  // Discard the existing image
  [treeImage release];
  treeImage = nil;

  // Invalidate any ongoing draw task
  isTreeDrawInProgress = NO;

  [self forceOverlayRedraw];
}

- (void) forceOverlayRedraw {
  //NSLog(@"Forcing overlay redraw");
  [self setNeedsDisplay: YES];

  [overlayImage release];
  overlayImage = nil;

  isOverlayDrawInProgress = NO;
}

- (void) startTreeDrawTask {
  //NSLog(@"Starting draw task");
  NSAssert(self.bounds.origin.x == 0 && self.bounds.origin.y == 0, @"Bounds not at (0, 0)");

  // Create image in background thread.
  DrawTaskInput  *drawInput =
    [[DrawTaskInput alloc] initWithVisibleTree: pathModelView.visibleTree
                                    treeInView: self.treeInView
                                 layoutBuilder: layoutBuilder
                                        bounds: self.bounds];
  [drawTaskManager asynchronouslyRunTaskWithInput: drawInput
                                         callback: self
                                         selector: @selector(itemTreeImageReady:)];

  isTreeDrawInProgress = YES;
  [drawInput release];
}

/* Callback method that signals that the drawing task has finished execution. It is also called when
 * the drawing has been aborted, in which the image will be nil.
 */
- (void) itemTreeImageReady: (id) image {
  if (image == nil) {
    // Only take action when the drawing task has completed succesfully.
    //
    // Without this check, a race condition can occur. When a new drawing task aborts the execution
    // of an ongoing task, the completion of the latter and subsequent invocation of -drawRect:
    // results in the abortion of the new task (as long as it has not yet completed).

    return;
  }
  NSLog(@"itemTreeImageReady");

  // Note: This method is called from the main thread (even though it has been triggered by the
  // drawer's background thread). So calling setNeedsDisplay directly is okay.
  [treeImage release];
  treeImage = [image retain];
  treeImageIsScaled = NO;
  isTreeDrawInProgress = NO;
  NSLog(@"treeImage = %@", NSStringFromSize(treeImage.size));

  if (zoomImage != nil) {
    // Replace initial zoom image so the layout matches the new aspect ratio.
    [zoomImage release];

    if (zoomingIn) {
      zoomImage = [treeImage retain];
    } else {
      ItemPathModel  *pathModel = pathModelView.pathModel;
      zoomImage = [[self imageInViewForItem: pathModel.itemBelowVisibleTree
                                     onPath: pathModel.itemPath] retain];
      NSAssert(zoomBackgroundImage == nil, @"zoomBackgroundImage should be nil");
      zoomBackgroundImage = [treeImage retain];
    }
  }

  [self setNeedsDisplay: YES];
}

- (void) startOverlayDrawTask {
  //NSLog(@"Starting overlay draw task");
  NSAssert(self.bounds.origin.x == 0 && self.bounds.origin.y == 0, @"Bounds not at (0, 0)");

  // Create image in background thread.
  OverlayDrawTaskInput  *overlayDrawInput =
      [[OverlayDrawTaskInput alloc] initWithVisibleTree: pathModelView.visibleTree
                                             treeInView: self.treeInView
                                          layoutBuilder: layoutBuilder
                                                 bounds: self.bounds
                                            overlayTest: overlayTest];
  [overlayDrawTaskManager asynchronouslyRunTaskWithInput: overlayDrawInput
                                                callback: self
                                                selector: @selector(overlayImageReady:)];

  isOverlayDrawInProgress = YES;
  [overlayDrawInput release];
}

- (void) overlayImageReady:(id)image {
  if (image != nil) {
    //NSLog(@"Completed overlay draw task");

    [overlayImage release];
    overlayImage = [image retain];
    overlayImageIsScaled = NO;
    isOverlayDrawInProgress = NO;

    [self setNeedsDisplay: YES];
  }
}

- (float) animatedOverlayStrength {
  return (self.window.mainWindow
          ? 0.7 + 0.3 * sin([NSDate date].timeIntervalSinceReferenceDate * 3.1415)
          : 0.7);
}

- (void) refreshDisplay {
  [self setNeedsDisplay: YES];
}

- (void) enablePeriodicRedraw:(BOOL) enable {
  if (enable) {
    if (redrawTimer == nil) {
      redrawTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1f
                                                     target: self
                                                   selector: @selector(refreshDisplay)
                                                   userInfo: nil
                                                    repeats: YES];
      redrawTimer.tolerance = 0.04f;
    }
  } else {
    if (redrawTimer != nil) {
      [redrawTimer invalidate];
      redrawTimer = nil;
    }
  }
}

- (void) startZoomAnimation {
  CGFloat  areaStart = rectArea(zoomBoundsStart);
  CGFloat  areaEnd = rectArea(zoomBoundsEnd);
  CGFloat  areaMin = MIN(areaStart, areaEnd);
  CGFloat  areaMax = MAX(areaStart, areaEnd);

  CGFloat  fraction = areaMin / areaMax;
  CGFloat  durationMultiplier = ramp(1 - fraction,
                                     1 - ZOOM_ANIMATION_SKIP_THRESHOLD,
                                     1 - ZOOM_ANIMATION_MAXLEN_THRESHOLD);

  if (durationMultiplier > 0) {
    [treeImage release];
    treeImage = nil;

    [NSAnimationContext beginGrouping];

    [NSAnimationContext.currentContext setDuration: 20 * durationMultiplier];
    [self addZoomAnimationCompletionHandler];
    self.animator.zoomBounds = zoomBoundsEnd;

    [NSAnimationContext endGrouping];
  } else {
    NSLog(@"Skipping zoom animation");
    [self releaseZoomImages];
  }
}

- (NSImage *)createTestImageFromColor {
  NSSize  size = NSMakeSize(640, 640);
  NSImage *image = [[[NSImage alloc] initWithSize: size] autorelease];
  [image lockFocus];
  [NSColor.blueColor drawSwatchInRect: NSMakeRect(0, 0, size.width, size.height)];
  [NSColor.whiteColor drawSwatchInRect: NSMakeRect(10, 10, size.width - 20, size.height - 20)];
  [image unlockFocus];
  return image;
}

- (NSImage *)createTestImageFromBitmap {
  int  w = 640, h = 640;
  NSBitmapImageRep  *bitmap;
  bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                   pixelsWide: w
                                                   pixelsHigh: h
                                                bitsPerSample: 8
                                              samplesPerPixel: 3
                                                     hasAlpha: NO
                                                     isPlanar: NO
                                               colorSpaceName: NSDeviceRGBColorSpace
                                                  bytesPerRow: 0
                                                 bitsPerPixel: 32];

  int  bitmapWidth = (int)bitmap.bytesPerRow / sizeof(UInt32);
  for (int y = 0; y < h; ++y) {
      UInt32  *pos = (UInt32 *)bitmap.bitmapData + y * bitmapWidth;
      for (int x = 0; x < w; ++x) {
          *pos++ = 0xFF;
      }
  }

  NSImage  *image = [[NSImage alloc] initWithSize: NSMakeSize(w, h)];
  [image addRepresentation: bitmap];
  [bitmap release];

  return [image autorelease];
}

- (void) drawScaledImages {
  if (testImage == nil) {
    testImage = [[self createTestImageFromColor] retain];
  }
  if (testImage2 == nil) {
    testImage2 = [[self createTestImageFromBitmap] retain];
  }
  [NSColor.whiteColor setFill];
  NSRectFill(self.bounds);

  [testImage drawInRect: NSMakeRect(50, 50, 320, 320)
               fromRect: NSZeroRect
              operation: NSCompositeCopy
               fraction: 1.0];

  [testImage2 drawInRect: NSMakeRect(50, 100, 320, 320)
                fromRect: NSZeroRect
               operation: NSCompositeCopy
                fraction: 1.0];

  [testImage drawInRect: NSMakeRect(450, 50, 480, 480)
               fromRect: NSZeroRect
              operation: NSCompositeCopy
               fraction: 1.0];
  [testImage2 drawInRect: NSMakeRect(450, 100, 480, 480)
                fromRect: NSZeroRect
               operation: NSCompositeCopy
                fraction: 1.0];
}

- (void) drawZoomAnimation {
  NSRect *zoomP = zoomingIn ? &zoomBoundsStart : &zoomBoundsEnd;
  NSRect *fullP = zoomingIn ? &zoomBoundsEnd : &zoomBoundsStart;

  NSLog(@"draw zoomBounds = %@ %@ %@", NSStringFromRect(*zoomP), NSStringFromRect(*fullP),
        NSStringFromSize(zoomImage.size));

  if (zoomBackgroundImage != nil) {
    CGFloat scaleX = zoomBounds.size.width / zoomP->size.width;
    CGFloat scaleY = zoomBounds.size.height / zoomP->size.height;
    CGFloat x = zoomP->origin.x - zoomBounds.origin.x / scaleX;
    CGFloat y = zoomP->origin.y - zoomBounds.origin.y / scaleY;
    [zoomBackgroundImage drawInRect: *fullP
                           fromRect: NSMakeRect(x, y,
                                                fullP->size.width / scaleX,
                                                fullP->size.height / scaleY)
                           operation: NSCompositeCopy
                           fraction: 0.5];
  }

  [zoomImage drawInRect: zoomBounds
               fromRect: NSZeroRect
              operation: NSCompositeCopy
               fraction: 1.0];
}

- (void) releaseZoomImages {
  [zoomImage release];
  zoomImage = nil;
  [zoomBackgroundImage release];
  zoomBackgroundImage = nil;
  NSLog(@"released zoom images");
}

- (void) abortZoomAnimation {
  if (zoomImage == nil) {
    return;
  }
  [self releaseZoomImages];

  [NSAnimationContext beginGrouping];
  [NSAnimationContext.currentContext setDuration: 0];
  self.animator.zoomBounds = NSZeroRect;
  [NSAnimationContext endGrouping];
}

- (void) addZoomAnimationCompletionHandler {
  NSInteger  myCount = ++zoomAnimationCount;

  [NSAnimationContext.currentContext setCompletionHandler: ^{
    NSLog(@"zoom animation completed");
    if (zoomAnimationCount == myCount) {
      // Only clear the images when they belong to my animation. They should not be cleared when a
      // zoom request triggered a new animation thereby aborting the previous animation.
      [self releaseZoomImages];
    }
  }];
}

- (void) postColorPaletteChanged {
  [[NSNotificationCenter defaultCenter] postNotificationName: ColorPaletteChangedEvent
                                                      object: self];
}

- (void) postColorMappingChanged {
  [[NSNotificationCenter defaultCenter] postNotificationName: ColorMappingChangedEvent
                                                      object: self];
}


/* Called when selection changes in path
 */
- (void) selectedItemChanged:(NSNotification *)notification {
  [self setNeedsDisplay: YES];
}

- (void) visibleTreeChanged:(NSNotification *)notification {
  [self forceRedraw];
}

- (void) visiblePathLockingChanged:(NSNotification *)notification {
  // Update the item path drawer directly. Although the drawer could also listen to the
  // notification, it seems better to do it like this. It keeps the item path drawer more general,
  // and as the item path drawer is tightly integrated with this view, there is no harm in updating
  // it directly.
  [pathDrawer setHighlightPathEndPoint: pathModelView.pathModel.isVisiblePathLocked];
 
  [self updateAcceptMouseMovedEvents];
  
  [self setNeedsDisplay: YES];
}

- (void) windowMainStatusChanged:(NSNotification *)notification {
  [self updateAcceptMouseMovedEvents];

  // Only when the window is the main one enable periodic redraw. This takes care of the overlay
  // animation as well as the selected item highlight animation.
  [self enablePeriodicRedraw: self.window.mainWindow];
}

- (void) windowKeyStatusChanged:(NSNotification *)notification {
  [self updateAcceptMouseMovedEvents];
}

- (void) updateAcceptMouseMovedEvents {
  BOOL  letPathFollowMouse = !pathModelView.pathModel.isVisiblePathLocked
                              && self.window.mainWindow
                              && self.window.keyWindow;

  self.window.acceptsMouseMovedEvents = letPathFollowMouse;

  if (letPathFollowMouse) {
    // Ensures that the view also receives the mouse moved events.
    [self.window makeFirstResponder: self];
  }
}


- (void) observeColorMapping {
  TreeDrawerSettings  *treeDrawerSettings = [self treeDrawerSettings];
  NSObject <FileItemMappingScheme>  *colorMapping = 
    treeDrawerSettings.colorMapper.fileItemMappingScheme;
    
  if (colorMapping != observedColorMapping) {
    NSNotificationCenter  *nc = [NSNotificationCenter defaultCenter];
    
    if (observedColorMapping != nil) {
      [nc removeObserver: self
                    name: MappingSchemeChangedEvent
                  object: observedColorMapping];
      [observedColorMapping release];
    }

    [nc addObserver: self
           selector: @selector(colorMappingChanged:)
               name: MappingSchemeChangedEvent
             object: colorMapping];
    observedColorMapping = [colorMapping retain];
  }
}

- (void) colorMappingChanged:(NSNotification *) notification {
  // Replace the mapper that is used by a new one (still from the same scheme)
  NSObject <FileItemMapping>  *newMapping =
    [observedColorMapping fileItemMappingForTree: pathModelView.scanTree];

  [self setTreeDrawerSettings: [self.treeDrawerSettings settingsWithChangedColorMapper: newMapping]];

  [self postColorMappingChanged]; 
}


- (void) updateSelectedItem: (NSPoint) point {
  [pathModelView selectItemAtPoint: point 
                    startingAtTree: self.treeInView
                usingLayoutBuilder: layoutBuilder
                            bounds: self.bounds];
  // Redrawing in response to any changes will happen when the change notification is received.
}

- (void) moveSelectedItem: (DirectionEnum) direction {
  [pathModelView moveSelectedItem: direction
                  startingAtTree: self.treeInView
              usingLayoutBuilder: layoutBuilder
                          bounds: self.bounds];
}

@end // @implementation DirectoryView (PrivateMethods)
