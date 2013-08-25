//
//  SBConversationsViewController.h
//  blanket
//
//  Created by Joey Castillo on 7/26/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBConversationListViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
    __strong NSTimer *refreshTimer;
}

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
