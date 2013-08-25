//
//  SBCodePresentationViewController.m
//  blanket
//
//  Created by Joey Castillo on 8/9/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBCodePresentationViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <QREncoder.h>
#import <SVProgressHUD.h>

#import "SBCryptographer.h"
#import "NSData+Base64.h"
#import "SBCodeScannerViewController.h"
#import "SBMessenger.h"

@interface SBCodePresentationViewController ()

@end

@implementation SBCodePresentationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(dismiss:)];
    self.imageView.layer.magnificationFilter = kCAFilterNearest;
    
    self.nextButton.titleLabel.numberOfLines = 0;
    [self.nextButton setTitle:NSLocalizedString(@"NEXT_STEP_BTN", @"Instructions for getting to the next step from showing code to a partner. ") forState:UIControlStateNormal];
    
    // The purpose of this class is to generate information to send the conversation partner.
    // We send this information as a base64 encoded string, contained in a QR code.
    // The whole point of this next part is to generate that code. 
    UIImage *qrCode = nil;
    
    NSData *alicePublicKey;
    NSData *aliceSecretKey;
    
    if ([SBCryptographer generateKeyPairWithPublicKey:&alicePublicKey secretKey:&aliceSecretKey]) {
        NSString *stringToEncode = nil;
        NSUUID *uuid;
        
        // These are attributes we set ourselves in all cases.
        self.alicePublicKey = alicePublicKey;
        self.aliceSecretKey = aliceSecretKey;
        
        // These are attributes that may be set for us already (if we started by scanning a code).
        if (!self.conversationID) {
            uuid = [[NSUUID alloc] init];
            self.conversationID = [uuid UUIDString];
            self.accessCode = [SBCryptographer getRandomString:BLANKET_ACCESS_CODE_LENGTH];
        } else {
            uuid = [[NSUUID alloc] initWithUUIDString:self.conversationID];
        }
        unsigned char *uuidBytes = malloc(sizeof(uuid_t));
        [uuid getUUIDBytes:uuidBytes];

        // This is an attribute that we never set ourselves; Alice sends her name, and receives Bob's name.
        NSString *outgoingConversationName = [[NSUserDefaults standardUserDefaults] stringForKey:SBBlanketUsernameKey];
        // Edge case, but if for whatever reason we don't have a name set, use the device model as a name.
        if (![outgoingConversationName length])
            outgoingConversationName = [[UIDevice currentDevice] localizedModel];
        
        // Everything's going into a byte buffer, but this is a string.
        // Encoding it as ASCII since getRandomString only returns ASCII characters.
        NSData *accessCodeData = [self.accessCode dataUsingEncoding:NSASCIIStringEncoding];
        
        // Set up the container for the data we're going to send.
        NSUInteger payloadSize = sizeof(uuid_t) + BLANKET_ACCESS_CODE_LENGTH + crypto_box_PUBLICKEYBYTES;
        unsigned char *payloadBytes = malloc(payloadSize);
        
        // First we include the conversation ID, 16 bytes...
        memcpy(payloadBytes, uuidBytes, sizeof(uuid_t));
        // ...followed by the access code, 16 more bytes...
        memcpy(payloadBytes + sizeof(uuid_t), [accessCodeData bytes], BLANKET_ACCESS_CODE_LENGTH);
        // ...followed by our public key, crypto_box_PUBLICKEYBYTES (32) bytes...
        memcpy(payloadBytes + sizeof(uuid_t) + BLANKET_ACCESS_CODE_LENGTH, [alicePublicKey bytes], crypto_box_PUBLICKEYBYTES);
        
        // Finally, wrap it all up in a package. The first four characters represent the version.
        const char version[4] = "SB01";
        NSMutableData *payload = [NSMutableData dataWithBytes:&version length:4];
        // Append the whole payload we just constructed
        [payload appendBytes:payloadBytes length:payloadSize];
        memset(payloadBytes, 0, payloadSize);
        free(payloadBytes);
        // And then append the conversation name. Variable length, UTF-8 encoding.
        // In practice, this cannot exceed 31 bytes to fit in a size 6 QR code.
        // Should probably make this a requirement in the UI somewhere. 
        NSData *conversationNameData = [outgoingConversationName dataUsingEncoding:NSUTF8StringEncoding];
        [payload appendData:conversationNameData];
        
        // Wrap the whole thing up in a base64 string...
        stringToEncode = [payload base64EncodedString];
        
        // ...and create our QR code!
        if (stringToEncode)
            qrCode = [QREncoder encode:stringToEncode
                                  size:6
                       correctionLevel:QRCorrectionLevelLow];
    }
    
    // If that whole process was successful, we're golden.
    if (qrCode) {
        self.imageView.image = qrCode;
    } else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COULD_NOT_GENERATE_CODE_TITLE", @"Title for the code create error dialog")
                                    message:NSLocalizedString(@"COULD_NOT_GENERATE_CODE_TEXT", @"Descriptive text for the code create error dialog")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK_BTN", @"Short title for a button")
                          otherButtonTitles:nil] show];
    }
}

- (IBAction)proceedToNextStep:(id)sender {
    if (!self.bobPublicKey) {
        // If we don't have Bob's key, we're at step 1; we need Bob's code and Bob's name to proceed.
        SBCodeScannerViewController *readerViewController = [[SBCodeScannerViewController alloc] init];
        readerViewController.alicePublicKey = self.alicePublicKey;
        readerViewController.aliceSecretKey = self.aliceSecretKey;
        readerViewController.conversationID = self.conversationID;
        readerViewController.accessCode = self.accessCode;
        // readerViewController will obtain bobPublicKey
        // readerViewController will obtain conversationName
        [self.navigationController pushViewController:readerViewController animated:YES];
    } else {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"STATUS_CREATING_CONVERSATION", @"One-liner for HUD status, 'Creating converastion'")
                             maskType:SVProgressHUDMaskTypeGradient];
        [[SBMessenger defaultMessenger] createConversationWithName:self.conversationName
                                                    conversationID:self.conversationID
                                                        accessCode:self.accessCode
                                                        publicKeyA:self.alicePublicKey
                                                        publicKeyB:self.bobPublicKey
                                                        secretKeyA:self.aliceSecretKey
                                                          callback:
         ^(BOOL success, NSError *error) {
             [SVProgressHUD dismiss];
             if (success) {
                 [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
             } else {
                 [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COULD_NOT_CREATE_CONVERSATION_TITLE", @"Title for the conversation create error dialog")
                                             message:[error localizedDescription]
                                            delegate:nil
                                   cancelButtonTitle:NSLocalizedString(@"OK_BTN", @"Short title for a button")
                                   otherButtonTitles:nil] show];
             }
         }];
    }
}

- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

@end
