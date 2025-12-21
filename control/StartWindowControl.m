#import "StartWindowControl.h"

#import "NSURL.h"
#import "RecentDocumentTableCellView.h"
#import "LocalizableStrings.h"
#import "ControlConstants.h"
#import "PreferencesPanelControl.h"

NSString*  TaglineTable = @"Taglines";
NSString*  NumTaglines = @"num-taglines";
NSString*  TaglineFormat = @"tagline-%d";

NSString*  fdaPreferencesUrl =
  @"x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles";

NSString*  checkFdaPermissionsPath = @"~/Library/Containers/com.apple.stocks";

@interface StartWindowControl (PrivateMethods)

- (void) setTagLineField;
- (void) startScan:(NSInteger)selectedRow sender:(id)sender;

- (BOOL) hasFdaPermissions;
- (BOOL) shouldShowFdaWarningSheet;
- (void) showFdaWarningSheet;
- (void) handleSuppressFdaWarningButton:(id)sender;
- (void) handleEditFdaPreferences;

@end // @interface StartWindowControl (PrivateMethods)

@implementation StartWindowControl

- (instancetype) initWithMainMenuControl:(MainMenuControl *)mainMenuControlVal {
  if (self = [super initWithWindow: nil]) {
    mainMenuControl = [mainMenuControlVal retain];

    numTagLines = [NSBundle.mainBundle localizedStringForKey: NumTaglines
                                                       value: @"1"
                                                       table: TaglineTable].intValue;

    // Show a random tagline
    tagLineIndex = arc4random_uniform(numTagLines);

    forceReloadOnShow = NO;
  }
  return self;
}

- (void) dealloc {
  NSLog(@"StartWindowControl.dealloc");
  [mainMenuControl release];

  [super dealloc];
}

- (NSString *)windowNibName {
  return @"StartWindow";
}

- (void)windowDidLoad {
  [super windowDidLoad];
  
  recentScansView.delegate = self;
  recentScansView.dataSource = self;
  recentScansView.doubleAction = @selector(scanActionAfterDoubleClick:);

  [recentScansView registerForDraggedTypes: NSURL.supportedPasteboardTypes];
  [recentScansView sizeLastColumnToFit];

  [self setTagLineField];
}


//----------------------------------------------------------------------------
// NSTableSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
  return NSDocumentController.sharedDocumentController.recentDocumentURLs.count + 1;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
  
  RecentDocumentTableCellView *cellView = [tableView makeViewWithIdentifier: @"RecentScanView"
                                                                      owner: self];

  NSInteger  numRecent = NSDocumentController.sharedDocumentController.recentDocumentURLs.count;

  if (row < numRecent) {
    NSURL *docUrl = NSDocumentController.sharedDocumentController.recentDocumentURLs[row];

    cellView.textField.stringValue =
      [NSFileManager.defaultManager displayNameAtPath: docUrl.path];
    cellView.imageView.image = [NSWorkspace.sharedWorkspace iconForFile: docUrl.path];
    cellView.secondTextField.stringValue = docUrl.path;
  } else {
    NSString  *msg = ((numRecent > 0) ?
                      NSLocalizedString(@"Select Other Folder",
                                        @"Entry in Start window, alongside other options") :
                      NSLocalizedString(@"Select Folder", @"Solitairy entry in Start window"));

    cellView.textField.stringValue = msg;
    cellView.secondTextField.stringValue = LocalizationNotNeeded(@"...");
  }

  return cellView;
}

- (NSDragOperation) tableView:(NSTableView *)tableView
                 validateDrop:(id <NSDraggingInfo>)info
                  proposedRow:(NSInteger)row
        proposedDropOperation:(NSTableViewDropOperation)op {

  NSURL *filePathURL = [NSURL getFileURLFromPasteboard: info.draggingPasteboard];
  //NSLog(@"Drop request with %@", filePathURL);

  if (filePathURL.isDirectory) {
    return NSDragOperationGeneric;
  }

  return NSDragOperationNone;
}

- (BOOL) tableView:(NSTableView *)tableView
        acceptDrop:(id <NSDraggingInfo>)info
               row:(NSInteger)row
     dropOperation:(NSTableViewDropOperation)op {

  NSURL *filePathURL = [NSURL getFileURLFromPasteboard: info.draggingPasteboard];
  //NSLog(@"Accepting drop request with %@", filePathURL);

  [mainMenuControl scanFolder: filePathURL.path];

  return YES;
}

//----------------------------------------------------------------------------

- (IBAction) scanAction:(id)sender {
  [self startScan: recentScansView.selectedRow sender: sender];
}

- (IBAction) scanActionAfterDoubleClick:(id)sender {
  [self startScan: recentScansView.clickedRow sender: sender];
}

- (IBAction) clearRecentScans:(id)sender {
  [NSDocumentController.sharedDocumentController clearRecentDocuments: sender];

  [recentScansView reloadData];
  clearHistoryButton.enabled = false;
}

- (IBAction) helpAction:(id)sender {
  [self.window close];

  [NSApplication.sharedApplication showHelp: sender];
}

- (void) cancelOperation:(id)sender {
  [self.window close];
}

- (void) showWindow:(id)sender {
  // Except when the window is first shown, always reload the data as the number and order of recent
  // documents may have changed.
  if (forceReloadOnShow) {
    [recentScansView reloadData];
  } else {
    forceReloadOnShow = YES;
  }

  clearHistoryButton.enabled =
    NSDocumentController.sharedDocumentController.recentDocumentURLs.count > 0;

  [super showWindow: sender];

  if ([self shouldShowFdaWarningSheet]) {
    [self showFdaWarningSheet];
  }
}

// Invoked because the controller is the delegate for the window.
- (void) windowWillClose:(NSNotification *)notification {
  [NSApp stopModal];
}

- (void) changeTagLine {
  tagLineIndex = (tagLineIndex + 1) % numTagLines;
  [self setTagLineField];
}

@end


@implementation StartWindowControl (PrivateMethods)

- (void) setTagLineField {
  NSString  *tagLineKey = [NSString stringWithFormat: TaglineFormat, tagLineIndex + 1];
  NSString  *localizedTagLine = [NSBundle.mainBundle localizedStringForKey: tagLineKey
                                                                     value: nil
                                                                     table: TaglineTable];
  // Nil-check to avoid problems if tag lines are not properly localized
  if (localizedTagLine != nil) {
    tagLine.stringValue = localizedTagLine;
  }
}

- (void) startScan:(NSInteger)selectedRow sender:(id)sender {
  [self.window close];

  NSDocumentController  *controller = NSDocumentController.sharedDocumentController;

  if (selectedRow >= 0 && selectedRow < controller.recentDocumentURLs.count) {
    // Scan selected folder
    NSURL *docUrl = controller.recentDocumentURLs[selectedRow];

    [mainMenuControl scanFolder: docUrl.path];
  } else {
    // Let user select the folder to scan
    [mainMenuControl scanDirectoryView: sender];
  }
}

- (BOOL) hasFdaPermissions {
  NSString *path = checkFdaPermissionsPath.stringByExpandingTildeInPath;
  NSString *tildeReplacement = [path substringToIndex:
                                path.length - checkFdaPermissionsPath.length + 1];

  NSRange range = [tildeReplacement rangeOfString: @"/Library/Containers"];
  if (range.location != NSNotFound) {
    // Path is sand-boxed. Replace sandbox home path by actual user home.

    NSString *userHome = [tildeReplacement substringToIndex: range.location];
    path = [userHome stringByAppendingPathComponent:
            [checkFdaPermissionsPath substringFromIndex: 2]];
  }

  NSError *error = nil;
  [NSFileManager.defaultManager contentsOfDirectoryAtPath: path error: &error];

  if (error) {
    NSLog(@"FDA permission check using %@ failed, error: %@", path, error);
    return YES;
  }

  NSLog(@"FDA permission check using %@ succeeded", path);

  return NO;

}

- (BOOL) shouldShowFdaWarningSheet {
  // Always check, even when warning should be suppressed. This way, the log always contains the
  // outcome of the FDA check, which can be helpful for trouble-shooting.
  if ([self hasFdaPermissions]) {
    return NO;
  }

  NSUserDefaults  *userDefaults = NSUserDefaults.standardUserDefaults;
  if ([userDefaults boolForKey: SuppressFdaWarningSheetKey]) {
    return NO;
  }

  return YES;
}

- (void) showFdaWarningSheet {
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];

  [alert addButtonWithTitle: @"Edit Preferences"]; // Main/default action
  [alert addButtonWithTitle: CANCEL_BUTTON_TITLE];
  alert.messageText = NSLocalizedString
    (@"GrandPerspective seems to lack Full Disk Access permissions",
     @"FDA warning sheet");
  [alert setInformativeText: NSLocalizedString
    (@"This may limit the disk content it can see. To remedy this, you can grant permissions via the preferences.",
     @"FDA warning sheet")
  ];

  alert.showsSuppressionButton = YES;
  alert.suppressionButton.target = self;
  alert.suppressionButton.action = @selector(handleSuppressFdaWarningButton:);

  NSUserDefaults  *userDefaults = NSUserDefaults.standardUserDefaults;
  BOOL suppressSheet = [userDefaults boolForKey: SuppressFdaWarningSheetKey];
  alert.suppressionButton.state = suppressSheet ? NSControlStateValueOn : NSControlStateValueOff;

  [alert beginSheetModalForWindow: self.window completionHandler: ^(NSModalResponse returnCode) {
    if (returnCode == NSAlertFirstButtonReturn) {
      [self handleEditFdaPreferences];
    }
  }];
}

- (void) handleSuppressFdaWarningButton:(id)sender {
  NSUserDefaults  *userDefaults = NSUserDefaults.standardUserDefaults;
  [userDefaults setBool: [sender state] == NSControlStateValueOn
                 forKey: SuppressFdaWarningSheetKey];
}

- (void) handleEditFdaPreferences {
  NSURL *url = [NSURL URLWithString: fdaPreferencesUrl];
  [NSWorkspace.sharedWorkspace openURL: url];
}

@end // @interface StartWindowControl (PrivateMethods)
