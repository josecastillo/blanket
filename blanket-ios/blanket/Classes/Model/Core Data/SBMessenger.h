//
//  BKTDataSource.h
//  blanket
//
//  Created by Joey Castillo on 7/16/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBConversation.h"
#import "SBMessage.h"

@interface SBMessenger : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (SBMessenger *)defaultMessenger;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (NSString *)plainTextForMessage:(SBMessage *)message;

- (void)createConversationWithName:(NSString *)name
                    conversationID:(NSString *)conversationID
                        accessCode:(NSString *)accessCode
                        publicKeyA:(NSData *)alicePublicKey
                        publicKeyB:(NSData *)bobPublicKey
                        secretKeyA:(NSData *)aliceSecretKey
                          callback:(void(^)(BOOL success, NSError *error))callback;

- (void)conversationExistsWithConversationID:(NSString *)name
                                  accessCode:(NSString *)accessCode
                                    callback:(void(^)(BOOL success, NSError *error))callback;

- (void)destroyConversation:(SBConversation *)conversation
                   callback:(void(^)(BOOL success, NSError *error))callback;

- (void)postMessageData:(NSData *)messageData
         toConversation:(SBConversation *)conversation
               callback:(void(^)(BOOL success, NSError *error))callback;

- (void)refreshConversation:(SBConversation *)conversation
                   callback:(void(^)(BOOL success, NSError *error))callback;

@end
