//
//  SBRestClient.h
//  blanket
//
//  Created by Joey Castillo on 8/7/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBWebServiceClient : NSObject

+ (SBWebServiceClient *)defaultClient;
- (NSDictionary *)openChannelWithConversationID:(NSString *)conversationID
                                     accessCode:(NSString *)accessCode
                                          error:(NSError **)error;

- (NSDictionary *)closeChannelWithConversationID:(NSString *)conversationID
                                      accessCode:(NSString *)accessCode
                                           error:(NSError **)error;

- (NSDictionary *)channelStatusForConversationID:(NSString *)conversationID
                                      accessCode:(NSString *)accessCode
                                           error:(NSError **)error;

- (NSDictionary *)messagesForConversationID:(NSString *)conversationID
                                 accessCode:(NSString *)accessCode
                                      since:(NSTimeInterval)since
                                      error:(NSError **)error;

- (NSDictionary *)postMessage:(NSData *)message
                    withNonce:(NSData *)nonce
         toConversationWithID:(NSString *)conversationID
                   accessCode:(NSString *)accessCode
                        error:(NSError **)error;

@end
