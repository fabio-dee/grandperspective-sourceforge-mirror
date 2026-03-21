#import <Cocoa/Cocoa.h>

#import "MainMenuControl.h"

@interface StartWindowControl : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {

  IBOutlet NSTableView  *recentScansView;
  IBOutlet NSTextField  *tagLine;
  IBOutlet NSButton  *clearHistoryButton;

  MainMenuControl  *mainMenuControl;

  int  numTagLines;
  int  tagLineIndex;

  BOOL  forceReloadOnShow;
}

// Override designated initialisers
- (instancetype) initWithWindow:(NSWindow *)window NS_UNAVAILABLE;
- (instancetype) initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

- (instancetype) initWithMainMenuControl:(MainMenuControl *)mainMenuControl NS_DESIGNATED_INITIALIZER;

- (IBAction) helpAction:(id)sender;
- (IBAction) scanAction:(id)sender;
- (IBAction) scanActionAfterDoubleClick:(id)sender;
- (IBAction) clearRecentScans:(id)sender;

- (void) changeTagLine;

@end
