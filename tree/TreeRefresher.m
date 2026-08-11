#import "TreeRefresher.h"

#import "AlertMessage.h"
#import "CompoundItem.h"
#import "DirectoryItem.h"
#import "TreeBalancer.h"
#import "FilteredTreeGuide.h"
#import "ScanProgressTracker.h"
#import "LogManager.h"


@interface TreeRefresher (PrivateMethods)

- (void) refreshItemTree:(DirectoryItem *)oldDir
                    into:(DirectoryItem *)newDir;

- (void) refreshViaFullRescanItemTree:(DirectoryItem *)oldDir
                                 into:(DirectoryItem *)newDir;

- (void) refreshViaShallowRescanItemTree:(DirectoryItem *)oldDir
                                    into:(DirectoryItem *)newDir;

- (void) refreshViaShallowCopyItemTree:(DirectoryItem *)oldDir
                                  into:(DirectoryItem *)newDir;

- (BOOL) deepHardlinkCompare:(DirectoryItem *)oldDir to:(DirectoryItem *)newDir;
- (BOOL) shallowHardlinkCompare:(DirectoryItem *)oldDir to:(DirectoryItem *)newDir;

@end // @interface TreeRefresher (PrivateMethods)


@implementation TreeRefresher

- (instancetype) initWithFilterSet:(FilterSet *)filterSetVal
                           oldTree:(DirectoryItem *)oldTreeVal {
  if (self = [super initWithFilterSet: filterSetVal]) {
    oldTree = [oldTreeVal retain];
  }
  return self;
}

- (void) dealloc {
  [oldTree release];

  [super dealloc];
}

@end // @implementation TreeRefresher

@implementation TreeRefresher (ProtectedMethods)

/* Constructs a tree for the given folder. It is used to implement buildTreeForPath:
 *
 * Overrides method in parent class to provide refresh implementation.
 */
- (BOOL) buildTreeForDirectory:(DirectoryItem *)dirItem atPath:(NSString *)path {
  hardLinkMismatch = NO;

  [self refreshItemTree: oldTree into: dirItem];

  return !abort;
}

- (AlertMessage *)createAlertMessage:(DirectoryItem *)scanTree {
  if (hardLinkMismatch) {
    AlertMessage  *alert = [[[AlertMessage alloc] init] autorelease];
    alert.messageText = NSLocalizedString
      (@"Inaccuracies in hard-linked folder contents", @"Alert message");
    alert.informativeText = NSLocalizedString
      (@"The refreshed content may not be fully accurate. Hard-linked items may occur more than once or could be missing. Perform a rescan to ensure that each hard-linked item occurs only once",
       @"Alert message");
    return alert;
  }

  return [super createAlertMessage: scanTree];
}

@end // @implementation TreeRefresher (ProtectedMethods)

@implementation TreeRefresher (PrivateMethods)

- (void) refreshItemTree:(DirectoryItem *)oldDir
                    into:(DirectoryItem *)newDir {
  NSAssert([oldDir.label isEqualToString: newDir.label] , @"Label mismatch");
  os_log_debug(LogManager.defaultLogManager.appLog,
               "refreshItemTree %@", newDir.path);

  if (abort) return;

  if ((oldDir.rescanFlags & DirectoryNeedsFullRescan) != 0) {
    [self refreshViaFullRescanItemTree: oldDir into: newDir];
  }
  else if ((oldDir.rescanFlags & DirectoryNeedsShallowRescan) != 0) {
    [self refreshViaShallowRescanItemTree: oldDir into: newDir];
  }
  else {
    [self refreshViaShallowCopyItemTree: oldDir into: newDir];
  }
}

- (void) refreshViaFullRescanItemTree:(DirectoryItem *)oldDir
                                 into:(DirectoryItem *)newDir {
  NSString  *path = newDir.systemPath;

  os_log_info(LogManager.defaultLogManager.appLog,
              "Full rescan of %@", path);
  [self scanTreeForDirectory: newDir atPath: path];

  if (!hardLinkMismatch && ![self deepHardlinkCompare: oldDir to: newDir]) {
    os_log(LogManager.defaultLogManager.appLog,
           "Deep hardlink mismatch at %@", path);
    hardLinkMismatch = true;
  }
}


- (void) refreshViaShallowRescanItemTree:(DirectoryItem *)oldDir
                                    into:(DirectoryItem *)newDir {
  NSString  *path = newDir.systemPath;

  os_log_info(LogManager.defaultLogManager.appLog,
              "Shallow rescan of %@", path);

  [treeGuide descendIntoDirectory: newDir];
  [progressTracker processingFolder: newDir];

  // Gather the old directories
  NSMutableDictionary  *oldSubdirs = [NSMutableDictionary dictionary];
  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.directoryItems
                                     callback: ^(FileItem *dir) {
    oldSubdirs[dir.label] = dir;
  }];

  // Perform shallow rescan.
  DirectoryItem  *collector = [self getContentsForDirectory: newDir atPath: path];

  __block int  numSubdirs = 0;
  [CompoundItem visitFileItemChildrenMaybeNil: collector.directoryItems
                                     callback: ^(FileItem *dir) {
    ++numSubdirs;
  }];
  [progressTracker setNumSubFolders: numSubdirs];

  // Populate the children directories, put results in linked list.
  __block Item  *newSubdirs = nil;
  [CompoundItem visitFileItemChildrenMaybeNil: collector.directoryItems
                                     callback: ^(FileItem *dir) {
    DirectoryItem  *newSubdir = (DirectoryItem *)dir;
    DirectoryItem  *oldSubdir = oldSubdirs[newSubdir.label];

    if (oldSubdir != nil) {
      [self refreshItemTree: oldSubdir into: newSubdir];
    } else {
      [self scanTreeForDirectory: newSubdir atPath: newSubdir.systemPath];
    }

    // Exclude empty directories
    if (newSubdir.itemSize == 0) return;

    if (newSubdirs == nil) {
      newSubdirs = [newSubdir retain];
    } else {
      CompoundItem  *newHead = [[CompoundItem alloc] initWithFirst: newSubdir second: newSubdirs];
      [newSubdirs release];
      newSubdirs = newHead;
    }
  }];

  // Balance the items
  Item  *balancedFiles = [treeBalancer convertLinkedListToTree: collector.fileItems];
  Item  *balancedSubdirs = [treeBalancer convertLinkedListToTree: newSubdirs];
  [newSubdirs release];

  [newDir setFileItems: balancedFiles directoryItems: balancedSubdirs];

  [treeGuide emergedFromDirectory: newDir];
  [progressTracker processedFolder: newDir];

  if (!hardLinkMismatch && ![self shallowHardlinkCompare: oldDir to: newDir]) {
    os_log(LogManager.defaultLogManager.appLog,
           "Shallow hardlink mismatch at %@", path);
    hardLinkMismatch = true;
  }
}

- (void) refreshViaShallowCopyItemTree:(DirectoryItem *)oldDir
                                  into:(DirectoryItem *)newDir {
  [treeGuide descendIntoDirectory: newDir];
  [progressTracker processingFolder: newDir];

  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.fileItems
                                     callback: ^(FileItem *oldFile) {
    [newDir addFile: [oldFile duplicateFileItem: newDir]];
  }];

  __block int  numSubdirs = 0;
  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.directoryItems
                                     callback: ^(FileItem *oldSubdir) {
    ++numSubdirs;
  }];
  [progressTracker setNumSubFolders: numSubdirs];

  // Populate the children directories
  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.directoryItems
                                     callback: ^(FileItem *oldSubdir) {
    DirectoryItem  *newSubdir = (DirectoryItem *)[oldSubdir duplicateFileItem: newDir];

    [self refreshItemTree: (DirectoryItem *)oldSubdir into: newSubdir];
    [newDir addSubdir: newSubdir];
  }];

  [newDir setSize];
  [newDir balanceTree: treeBalancer];

  [treeGuide emergedFromDirectory: newDir];
  [progressTracker processedFolder: newDir];
}

- (BOOL) deepHardlinkCompare:(DirectoryItem *)oldDir to:(DirectoryItem *)newDir {
  NSMutableSet  *oldSet = [[NSMutableSet alloc] init];
  NSMutableSet  *newSet = [[NSMutableSet alloc] init];

  // Find hard-linked items in the old directory
  [oldDir visitFileItemDescendants: ^(FileItem *file) {
    if (file.isHardLinked) {
      [oldSet addObject: file.label];
    }
  }];

  // Find hard-linked items in the old directory
  [newDir visitFileItemDescendants: ^(FileItem *file) {
    if (file.isHardLinked) {
      [newSet addObject: file.label];
    }
  }];

  BOOL  equal = [oldSet isEqualToSet: newSet];

  [oldSet release];
  [newSet release];

  return equal;
}

- (BOOL) shallowHardlinkCompare:(DirectoryItem *)oldDir to:(DirectoryItem *)newDir {
  NSMutableSet  *oldSet = [[NSMutableSet alloc] init];
  NSMutableSet  *newSet = [[NSMutableSet alloc] init];

  // Find hard-linked items in the old directory
  [CompoundItem visitFileItemChildrenMaybeNil: oldDir.childItems
                                     callback: ^(FileItem *file) {
    if (file.isHardLinked) {
      [oldSet addObject: file.label];
    }
  }];

  // Find hard-linked items in the old directory
  [CompoundItem visitFileItemChildrenMaybeNil: newDir.childItems
                                     callback: ^(FileItem *file) {
    if (file.isHardLinked) {
      [newSet addObject: file.label];
    }
  }];

  BOOL  equal = [oldSet isEqualToSet: newSet];

  [oldSet release];
  [newSet release];

  return equal;
}

@end // @implementation TreeRefresher (PrivateMethods)
