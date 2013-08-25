//
//  SBCodePresentationViewController.h
//  blanket
//
//  Created by Joey Castillo on 8/9/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBCodePresentationViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIButton *nextButton;

- (IBAction)proceedToNextStep:(id)sender;
- (IBAction)dismiss:(id)sender;

@property (nonatomic, strong) NSData *alicePublicKey;
@property (nonatomic, strong) NSData *aliceSecretKey;
@property (nonatomic, strong) NSData *bobPublicKey;
@property (nonatomic, strong) NSString *conversationName;
@property (nonatomic, strong) NSString *conversationID;
@property (nonatomic, strong) NSString *accessCode;
@end
