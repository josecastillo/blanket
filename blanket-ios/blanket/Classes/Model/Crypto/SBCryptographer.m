//
//  BKTCryptographer.m
//  blanket
//
//  Created by Joey Castillo on 7/11/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBCryptographer.h"
#import <CommonCrypto/CommonDigest.h>
#import <sodium.h>

@implementation SBCryptographer

static BOOL __sodiumInitialized;

+ (void)initializeCryptography {
    sodium_init();
    __sodiumInitialized = YES;
}

+ (BOOL)generateKeyPairWithPublicKey:(NSData **)publicKey secretKey:(NSData **)secretKey {
    NSAssert(__sodiumInitialized, @"Crypto subsystem must be initialized before using any cryptography methods.");
    
    unsigned char *public_key = malloc(crypto_box_PUBLICKEYBYTES);
    unsigned char *secret_key = malloc(crypto_box_SECRETKEYBYTES);
    if(0 == crypto_box_keypair(public_key, secret_key)) {
        *publicKey = [NSData dataWithBytesNoCopy:public_key
                                          length:crypto_box_PUBLICKEYBYTES
                                    freeWhenDone:YES];
        *secretKey = [NSData dataWithBytesNoCopy:secret_key
                                          length:crypto_box_SECRETKEYBYTES
                                    freeWhenDone:YES];
        return YES;
    }
    
    return NO;
}

+ (NSData *)encryptMessage:(NSData *)message withPublicKey:(NSData *)publicKey secretKey:(NSData *)secretKey nonce:(NSData *)nonce {
    NSAssert(__sodiumInitialized, @"Crypto subsystem must be initialized before using any cryptography methods.");
    
    NSUInteger messageLength = [message length];
    // Bail out if the message is too short or too long
    if ((!messageLength) || (messageLength > BLANKET_MESSAGE_LENGTH))
        return nil;
    
    // All messages will be 256 bytes long with a 32 byte pad at the beginning for crypto_box
    unsigned char *messageData = malloc(BLANKET_MESSAGE_LENGTH_PADDED);
    // Zero out all memory
    memset(messageData, 0, BLANKET_MESSAGE_LENGTH_PADDED);
    // Copy the message. Either the message is exactly 256 bytes long, or there is a zero at the end of message
    memcpy(messageData + crypto_box_ZEROBYTES, [message bytes], messageLength);
    // We need to pad the message with random bytes if it's too short.
    // 256 characters: Fine; it fills the whole buffer.
    // 255 characters: Fine; with the zero terminator it fills the whole buffer.
    // 254 characters or fewer: need to pad the space after the terminator with random bytes.
    NSUInteger bytesNeeded = BLANKET_MESSAGE_LENGTH - messageLength - 1;
    if (bytesNeeded)
        randombytes(messageData + crypto_box_ZEROBYTES + messageLength + 1, bytesNeeded);

    // Set up an appropriately-sized buffer for receiving the encrypted payload
    unsigned char *encrypted_payload = malloc(BLANKET_MESSAGE_LENGTH_PADDED);
    memset(encrypted_payload, 0, BLANKET_MESSAGE_LENGTH_PADDED);
    
    // Check for the response code to be zero; if so, we succeeded at encrypting the payload.
    if(0 == crypto_box(encrypted_payload, messageData, BLANKET_MESSAGE_LENGTH_PADDED, [nonce bytes], [publicKey bytes], [secretKey bytes])) {
        // Zero out and then free the plaintext message data.
        memset(messageData, 0, BLANKET_MESSAGE_LENGTH_PADDED);
        free(messageData);
        
        // Return the encrypted payload as an NSData object, including the padding bytes.
        NSData *retval = [NSData dataWithBytesNoCopy:encrypted_payload length:BLANKET_MESSAGE_LENGTH_PADDED freeWhenDone:YES];
        return retval;
    } else {
        // Encryption failed; still, zero out and then free the plaintext message data.
        memset(messageData, 0, BLANKET_MESSAGE_LENGTH_PADDED);
        free(messageData);
    }
    
    return nil;
}

+ (NSData *)decryptMessage:(NSData *)message withPublicKey:(NSData *)publicKey secretKey:(NSData *)secretKey nonce:(NSData *)nonce {
    NSAssert(__sodiumInitialized, @"Crypto subsystem must be initialized before using any cryptography methods.");
    
    NSUInteger messageLength = [message length];
    // Bail out if the message is too short or too long
    if ((!messageLength) || (messageLength > BLANKET_MESSAGE_LENGTH_PADDED))
        return nil;
    // Set up an appropriately-sized buffer for receiving the decrypted payload
    unsigned char *decrypted_payload = malloc(BLANKET_MESSAGE_LENGTH_PADDED);
    
    NSData *retVal = nil;
    
    // Check for the response code to be zero; if so, we succeeded at decrypting the payload.
    if (0 == crypto_box_open(decrypted_payload, [message bytes], [message length], [nonce bytes], [publicKey bytes], [secretKey bytes])) {
        
        NSUInteger length = 0;
        for (int i = 0; i < BLANKET_MESSAGE_LENGTH; i++) {
            if (decrypted_payload[crypto_box_ZEROBYTES + i] == 0)
                break;
            else
                length++;
        }
        
        // We have to copy these bytes, as they're a subrange of malloc'ed data
        retVal = [NSData dataWithBytes:(void *)(decrypted_payload + crypto_box_ZEROBYTES)
                                length:length];
        memset(decrypted_payload, 0, BLANKET_MESSAGE_LENGTH_PADDED);
    }
    
    // Now zero out the data and free it.
    free(decrypted_payload);
    
    return retVal;
}

+ (NSData *)getNonce {
    NSAssert(__sodiumInitialized, @"Crypto subsystem must be initialized before using any cryptography methods.");
    
    return [self getRandomBytes:crypto_box_NONCEBYTES];
}

+ (NSData *)getRandomBytes:(const unsigned long long)length {
    NSAssert(__sodiumInitialized, @"Crypto subsystem must be initialized before using any cryptography methods.");
    
    unsigned char *bytes = malloc(length);
    randombytes(bytes, length);
    return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:YES];
}

+ (NSString *)getRandomString:(const unsigned long long)length {
    NSAssert(__sodiumInitialized, @"Crypto subsystem must be initialized before using any cryptography methods.");
    
    unsigned char *bytes = malloc(length);
    randombytes(bytes, length);
    NSString *characters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *retVal = [NSMutableString stringWithCapacity:length];
    for (int i = 0 ; i < length ; i++) {
        int index = bytes[i] % [characters length];
        [retVal appendFormat:@"%c", [characters characterAtIndex:index]];
    }
    free(bytes);
    return [NSString stringWithString:retVal];
}

@end
