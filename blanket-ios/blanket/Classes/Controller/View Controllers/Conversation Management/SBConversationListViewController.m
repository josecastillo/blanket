//
//  SBConversationsViewController.m
//  blanket
//
//  Created by Joey Castillo on 7/26/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBConversationListViewController.h"
#import "SBConversationDetailViewController.h"
#import "NSData+Base64.h"
#import "SBCryptographer.h"
#import "SBKeymaster.h"
#import "SBMessenger.h"
#import <TTTTimeIntervalFormatter.h>

@interface SBConversationListViewController ()

@end

@implementation SBConversationListViewController

static __strong TTTTimeIntervalFormatter *timeFormatter;

+ (void)initialize {
    timeFormatter = [[TTTTimeIntervalFormatter alloc] init];
    timeFormatter.leastSignificantUnit = NSMinuteCalendarUnit;
}

#pragma mark - Custom logic

- (void)refreshAllConversations {
    id <NSFetchedResultsSectionInfo> section = [self.fetchedResultsController.sections lastObject];
    NSArray *conversations = [section objects];
    for (SBConversation *conversation in conversations) {
        [[SBMessenger defaultMessenger] refreshConversation:conversation callback:^(BOOL success, NSError *error) {CFRunLoopStop(CFRunLoopGetCurrent());}];
        CFRunLoopRun();
    }
}

#pragma mark - View lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserverForName:SBSodiumInitializedNotification
                                                          object:[[UIApplication sharedApplication] delegate]
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:
         ^(NSNotification *note) {
             self.managedObjectContext = [[SBMessenger defaultMessenger] managedObjectContext];
             self.navigationItem.rightBarButtonItem.enabled = YES;
             self.navigationItem.leftBarButtonItem.enabled = YES;
             [self.tableView reloadData];
             [self performSelector:@selector(refreshAllConversations) withObject:nil afterDelay:.1];
         }];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:
         ^(NSNotification *note) {
             // Fetch new convo data from server
             if (self.managedObjectContext)
                 [self refreshAllConversations];
             
             // Set up timer to refresh timestamps
             NSMethodSignature *methodSignature = [UITableView instanceMethodSignatureForSelector:@selector(reloadData)];
             NSInvocation *reloadDataInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
             [reloadDataInvocation setTarget:self.tableView];
             [reloadDataInvocation setSelector:@selector(reloadData)];
             refreshTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                         invocation:reloadDataInvocation
                                                            repeats:YES];
         }];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:
         ^(NSNotification *note) {
             [refreshTimer invalidate];
             refreshTimer = nil;
         }];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"HOMEPAGE_TITLE", @"Title for the Blanket main page");
    self.navigationItem.leftBarButtonItem.title = NSLocalizedString(@"SETTINGS_BTN", @"Short, button title for settings");
    self.navigationItem.rightBarButtonItem.accessibilityLabel = NSLocalizedString(@"NEW_CONVO_BTN", @"Short, button title for 'Create new conversation'");
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    SBConversation *conversation = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = conversation.name;
    NSTimeInterval secondsSinceLastUpdate = [conversation.last_synced timeIntervalSinceDate:[NSDate date]];
    // Server time can differ from local time; to prevent lines like 'two seconds from now' we round all positive values to zero.
    if (secondsSinceLastUpdate > 0)
        secondsSinceLastUpdate = 0;
    cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"LAST_UPDATE_STRING_FORMAT", @"The phrase 'Updated [just now|3 hours ago|2 days ago]', no trailing punctuation. Time interval is automatically localized."), [timeFormatter stringForTimeInterval:secondsSinceLastUpdate]];
    cell.imageView.hidden = !conversation.unreadValue;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SBConversation *conversation = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [[SBMessenger defaultMessenger] destroyConversation:conversation
                                                   callback:
         ^(BOOL success, NSError *error) {
             if (!success) {
                 [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COULD_NOT_DELETE_CONVERSATION_TITLE", @"Title for the conversation delete error dialog")
                                             message:[error localizedDescription]
                                            delegate:nil
                                   cancelButtonTitle:NSLocalizedString(@"OK_BTN", @"Short title for a button")
                                   otherButtonTitles:nil] show];
             }
         }];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
        return _fetchedResultsController;
    
    if (!self.managedObjectContext)
        return nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:[SBConversation entityName]
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:SBConversationAttributes.latest_message
                                                                   ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark Storyboard

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SBConversationDetailSegue"]) {
        SBConversationDetailViewController *destinationViewController = (SBConversationDetailViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        destinationViewController.conversation = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
}

@end
