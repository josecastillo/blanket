// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SBMessage.m instead.

#import "_SBMessage.h"

const struct SBMessageAttributes SBMessageAttributes = {
	.data = @"data",
	.incoming = @"incoming",
	.nonce = @"nonce",
	.timestamp = @"timestamp",
};

const struct SBMessageRelationships SBMessageRelationships = {
	.conversation = @"conversation",
};

const struct SBMessageFetchedProperties SBMessageFetchedProperties = {
};

@implementation SBMessageID
@end

@implementation _SBMessage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"SBMessage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"SBMessage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"SBMessage" inManagedObjectContext:moc_];
}

- (SBMessageID*)objectID {
	return (SBMessageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"incomingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"incoming"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic data;






@dynamic incoming;



- (BOOL)incomingValue {
	NSNumber *result = [self incoming];
	return [result boolValue];
}

- (void)setIncomingValue:(BOOL)value_ {
	[self setIncoming:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIncomingValue {
	NSNumber *result = [self primitiveIncoming];
	return [result boolValue];
}

- (void)setPrimitiveIncomingValue:(BOOL)value_ {
	[self setPrimitiveIncoming:[NSNumber numberWithBool:value_]];
}





@dynamic nonce;






@dynamic timestamp;






@dynamic conversation;

	






@end
