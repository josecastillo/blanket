//
//  SBRestClient.m
//  blanket
//
//  Created by Joey Castillo on 8/7/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBWebServiceClient.h"
#import "NSData+Base64.h"

@implementation SBWebServiceClient

static NSString *protocol = @"https";
static NSString *host = @"blanket.herokuapp.com";
static NSString *version = @"v1";

static SBWebServiceClient *instance;

+ (SBWebServiceClient *)defaultClient {
    if (!instance) {
        instance = [[SBWebServiceClient alloc] init];
    }
    return instance;
}

- (NSURL *)urlForEndpoint:(NSString *)endpoint username:(NSString *)username password:(NSString *)password {
    NSString *urlString;
    urlString = [NSString stringWithFormat:@"%@://%@:%@@%@/%@/%@", protocol, username, password, host, version, endpoint];
    return [NSURL URLWithString:urlString];
}

- (NSDictionary *)executeRequestForUrl:(NSURL *)url postBody:(NSData *)postData error:(NSError **)error {
    // Set up our return value
    NSDictionary *retVal = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10.0];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    if (postData) {
        request.HTTPBody = postData;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    
    // Just logging the request
    {
        id thing = nil;
        if (postData)
            thing = [NSJSONSerialization JSONObjectWithData:postData options:0 error:NULL];
    }
    // Execute the request
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:error];
    if (data) {
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data
                                                               options:0
                                                                 error:error];
        if (result) {
            NSLog(@"%@", result);
            if ([result[@"success"] boolValue]) {
                retVal = result[@"payload"];
            } else {
                *error = [NSError errorWithDomain:@"SBBlanketDomain"
                                             code:-1
                                         userInfo:@{ NSLocalizedDescriptionKey : [[NSBundle mainBundle] localizedStringForKey:result[@"error"] value:@"" table:nil] }];
            }
        }
    }
    
    return retVal;
}

- (NSDictionary *)openChannelWithConversationID:(NSString *)conversationID
                                     accessCode:(NSString *)accessCode
                                          error:(NSError **)error {

    NSURL *url = [self urlForEndpoint:@"channel/open" username:conversationID password:accessCode];
    return [self executeRequestForUrl:url postBody:nil error:error];
}

- (NSDictionary *)closeChannelWithConversationID:(NSString *)conversationID
                                      accessCode:(NSString *)accessCode
                                           error:(NSError **)error {

    NSURL *url = [self urlForEndpoint:@"channel/close" username:conversationID password:accessCode];
    
    return [self executeRequestForUrl:url postBody:nil error:error];
}

- (NSDictionary *)channelStatusForConversationID:(NSString *)conversationID
                                      accessCode:(NSString *)accessCode
                                           error:(NSError **)error {

    NSURL *url = [self urlForEndpoint:@"channel" username:conversationID password:accessCode];

    return [self executeRequestForUrl:url postBody:nil error:error];
}

- (NSDictionary *)messagesForConversationID:(NSString *)conversationID
                                 accessCode:(NSString *)accessCode
                                      since:(NSTimeInterval)since
                                      error:(NSError **)error {
    
    NSURL *url = [self urlForEndpoint:@"message" username:conversationID password:accessCode];
    NSDictionary *parameters = @{@"since" : [NSNumber numberWithDouble:since] };
    NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:error];

    if (!postData)
        return nil;
    
    return [self executeRequestForUrl:url postBody:postData error:error];
}

- (NSDictionary *)postMessage:(NSData *)message
                    withNonce:(NSData *)nonce
         toConversationWithID:(NSString *)conversationID
                   accessCode:(NSString *)accessCode
                        error:(NSError **)error {

    NSURL *url = [self urlForEndpoint:@"message/create" username:conversationID password:accessCode];
    NSDictionary *parameters = @{@"message" : [message base64EncodedString], @"nonce" : [nonce base64EncodedString] };
    NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:error];
    
    if (!postData)
        return nil;
    
    return [self executeRequestForUrl:url postBody:postData error:error];
}


@end
