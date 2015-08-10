//
//  MSKitProtocols.h
//  MSKit
//
//  Created by Jason Cardwell on 3/27/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;

@protocol MSDebugDescription <NSObject>

- (NSString *)debugDescriptionWithVerbosity:(NSUInteger)verbosity 
								   tabDepth:(NSUInteger)tabDepth
									  inset:(NSUInteger)inset;

@end

@protocol MSDismissable <NSObject>

- (IBAction)dismiss:(id)sender;

@end

@protocol MSCaching <NSObject>

@property BOOL shouldUseCache;

- (void)emptyCache;


@end

@protocol MSResettable <NSObject>

- (void)resetToInitialState;

@end

//@class MSDictionary;

//@protocol MSJSONExport <NSObject>
//
//@property (nonatomic, weak, readonly) id         JSONObject;
//@property (nonatomic, weak, readonly) NSString * JSONString;
//
//@optional
//- (MSDictionary *)JSONDictionary;
//- (BOOL)writeJSONToFile:(NSString *)file;
//
//@end

@protocol MSKeyContaining <NSObject>

- (BOOL)hasKey:(id<NSCopying>)key;
- (id)valueForKey:(id<NSCopying>)key;

@end

@protocol MSKeySearchable <NSObject>

- (NSArray *)allValues;

@end

@protocol MSObjectContaining <NSObject>

- (NSArray *)topLevelObjects;
- (NSArray *)topLevelObjectsConformingTo:(Protocol *)protocol;
- (NSArray *)topLevelObjectsOfKind:(Class)kind;

- (NSArray *)allObjectsOfKind:(Class)kind;
- (NSArray *)allObjectsConformingTo:(Protocol *)protocol;

@end
