//
//  SBCreateConversationStartViewController.m
//  blanket
//
//  Created by Joey Castillo on 8/9/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBCreateConversationStartViewController.h"
#import "SBCodePresentationViewController.h"
#import "SBCodeScannerViewController.h"

@interface SBCreateConversationStartViewController ()

@end

@implementation SBCreateConversationStartViewController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"NEW_CONVERSATION_GENERATE_CODE_STEP", @"The phrase 'Start by generating a code'");
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"NEW_CONVERSATION_SCAN_CODE_STEP", @"The phrase 'Start by scanning a code'");
            break;
            
        default:
            cell.textLabel.text = nil;
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return NSLocalizedString(@"NEW_CONVERSATION_PROMPT_HEADER", @"The phrase 'How do you want to start this conversation?'");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return NSLocalizedString(@"NEW_CONVERSATION_PROMPT_FOOTER", @"The phrase 'You must be in the same physical location as your conversation partner in order to start a conversation with Blanket. One of you should start by generating a code, and the other should start by scanning that code.'");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
        {
            SBCodePresentationViewController *destinationViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SBCodePresentationViewController"];
            [self.navigationController pushViewController:destinationViewController animated:YES];
        }
            break;
        case 1:
        {
            SBCodeScannerViewController *destinationViewController = [[SBCodeScannerViewController alloc] init];
            [self.navigationController pushViewController:destinationViewController animated:YES];
        }
            break;
        default:
            break;
    }
}

- (IBAction)dismiss:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
