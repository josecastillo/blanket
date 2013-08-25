//
//  BKTKeymaster.h
//  blanket
//
//  Created by Joey Castillo on 7/13/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBKeymaster : NSObject

+ (BOOL)setSecretKey:(NSData *)secretKey forConversationID:(NSString *)conversationID;
+ (BOOL)deleteSecretKeyForConversationID:(NSString *)conversationID;
+ (NSDictionary *)secretKeyAttributesForConversationID:(NSString *)conversationID;
+ (NSData *)secretKeyForConversationID:(NSString *)conversationID;

+ (BOOL)setAccessCode:(NSString *)accessCode forConversationID:(NSString *)conversationID;
+ (BOOL)deleteAccessCodeForConversationID:(NSString *)conversationID;
+ (NSDictionary *)accessCodeAttributesForConversationID:(NSString *)conversationID;
+ (NSString *)accessCodeForConversationID:(NSString *)conversationID;


@end
