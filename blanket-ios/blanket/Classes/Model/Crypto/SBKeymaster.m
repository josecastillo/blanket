//
//  BKTKeymaster.m
//  blanket
//
//  Created by Joey Castillo on 7/13/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBKeymaster.h"
#import <Security/Security.h>

@implementation SBKeymaster

#pragma mark General Utilities

+ (void)operationFailedWithStatus:(OSStatus)status {
    NSAssert1(NO, @"Serious error: Keychain status %ld", status);
}

#pragma mark Cryptographic Keys

+ (CFMutableDictionaryRef)newKeyQueryForConversationID:(NSString *)conversationID {
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(kCFAllocatorDefault, 7, NULL, NULL);
    
    // This is a cryprographic key
    CFDictionarySetValue(query, kSecClass, kSecClassKey);
    // Setting as an RSA since this is the only supported value
    CFDictionarySetValue(query, kSecAttrKeyType, kSecAttrKeyTypeRSA);
    // The conversation ID will serve as a tag
    CFDictionarySetValue(query, kSecAttrApplicationTag, (__bridge const void *)(conversationID));
    // Noting that this is a private key.
    CFDictionarySetValue(query, kSecAttrKeyClass, kSecAttrKeyClassPrivate);
    // Ensure that this key is only available when the device is unlocked
    CFDictionarySetValue(query, kSecAttrAccessible, kSecAttrAccessibleWhenUnlocked);
    
    return query;
}

+ (NSDictionary *)secretKeyAttributesForConversationID:(NSString *)conversationID {
    OSStatus status = noErr;
    CFDictionaryRef attributes = nil;
    CFMutableDictionaryRef query = [self newKeyQueryForConversationID:conversationID];
    
    CFDictionarySetValue(query, kSecReturnAttributes, kCFBooleanTrue);
    
    status = SecItemCopyMatching(query, (CFTypeRef *)&attributes);
    
    CFRelease(query);
    
    if (status == noErr) {
        NSDictionary *retVal = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)attributes];
        CFRelease(attributes);
        return retVal;
    }
    
    // errSecItemNotFound is the only expected error code; assert an error for anything else.
    if (status != errSecItemNotFound)
        [self operationFailedWithStatus:status];
    
    return nil;
}

+ (NSData *)secretKeyForConversationID:(NSString *)conversationID {
    OSStatus status = noErr;
    CFDataRef data = nil;
    CFMutableDictionaryRef query = [self newKeyQueryForConversationID:conversationID];
    
    CFDictionarySetValue(query, kSecReturnData, kCFBooleanTrue);
    
    status = SecItemCopyMatching(query, (CFTypeRef *)&data);
    
    CFRelease(query);
    
    if (status == noErr) {
        NSData *retVal = [NSData dataWithData:(__bridge NSData *)(data)];
        CFRelease(data);
        return retVal;
    }
    
    // errSecItemNotFound is the only expected error code; assert an error for anything else.
    if (status != errSecItemNotFound)
        [self operationFailedWithStatus:status];
    
    return nil;
}

+ (BOOL)setSecretKey:(NSData *)secretKey forConversationID:(NSString *)conversationID {
    
    if ([self secretKeyAttributesForConversationID:conversationID])
        NSAssert1(NO, @"Secret key already exists for conversation %@", conversationID);
    
    OSStatus status = noErr;
    CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(kCFAllocatorDefault, 5, NULL, NULL);
    CFDictionaryRef outDictionary = nil;
    
    
    CFDictionarySetValue(attributes, kSecClass, kSecClassKey);
    CFDictionarySetValue(attributes, kSecAttrKeyType, kSecAttrKeyTypeRSA);
    CFDictionarySetValue(attributes, kSecAttrApplicationTag, (__bridge const void *)(conversationID));
    CFDictionarySetValue(attributes, kSecAttrKeyClass, kSecAttrKeyClassPrivate);
    CFDictionarySetValue(attributes, kSecAttrAccessible, kSecAttrAccessibleWhenUnlocked);
    CFDictionarySetValue(attributes, kSecValueData, (__bridge const void *)(secretKey));
    CFDictionarySetValue(attributes, kSecReturnAttributes, kCFBooleanTrue);

    status = SecItemAdd(attributes, (CFTypeRef *)&outDictionary);
    
    CFRelease(attributes);
    
    if (status != noErr)
        [self operationFailedWithStatus:status];

    CFRelease(outDictionary);

    return YES;
}

+ (BOOL)deleteSecretKeyForConversationID:(NSString *)conversationID
{
    OSStatus status = noErr;
    CFMutableDictionaryRef query = [self newKeyQueryForConversationID:conversationID];
    
    status = SecItemDelete(query);
    
    CFRelease(query);
    
    if (status != noErr)
        [self operationFailedWithStatus:status];
    
    return YES;
}

#pragma mark Access Codes

+ (CFMutableDictionaryRef)newCodeQueryForConversationID:(NSString *)conversationID {
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(kCFAllocatorDefault, 7, NULL, NULL);
    
    // This is an internet password
    CFDictionarySetValue(query, kSecClass, kSecClassInternetPassword);
    // The conversation ID will serve as account name
    CFDictionarySetValue(query, kSecAttrAccount, (__bridge const void *)(conversationID));
    // Noting that this password authenticates via HTTP Basic Auth
    CFDictionarySetValue(query, kSecAttrAuthenticationType, kSecAttrAuthenticationTypeHTTPBasic);
    // Ensure that this key is only available when the device is unlocked
    CFDictionarySetValue(query, kSecAttrAccessible, kSecAttrAccessibleWhenUnlocked);
    
    return query;
}

+ (BOOL)setAccessCode:(NSString *)accessCode forConversationID:(NSString *)conversationID {
    if ([self accessCodeAttributesForConversationID:conversationID])
        NSAssert1(NO, @"Access code already exists for conversation %@", conversationID);
    
    OSStatus status = noErr;
    CFMutableDictionaryRef attributes = CFDictionaryCreateMutable(kCFAllocatorDefault, 5, NULL, NULL);
    CFDictionaryRef outDictionary = nil;
    
    
    CFDictionarySetValue(attributes, kSecClass, kSecClassInternetPassword);
    CFDictionarySetValue(attributes, kSecAttrAccount, (__bridge const void *)(conversationID));
    CFDictionarySetValue(attributes, kSecAttrAuthenticationType, kSecAttrAuthenticationTypeHTTPBasic);
    CFDictionarySetValue(attributes, kSecAttrAccessible, kSecAttrAccessibleWhenUnlocked);
    CFDictionarySetValue(attributes, kSecValueData, (__bridge const void *)([accessCode dataUsingEncoding:NSASCIIStringEncoding]));
    CFDictionarySetValue(attributes, kSecReturnAttributes, kCFBooleanTrue);
    
    status = SecItemAdd(attributes, (CFTypeRef *)&outDictionary);
    
    CFRelease(attributes);
    
    if (status != noErr)
        [self operationFailedWithStatus:status];
    
    CFRelease(outDictionary);
    
    return YES;
}

+ (NSDictionary *)accessCodeAttributesForConversationID:(NSString *)conversationID {
    OSStatus status = noErr;
    CFDictionaryRef attributes = nil;
    CFMutableDictionaryRef query = [self newCodeQueryForConversationID:conversationID];
    
    CFDictionarySetValue(query, kSecReturnAttributes, kCFBooleanTrue);
    
    status = SecItemCopyMatching(query, (CFTypeRef *)&attributes);
    
    CFRelease(query);
    
    if (status == noErr) {
        NSDictionary *retVal = [NSDictionary dictionaryWithDictionary:(__bridge NSDictionary *)attributes];
        CFRelease(attributes);
        return retVal;
    }
    
    // errSecItemNotFound is the only expected error code; assert an error for anything else.
    if (status != errSecItemNotFound)
        [self operationFailedWithStatus:status];
    
    return nil;
}

+ (NSString *)accessCodeForConversationID:(NSString *)conversationID {
    OSStatus status = noErr;
    CFDataRef data = nil;
    CFMutableDictionaryRef query = [self newCodeQueryForConversationID:conversationID];
    
    CFDictionarySetValue(query, kSecReturnData, kCFBooleanTrue);
    
    status = SecItemCopyMatching(query, (CFTypeRef *)&data);
    
    CFRelease(query);
    
    if (status == noErr) {
        NSData *encodedAccessCode = [NSData dataWithData:(__bridge NSData *)(data)];
        CFRelease(data);
        NSString *retVal = [[NSString alloc] initWithData:encodedAccessCode
                                                 encoding:NSASCIIStringEncoding];
        return retVal;
    }
    
    // errSecItemNotFound is the only expected error code; assert an error for anything else.
    if (status != errSecItemNotFound)
        [self operationFailedWithStatus:status];
    
    return nil;
}

+ (BOOL)deleteAccessCodeForConversationID:(NSString *)conversationID {
    OSStatus status = noErr;
    CFMutableDictionaryRef query = [self newCodeQueryForConversationID:conversationID];
    
    status = SecItemDelete(query);
    
    CFRelease(query);
    
    if (status != noErr)
        [self operationFailedWithStatus:status];
    
    return YES;
}

@end
