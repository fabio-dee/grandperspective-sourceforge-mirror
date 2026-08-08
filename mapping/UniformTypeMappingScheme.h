#import <Cocoa/Cocoa.h>

#import "StatefullFileItemMapping.h"


@class UniformTypeRanking;

@interface UniformTypeMappingScheme : StatefullFileItemMapping {
}

- (instancetype) initWithUniformTypeRanking:(UniformTypeRanking *)typeRanking NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, strong) UniformTypeRanking *uniformTypeRanking;

@end
