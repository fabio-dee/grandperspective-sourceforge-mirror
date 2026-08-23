#import "FilterTestRepository.h"

#import "FileItemTest.h"
#import "SelectiveItemTest.h"

#import "NotifyingDictionary.h"


// The key for storing user tests
NSString  *UserTestsKey = @"filterTests";

// The key for storing application-provided tests
NSString  *AppTestsKey = @"GPDefaultFilterTests";


@interface FilterTestRepository (PrivateMethods) 

- (void) addStoredTestsFromDictionary:(NSDictionary *)testDicts
                          toLiveTests:(NSMutableDictionary *)testsByName;

@end


@implementation FilterTestRepository

+ (FilterTestRepository *)defaultFilterTestRepository {
  static FilterTestRepository  *defaultInstance = nil;
  static dispatch_once_t  onceToken;

  dispatch_once(&onceToken, ^{
    defaultInstance = [[FilterTestRepository alloc] init];
  });
  
  return defaultInstance;
}


- (instancetype) init {
  if (self = [super init]) {
    NSMutableDictionary  *initialTestDictionary = [NSMutableDictionary dictionaryWithCapacity: 16];
    
    // Load application-provided tests from the information properties file.
    NSBundle  *bundle = NSBundle.mainBundle;
      
    [self addStoredTestsFromDictionary: [bundle objectForInfoDictionaryKey: AppTestsKey]
                           toLiveTests: initialTestDictionary];
    applicationProvidedTests = [[NSDictionary alloc] initWithDictionary: initialTestDictionary];

    // Load additional user-created tests from preferences.
    NSUserDefaults  *userDefaults = NSUserDefaults.standardUserDefaults;
    [self addStoredTestsFromDictionary: [userDefaults dictionaryForKey: UserTestsKey]
                           toLiveTests: initialTestDictionary];

    // Store tests in a NotifyingDictionary
    _testsByName =
      (NSDictionary *)[[NotifyingDictionary alloc] initWithCapacity: 16
                                                    initialContents: initialTestDictionary];
  }
  
  return self;
}

- (void) dealloc {
  [_testsByName release];
  [applicationProvidedTests release];

  [super dealloc];
}


- (NotifyingDictionary *)testsByNameAsNotifyingDictionary {
  return (NotifyingDictionary *)self.testsByName;
}


- (FileItemTest *)fileItemTestForName:(NSString *)name {
  return self.testsByName[name];
}

- (FileItemTest *)applicationProvidedTestForName:(NSString *)name {
  return applicationProvidedTests[name];
}


- (void) storeUserCreatedTests {
  NSMutableDictionary  *testsDict = 
    [NSMutableDictionary dictionaryWithCapacity: self.testsByName.count];

  for (NSString *name in [self.testsByName keyEnumerator]) {
    FileItemTest  *fileItemTest = self.testsByName[name];

    if (fileItemTest != applicationProvidedTests[name]) {
      testsDict[name] = [fileItemTest dictionaryForObject];
    }
  }

  NSUserDefaults  *userDefaults = NSUserDefaults.standardUserDefaults;
  [userDefaults setObject: testsDict forKey: UserTestsKey];
  [userDefaults synchronize];
}

@end // @implementation FilterTestRepository


@implementation FilterTestRepository (PrivateMethods) 

- (void) addStoredTestsFromDictionary:(NSDictionary *)testDicts
                          toLiveTests:(NSMutableDictionary *)testsByNameVal {
  for (NSString *name in [testDicts keyEnumerator]) {
    NSDictionary  *filterTestDict = testDicts[name];
    FileItemTest  *fileItemTest = [FileItemTest fileItemTestFromDictionary: filterTestDict];
    
    testsByNameVal[name] = fileItemTest;
  }
}


- (void) addStoredTestsFromArray:(NSArray *)testDicts
                     toLiveTests:(NSMutableDictionary *)testsByNameVal {
  for (NSDictionary *fileItemTestDict in testDicts) {
    FileItemTest  *fileItemTest = [FileItemTest fileItemTestFromDictionary: fileItemTestDict];
    NSString  *name = fileItemTestDict[@"name"];

    testsByNameVal[name] = fileItemTest;
  }
}

@end // @implementation FilterTestRepository (PrivateMethods) 
