// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SBMessage.h instead.

#import <CoreData/CoreData.h>


extern const struct SBMessageAttributes {
	__unsafe_unretained NSString *data;
	__unsafe_unretained NSString *incoming;
	__unsafe_unretained NSString *nonce;
	__unsafe_unretained NSString *timestamp;
} SBMessageAttributes;

extern const struct SBMessageRelationships {
	__unsafe_unretained NSString *conversation;
} SBMessageRelationships;

extern const struct SBMessageFetchedProperties {
} SBMessageFetchedProperties;

@class SBConversation;






@interface SBMessageID : NSManagedObjectID {}
@end

@interface _SBMessage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SBMessageID*)objectID;





@property (nonatomic, strong) NSData* data;



//- (BOOL)validateData:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* incoming;



@property BOOL incomingValue;
- (BOOL)incomingValue;
- (void)setIncomingValue:(BOOL)value_;

//- (BOOL)validateIncoming:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSData* nonce;



//- (BOOL)validateNonce:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* timestamp;



//- (BOOL)validateTimestamp:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) SBConversation *conversation;

//- (BOOL)validateConversation:(id*)value_ error:(NSError**)error_;





@end

@interface _SBMessage (CoreDataGeneratedAccessors)

@end

@interface _SBMessage (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveData;
- (void)setPrimitiveData:(NSData*)value;




- (NSNumber*)primitiveIncoming;
- (void)setPrimitiveIncoming:(NSNumber*)value;

- (BOOL)primitiveIncomingValue;
- (void)setPrimitiveIncomingValue:(BOOL)value_;




- (NSData*)primitiveNonce;
- (void)setPrimitiveNonce:(NSData*)value;




- (NSDate*)primitiveTimestamp;
- (void)setPrimitiveTimestamp:(NSDate*)value;





- (SBConversation*)primitiveConversation;
- (void)setPrimitiveConversation:(SBConversation*)value;


@end
