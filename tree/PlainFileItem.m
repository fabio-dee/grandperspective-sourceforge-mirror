#import "PlainFileItem.h"

#import "DirectoryItem.h"
#import "UniformType.h"

@implementation PlainFileItem

// Overrides designated initialiser
- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(item_size_t)size
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime {
  return [self initWithLabel: label
                      parent: parent
                        size: size
                        type: nil
                       flags: flags
                creationTime: creationTime
            modificationTime: modificationTime
                  accessTime: accessTime];
}

- (instancetype) initWithLabel:(NSString *)label
                        parent:(DirectoryItem *)parent
                          size:(item_size_t)size
                          type:(UTType *)type
                         flags:(FileItemOptions)flags
                  creationTime:(CFAbsoluteTime)creationTime
              modificationTime:(CFAbsoluteTime)modificationTime
                    accessTime:(CFAbsoluteTime)accessTime {
  if (self = [super initWithLabel: label
                           parent: parent
                             size: size
                            flags: flags
                     creationTime: creationTime
                 modificationTime: modificationTime
                       accessTime: accessTime]) {
    _uniformType = [type retain];
  }
  
  return self;
}

- (void) dealloc {
  [_uniformType release];
  
  [super dealloc];
}

// Overrides abstract method in FileItem
- (FileItem *)duplicateFileItem:(DirectoryItem *)newParent {
  return [[[PlainFileItem alloc] initWithLabel: self.label
                                        parent: newParent
                                          size: self.itemSize
                                          type: self.uniformType
                                         flags: self.fileItemFlags
                                  creationTime: self.creationTime
                              modificationTime: self.modificationTime
                                    accessTime: self.accessTime] autorelease];
}

// Overrides abstract method in Item
- (void) visitFileItemDescendants:(void(^)(FileItem *))callback {
  callback(self);
}

// Overrides abstract method in Item
- (FileItem *)findFileItemDescendant:(BOOL(^)(FileItem *))predicate {
  return predicate(self) ? self : nil;
}

@end
