//
//  SBSettingsViewController.m
//  blanket
//
//  Created by Joey Castillo on 8/16/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBSettingsViewController.h"

@interface SBSettingsViewController ()

@end

@implementation SBSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.nameLabel.text = NSLocalizedString(@"YOUR_NAME_LABEL", @"Short label for the phrase 'Your Name'; appears next to a field asking for the user's name.");
    self.nameField.text = [[NSUserDefaults standardUserDefaults] stringForKey:SBBlanketUsernameKey];
}

- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)commit:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:self.nameField.text forKey:SBBlanketUsernameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismiss:sender];
}

- (void)viewDidUnload {
    [self setNameLabel:nil];
    [self setNameField:nil];
    [super viewDidUnload];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 && indexPath.section == 0) {
        [self.nameField becomeFirstResponder];
    }
}
@end
