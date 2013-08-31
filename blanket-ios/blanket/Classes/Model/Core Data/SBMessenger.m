//
//  BKTDataSource.m
//  blanket
//
//  Created by Joey Castillo on 7/16/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBMessenger.h"
#import "SBCryptographer.h"
#import "SBKeymaster.h"
#import "SBWebServiceClient.h"
#import "NSData+Base64.h"

@implementation SBMessenger

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

static SBMessenger *instance;

+ (SBMessenger *)defaultMessenger {
    if (!instance)
        instance = [[self alloc] init];
    return instance;
}

- (NSString *)plainTextForMessage:(SBMessage *)message {
    NSData *publicKey;
    if (message.incomingValue)
        publicKey = message.conversation.pubkey_b;
    else
        publicKey = message.conversation.pubkey_a;
    NSData *messageData = [SBCryptographer decryptMessage:message.data
                                            withPublicKey:publicKey
                                                secretKey:[SBKeymaster secretKeyForConversationID:message.conversation.conversation_id]
                                                    nonce:message.nonce];
    if (messageData)
        return [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];

    return nil;
}

- (void)createConversationWithName:(NSString *)name
                    conversationID:(NSString *)conversationID
                        accessCode:(NSString *)accessCode
                        publicKeyA:(NSData *)alicePublicKey
                        publicKeyB:(NSData *)bobPublicKey
                        secretKeyA:(NSData *)aliceSecretKey
                          callback:(void(^)(BOOL success, NSError *error))callback {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSDictionary *response = [[SBWebServiceClient defaultClient] openChannelWithConversationID:conversationID
                                                                                        accessCode:accessCode
                                                                                             error:&error];
        // And only store to the database if the request was successful.
        if (response) {
            SBConversation *conversation = [NSEntityDescription insertNewObjectForEntityForName:[SBConversation entityName]
                                                                         inManagedObjectContext:self.managedObjectContext];
            conversation.name = name;
            conversation.pubkey_a = alicePublicKey;
            conversation.pubkey_b = bobPublicKey;
            conversation.conversation_id = conversationID;
            conversation.last_synced = [NSDate dateWithTimeIntervalSince1970:[response[@"last_update"] doubleValue]];

            // Store private key and access code if successful
            if (![SBKeymaster secretKeyAttributesForConversationID:conversationID])
                [SBKeymaster setSecretKey:aliceSecretKey forConversationID:conversationID];
            if (![SBKeymaster accessCodeAttributesForConversationID:conversationID])
                [SBKeymaster setAccessCode:accessCode forConversationID:conversationID];

            dispatch_sync(dispatch_get_main_queue(), ^{
                [self saveContext];
                callback(YES, nil);
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{ callback(NO, error); });
        }
    });
}

- (void)conversationExistsWithConversationID:(NSString *)conversationID
                                  accessCode:(NSString *)accessCode
                                    callback:(void(^)(BOOL success, NSError *error))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSDictionary *response = [[SBWebServiceClient defaultClient] channelStatusForConversationID:conversationID
                                                                                         accessCode:accessCode
                                                                                              error:&error];
        if (response) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self saveContext];
                callback(YES, nil);
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{ callback(NO, error); });
        }
    });
}

- (void)destroyConversation:(SBConversation *)conversation callback:(void (^)(BOOL, NSError *))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSString *conversationID = conversation.conversation_id;
        NSDictionary *response = [[SBWebServiceClient defaultClient] closeChannelWithConversationID:conversationID
                                                                                   accessCode:[SBKeymaster accessCodeForConversationID:conversationID]
                                                                                        error:&error];
        // Only destroy the conversation if the request was successful.
        if (response) {
            [self.managedObjectContext deleteObject:conversation];
            [SBKeymaster deleteSecretKeyForConversationID:conversationID];
            [SBKeymaster deleteAccessCodeForConversationID:conversationID];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self saveContext];
                callback(YES, nil);
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{ callback(NO, error); });
        }
    });
}

- (void)postMessageData:(NSData *)messageData
         toConversation:(SBConversation *)conversation
               callback:(void(^)(BOOL success, NSError *error))callback {
    NSData *nonce = [SBCryptographer getNonce];

    // Encrypt the message twice: first to the recipient, and then to ourselves
    NSData *outgoingData = [SBCryptographer encryptMessage:messageData
                                           withPublicKey:conversation.pubkey_b
                                               secretKey:[SBKeymaster secretKeyForConversationID:conversation.conversation_id]
                                                     nonce:nonce];
    NSData *localData = [SBCryptographer encryptMessage:messageData
                                          withPublicKey:conversation.pubkey_a
                                              secretKey:[SBKeymaster secretKeyForConversationID:conversation.conversation_id]
                                                  nonce:nonce];
    
    // Only send if encryption succeeded
    if (outgoingData && localData) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSError *error = nil;
            NSString *conversationID = conversation.conversation_id;
            NSDictionary *response = [[SBWebServiceClient defaultClient] postMessage:outgoingData
                                                                     withNonce:nonce
                                                          toConversationWithID:conversationID
                                                                    accessCode:[SBKeymaster accessCodeForConversationID:conversationID]
                                                                         error:&error];
            // And only store to the database if the request was successful.
            if (response) {
                SBMessage *message = [NSEntityDescription insertNewObjectForEntityForName:[SBMessage entityName]
                                                                   inManagedObjectContext:self.managedObjectContext];
                NSTimeInterval timeInterval = [response[@"timestamp"] doubleValue];
                message.conversation = conversation;
                message.data = localData;
                message.nonce = nonce;
                message.incoming = @NO;
                message.timestamp = [NSDate dateWithTimeIntervalSince1970:timeInterval];
                message.conversation.latest_message = message.timestamp;
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self saveContext];
                    callback(YES, nil);
                });
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{ callback(NO, error); });
            }
        });
    } else {
        NSError *error = [NSError errorWithDomain:SBBlanketDomain
                                             code:-1
                                         userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"ENCRYPTION_FAILED_MESSAGE_NOT_SENT", @"String of arbitrary length for an error message.") }];
        callback(NO, error);
        return;
    }
}

- (void)refreshConversation:(SBConversation *)conversation
                   callback:(void(^)(BOOL success, NSError *error))callback {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSString *conversationID = conversation.conversation_id;
        NSTimeInterval since = [conversation.last_synced timeIntervalSince1970];
        NSDictionary *response = [[SBWebServiceClient defaultClient] messagesForConversationID:conversationID
                                                                              accessCode:[SBKeymaster accessCodeForConversationID:conversationID]
                                                                                   since:since
                                                                                   error:&error];
        if (response) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSArray *messages = response[@"messages"];
                for (NSDictionary *incomingMessage in messages) {
                    // If we detect a duplicate nonce in the conversation, it's a dupe -- likely a message we sent ourselves, and subsequently received from the server.
                    NSData *messageNonce = [NSData dataFromBase64String:incomingMessage[@"nonce"]];
                    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[SBMessage entityName]];
                    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
                                              [NSPredicate predicateWithFormat:@"%K == %@", SBMessageRelationships.conversation, conversation],
                                              [NSPredicate predicateWithFormat:@"%K == %@", SBMessageAttributes.nonce, messageNonce],
                                              ]];
                    [fetchRequest setPredicate:predicate];
                    if ([[self.managedObjectContext executeFetchRequest:fetchRequest error:NULL] count])
                        continue;
                    
                    SBMessage *message = [NSEntityDescription insertNewObjectForEntityForName:[SBMessage entityName]
                                                                       inManagedObjectContext:self.managedObjectContext];
                    message.conversation = conversation;
                    message.data = [NSData dataFromBase64String:incomingMessage[@"data"]];
                    message.nonce = messageNonce;
                    message.incoming = @YES;
                    message.timestamp = [NSDate dateWithTimeIntervalSince1970:[incomingMessage[@"timestamp"] doubleValue]];
                    
                    conversation.unread = @YES;
                }
                
                // Update the latest message timestamp on the conversation
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[SBMessage entityName]];
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", SBMessageRelationships.conversation, conversation]];
                [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:SBMessageAttributes.timestamp
                                                                                 ascending:NO]]];
                [fetchRequest setFetchLimit:1];
                NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
                if ([result count]) {
                    SBMessage *message = [result lastObject];
                    conversation.latest_message = message.timestamp;
                }
                
                // And update the last sync of the conversation. 
                NSNumber *lastUpdate = response[@"last_update"];
                conversation.last_synced = [NSDate dateWithTimeIntervalSince1970:[lastUpdate doubleValue]];
                [self saveContext];
                callback(YES, nil);
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{ callback(NO, error); });
        }
    });
}


- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"blanket" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"blanket.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
                                                           error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
