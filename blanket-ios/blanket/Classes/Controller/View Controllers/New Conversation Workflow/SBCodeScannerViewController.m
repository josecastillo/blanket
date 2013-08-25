//
//  SBCodeScannerViewController.m
//  blanket
//
//  Created by Joey Castillo on 8/11/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBCodeScannerViewController.h"
#import "SBCodePresentationViewController.h"
#import "SBMessenger.h"
#import "NSData+Base64.h"
#import <SVProgressHUD.h>

@interface SBCodeScannerViewController ()

@end

@implementation SBCodeScannerViewController

- (id)init {
    self = [super init];
    if (self) {
        self.readerDelegate = self;
        self.supportedOrientationsMask = ZBarOrientationMaskAll;
        [self.scanner setSymbology:0
                            config:ZBAR_CFG_ENABLE
                                to:0];
        [self.scanner setSymbology:ZBAR_QRCODE
                            config:ZBAR_CFG_ENABLE
                                to:1];
        self.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        self.showsZBarControls = NO;
        self.wantsFullScreenLayout = NO;
    }
    return self;
}

- (void)viewDidLoad {
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(dismiss:)];
    [super viewDidLoad];
}

- (void) imagePickerController:(UIImagePickerController *)reader didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
    for(ZBarSymbol *symbol in results) {
        NSUInteger payloadSize = sizeof(uuid_t) + BLANKET_ACCESS_CODE_LENGTH + crypto_box_PUBLICKEYBYTES;
        
        NSData *data = [NSData dataFromBase64String:symbol.data];
        NSString *version = nil;
        
        // Check that the data is long enough to contain 4 character version tag, payload and at least one character of conversation name.
        if ([data length] > 4 + payloadSize)
            version = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 4)]
                                            encoding:NSASCIIStringEncoding];
        if ([version isEqualToString:@"SB01"]) {
            NSData *payloadData = [data subdataWithRange:NSMakeRange(4, payloadSize)];
            NSData *conversationNameData = [data subdataWithRange:NSMakeRange(4 + payloadSize, [data length] -payloadSize - 4)];
            const void *payloadBytes = [payloadData bytes];
            NSUInteger offset = 0;
            
            // Get the conversation's UUID
            const unsigned char *uuidBytes = malloc(sizeof(uuid_t));
            uuidBytes = memcpy((void *)uuidBytes, payloadBytes, sizeof(uuid_t));
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:uuidBytes];
            NSString *conversationID = [uuid UUIDString];
            if (self.conversationID) {
                if (![self.conversationID isEqualToString:conversationID]) {
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COULD_NOT_CREATE_CONVERSATION_TITLE", @"Title for the conversation create error dialog")
                                                message:NSLocalizedString(@"CONVERSATION_ID_MISMATCH_MESSAGE", @"Message for when a scanned conversation ID does not match the ID generated in step 1")
                                               delegate:nil
                                      cancelButtonTitle:NSLocalizedString(@"OK_BTN", @"Short title for a button")
                                      otherButtonTitles:nil] show];
                    return;
                }
            } else {
                self.conversationID = conversationID;
            }
            offset += sizeof(uuid_t);
            
            // Get the access code
            NSString *accessCode = [[NSString alloc] initWithBytes:payloadBytes + offset
                                                            length:BLANKET_ACCESS_CODE_LENGTH
                                                          encoding:NSASCIIStringEncoding];
            if (self.accessCode) {
                if (![self.accessCode isEqualToString:accessCode]) {
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COULD_NOT_CREATE_CONVERSATION_TITLE", @"Title for the conversation create error dialog")
                                                message:NSLocalizedString(@"ACCESS_CODE_MISMATCH_MESSAGE", @"Message for when a scanned access code does not match the access code generated in step 1")
                                               delegate:nil
                                      cancelButtonTitle:NSLocalizedString(@"OK_BTN", @"Short title for a button")
                                      otherButtonTitles:nil] show];
                    return;
                }
            } else {
                self.accessCode = accessCode;
            }
            offset += BLANKET_ACCESS_CODE_LENGTH;
            
            // Get Bob's public key
            self.bobPublicKey = [NSData dataWithBytes:payloadBytes + offset
                                               length:crypto_box_PUBLICKEYBYTES];
            
            // Get Bob's name for the conversation title
            self.conversationName = [[NSString alloc] initWithData:conversationNameData
                                                          encoding:NSUTF8StringEncoding];
            
            // If we got all that data, we're good to go. 
            if (self.accessCode && self.bobPublicKey && self.conversationName) {
                [self proceedToNextStep:self];
                break;
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COULD_NOT_CREATE_CONVERSATION_TITLE", @"Title for the conversation create error dialog")
                                        message:NSLocalizedString(@"INVALID_CODE_MESSAGE", @"Message for when a scanned QR code is invalid for any reason")
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK_BTN", @"Short title for a button")
                              otherButtonTitles:nil] show];
        }
    }
}

- (void)dismiss:(id)sender {
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

- (void)proceedToNextStep:(id)sender {
    if (!self.alicePublicKey) {
        // If we haven't generated our public key yet, we will need to do that first.
        SBCodePresentationViewController *destinationViewController = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"SBCodePresentationViewController"];
        destinationViewController.conversationID = self.conversationID;
        destinationViewController.accessCode = self.accessCode;
        destinationViewController.bobPublicKey = self.bobPublicKey;
        destinationViewController.conversationName = self.conversationName;
        
        [self.navigationController pushViewController:destinationViewController animated:YES];
    } else {
        // We should have all the information we need. 
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

@end
