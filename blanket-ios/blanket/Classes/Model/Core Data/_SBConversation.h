// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SBConversation.h instead.

#import <CoreData/CoreData.h>


extern const struct SBConversationAttributes {
	__unsafe_unretained NSString *conversation_id;
	__unsafe_unretained NSString *last_synced;
	__unsafe_unretained NSString *latest_message;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *pubkey_a;
	__unsafe_unretained NSString *pubkey_b;
	__unsafe_unretained NSString *unread;
} SBConversationAttributes;

extern const struct SBConversationRelationships {
	__unsafe_unretained NSString *messages;
} SBConversationRelationships;

extern const struct SBConversationFetchedProperties {
} SBConversationFetchedProperties;

@class SBMessage;









@interface SBConversationID : NSManagedObjectID {}
@end

@interface _SBConversation : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SBConversationID*)objectID;





@property (nonatomic, strong) NSString* conversation_id;



//- (BOOL)validateConversation_id:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* last_synced;



//- (BOOL)validateLast_synced:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* latest_message;



//- (BOOL)validateLatest_message:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSData* pubkey_a;



//- (BOOL)validatePubkey_a:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSData* pubkey_b;



//- (BOOL)validatePubkey_b:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* unread;



@property BOOL unreadValue;
- (BOOL)unreadValue;
- (void)setUnreadValue:(BOOL)value_;

//- (BOOL)validateUnread:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *messages;

- (NSMutableSet*)messagesSet;





@end

@interface _SBConversation (CoreDataGeneratedAccessors)

- (void)addMessages:(NSSet*)value_;
- (void)removeMessages:(NSSet*)value_;
- (void)addMessagesObject:(SBMessage*)value_;
- (void)removeMessagesObject:(SBMessage*)value_;

@end

@interface _SBConversation (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveConversation_id;
- (void)setPrimitiveConversation_id:(NSString*)value;




- (NSDate*)primitiveLast_synced;
- (void)setPrimitiveLast_synced:(NSDate*)value;




- (NSDate*)primitiveLatest_message;
- (void)setPrimitiveLatest_message:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSData*)primitivePubkey_a;
- (void)setPrimitivePubkey_a:(NSData*)value;




- (NSData*)primitivePubkey_b;
- (void)setPrimitivePubkey_b:(NSData*)value;




- (NSNumber*)primitiveUnread;
- (void)setPrimitiveUnread:(NSNumber*)value;

- (BOOL)primitiveUnreadValue;
- (void)setPrimitiveUnreadValue:(BOOL)value_;





- (NSMutableSet*)primitiveMessages;
- (void)setPrimitiveMessages:(NSMutableSet*)value;


@end
