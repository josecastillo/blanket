//
//  SBConversationDetailViewController.h
//  blanket
//
//  Created by Joey Castillo on 7/27/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBMessageEntryView.h"

@class SBConversation;

@interface SBConversationDetailViewController : UIViewController <NSFetchedResultsControllerDelegate, SBMessageEntryViewDelegate>

@property (strong, nonatomic) SBConversation *conversation;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet SBMessageEntryView *messageEntryView;

@property (nonatomic, strong) NSMutableSet *decryptedMessages;
@end
