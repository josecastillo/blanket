// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SBConversation.m instead.

#import "_SBConversation.h"

const struct SBConversationAttributes SBConversationAttributes = {
	.conversation_id = @"conversation_id",
	.last_synced = @"last_synced",
	.latest_message = @"latest_message",
	.name = @"name",
	.pubkey_a = @"pubkey_a",
	.pubkey_b = @"pubkey_b",
	.unread = @"unread",
};

const struct SBConversationRelationships SBConversationRelationships = {
	.messages = @"messages",
};

const struct SBConversationFetchedProperties SBConversationFetchedProperties = {
};

@implementation SBConversationID
@end

@implementation _SBConversation

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"SBConversation" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"SBConversation";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"SBConversation" inManagedObjectContext:moc_];
}

- (SBConversationID*)objectID {
	return (SBConversationID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"unreadValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unread"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic conversation_id;






@dynamic last_synced;






@dynamic latest_message;






@dynamic name;






@dynamic pubkey_a;






@dynamic pubkey_b;






@dynamic unread;



- (BOOL)unreadValue {
	NSNumber *result = [self unread];
	return [result boolValue];
}

- (void)setUnreadValue:(BOOL)value_ {
	[self setUnread:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveUnreadValue {
	NSNumber *result = [self primitiveUnread];
	return [result boolValue];
}

- (void)setPrimitiveUnreadValue:(BOOL)value_ {
	[self setPrimitiveUnread:[NSNumber numberWithBool:value_]];
}





@dynamic messages;

	
- (NSMutableSet*)messagesSet {
	[self willAccessValueForKey:@"messages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"messages"];
  
	[self didAccessValueForKey:@"messages"];
	return result;
}
	






@end
