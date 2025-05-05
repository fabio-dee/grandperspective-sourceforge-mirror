#import <Cocoa/Cocoa.h>


extern NSString  *FileDeletionTargetsKey;
extern NSString  *ConfirmFileDeletionKey;
extern NSString  *ConfirmFolderDeletionKey;
extern NSString  *DefaultRescanActionKey;
extern NSString  *RescanBehaviourKey;
extern NSString  *NoViewsBehaviourKey;
extern NSString  *FileSizeMeasureKey;
extern NSString  *FileSizeUnitSystemKey;
extern NSString  *DefaultDrawItemsKey;
extern NSString  *DefaultColorMappingKey;
extern NSString  *DefaultColorPaletteKey;
extern NSString  *DefaultDrawItemsKey;
extern NSString  *ScanFilterKey;
extern NSString  *MaskFilterKey;
extern NSString  *DefaultColorGradient;
extern NSString  *MinimumTimeBoundForColorMappingKey;
extern NSString  *ShowEntireVolumeByDefaultKey;
extern NSString  *ProgressPanelRefreshRateKey;
extern NSString  *ProgressPanelStableTimeKey;
extern NSString  *DefaultViewWindowWidth;
extern NSString  *DefaultViewWindowHeight;
extern NSString  *CustomFileOpenApplication;
extern NSString  *CustomFileRevealApplication;
extern NSString  *UpdateFiltersBeforeUse;
extern NSString  *DelayBeforeWelcomeWindowAfterStartupKey;
extern NSString  *KeyboardNavigationDeltaKey;
extern NSString  *PackageCheckBehaviorKey;
extern NSString  *DefaultDisplayFocusKey;

extern NSString  *UnlimitedDisplayFocusValue;


@class FilterPopUpControl;

@interface PreferencesPanelControl : NSWindowController {

  IBOutlet NSPopUpButton  *fileDeletionPopUp;
  IBOutlet NSButton  *fileDeletionConfirmationCheckBox;
  
  IBOutlet NSPopUpButton  *rescanBehaviourPopUp;

  IBOutlet NSPopUpButton  *noViewsBehaviourPopUp;
  
  IBOutlet NSPopUpButton  *fileSizeMeasurePopUp;
  IBOutlet NSPopUpButton  *fileSizeUnitSystemPopUp;
  IBOutlet NSPopUpButton  *scanFilterPopUp;

  IBOutlet NSPopUpButton  *defaultDrawItemsPopUp;
  IBOutlet NSPopUpButton  *defaultColorMappingPopUp;
  IBOutlet NSPopUpButton  *defaultColorPalettePopUp;
  IBOutlet NSPopUpButton  *defaultMaskFilterPopUp;
  IBOutlet NSPopUpButton  *defaultDisplayFocusPopUp;

  IBOutlet NSButton  *showEntireVolumeByDefaultCheckBox;

  FilterPopUpControl  *defaultMaskFilterPopUpControl;
  FilterPopUpControl  *scanFilterPopUpControl;
}

- (IBAction) popUpValueChanged:(id)sender;

- (IBAction) valueChanged:(id)sender;

+ (BOOL) appHasDeletePermission;

@end
