//
//  SBCodeScannerViewController.h
//  blanket
//
//  Created by Joey Castillo on 8/11/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZBarReaderViewController.h"

@interface SBCodeScannerViewController : ZBarReaderViewController <ZBarReaderDelegate>

- (void)proceedToNextStep:(id)sender;
- (void)dismiss:(id)sender;

@property (nonatomic, strong) NSData *alicePublicKey;
@property (nonatomic, strong) NSData *aliceSecretKey;
@property (nonatomic, strong) NSData *bobPublicKey;
@property (nonatomic, strong) NSString *conversationName;
@property (nonatomic, strong) NSString *conversationID;
@property (nonatomic, strong) NSString *accessCode;

@end
