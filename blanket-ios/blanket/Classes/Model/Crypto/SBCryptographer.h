//
//  BKTCryptographer.h
//  blanket
//
//  Created by Joey Castillo on 7/11/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBCryptographer : NSObject

+ (void)initializeCryptography;

+ (BOOL)generateKeyPairWithPublicKey:(NSData **)publicKey secretKey:(NSData **)secretKey;

+ (NSData *)encryptMessage:(NSData *)message withPublicKey:(NSData *)publicKey secretKey:(NSData *)secretKey nonce:(NSData *)nonce;
+ (NSData *)decryptMessage:(NSData *)message withPublicKey:(NSData *)publicKey secretKey:(NSData *)secretKey nonce:(NSData *)nonce;

+ (NSData *)getNonce;
+ (NSData *)getRandomBytes:(const unsigned long long)length;
+ (NSString *)getRandomString:(const unsigned long long)length;

@end
