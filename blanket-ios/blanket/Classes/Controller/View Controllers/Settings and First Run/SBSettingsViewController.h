//
//  SBSettingsViewController.h
//  blanket
//
//  Created by Joey Castillo on 8/16/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBSettingsViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
- (IBAction)dismiss:(id)sender;
- (IBAction)commit:(id)sender;

@end
