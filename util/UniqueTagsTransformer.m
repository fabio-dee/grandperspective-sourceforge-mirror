#import "UniqueTagsTransformer.h"


@implementation UniqueTagsTransformer

+ (Class) transformedValueClass {
  return NSNumber.class;
}

+ (BOOL) allowsReverseTransformation {
  return YES; 
}


+ (UniqueTagsTransformer *) defaultUniqueTagsTransformer {
  static UniqueTagsTransformer  *defaultUniqueTagsTransformer = nil;
  static dispatch_once_t  onceToken;

  dispatch_once(&onceToken, ^{
    defaultUniqueTagsTransformer = [[UniqueTagsTransformer alloc] init];
  });
  
  return defaultUniqueTagsTransformer;
}


- (instancetype) init {
  if (self = [super init]) {
    valueToTag = [[NSMutableDictionary alloc] initWithCapacity: 64];
    tagToValue = [[NSMutableDictionary alloc] initWithCapacity: 64];
    
    nextTag = 0;
  }
  
  return self;
}

- (void) dealloc {
  [valueToTag release];
  [tagToValue release];
  
  [super dealloc];
}


- (id) transformedValue:(id) value {
  if (value == nil) {
    // Gracefully handle nil values.
    return nil;
  }

  id  tag = valueToTag[value];
 
  if (tag == nil) {
    tag = @(nextTag++);

    valueToTag[value] = tag;
    tagToValue[tag] = value;
  }
  
  return tag;
}

- (id) reverseTransformedValue:(id) tag {
  id  value = tagToValue[tag];
  
  NSAssert(value != nil, @"Unknown tag value.");
  
  return value;
}


- (void) addLocalisedNamesFor:(NSArray *)names
                      toPopUp:(NSPopUpButton *)popUp
                       select:(NSString *)selectName
                        table:(NSString *)tableName {
  for (NSString *name in names) {
    [self addLocalisedNameFor: name
                      toPopUp: popUp
                       select: [name isEqualToString: selectName]
                        table: tableName];
  }
}

- (void) addLocalisedNameFor:(NSString *)name
                     toPopUp:(NSPopUpButton *)popUp
                      select:(BOOL) select
                       table:(NSString *)tableName {
  NSString  *localizedName = [NSBundle.mainBundle localizedStringForKey: name
                                                                  value: nil
                                                                  table: tableName];

  // Find location where to insert item so that list remains sorted by localized name
  // Note: Using linear search, which is OK as long as list is relatively small.
  int  index = 0;
  while (index < popUp.numberOfItems) {
    NSString  *otherName = [popUp itemAtIndex: index].title;
    if ([localizedName compare: otherName] == NSOrderedAscending) {
      break;
    }
    index++;
  }

  [self addValue: name
       withTitle: localizedName
         toPopUp: popUp
         atIndex: index
          select: select];
}

- (void) addSortedLocalisedNamesFor:(NSArray *)names
                            toPopUp:(NSPopUpButton *)popUp
                             select:(NSString *)selectName
                              table:(NSString *)tableName {
  int  index = (int)popUp.numberOfItems;

  for (NSString *name in names) {
    NSString  *localizedName = [NSBundle.mainBundle localizedStringForKey: name
                                                                    value: nil
                                                                    table: tableName];
    [self addValue: name
         withTitle: localizedName
           toPopUp: popUp
           atIndex: index++
            select: [name isEqualToString: selectName]];
  }
}

- (void) addValue:(NSObject *)value
        withTitle:(NSString *)title
          toPopUp:(NSPopUpButton *)popUp
          atIndex:(int)index
           select:(BOOL)select {
  int  tag = [[self transformedValue: value] intValue];

  [popUp insertItemWithTitle: title atIndex: index];
  [popUp itemAtIndex: index].tag = tag;

  if (select) {
    [popUp selectItemAtIndex: index];
  }
}

- (NSString *)nameForTag:(NSUInteger)tag {
  return [self reverseTransformedValue: @(tag)];
}

- (NSObject *)valueForTag:(NSUInteger)tag {
  return [self reverseTransformedValue: @(tag)];
}

- (NSUInteger) tagForName:(NSString *)name {
  return [[self transformedValue: name] intValue];
}

- (NSUInteger) tagForValue:(NSObject *)value {
  return [[self transformedValue: value] intValue];
}

@end
