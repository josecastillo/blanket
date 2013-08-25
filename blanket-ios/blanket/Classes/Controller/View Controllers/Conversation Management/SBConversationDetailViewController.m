//
//  SBConversationDetailViewController.m
//  blanket
//
//  Created by Joey Castillo on 7/27/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBConversationDetailViewController.h"
#import "SBMessenger.h"
#import "SBCryptographer.h"
#import "SBKeymaster.h"
#import <SVProgressHUD.h>
#import <NSData+Base64.h>

@interface SBConversationDetailViewController ()

@end

@implementation SBConversationDetailViewController

static NSDateFormatter *dateFormatter;

+ (void)initialize {
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDoesRelativeDateFormatting:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                           target:self
                                                                           action:@selector(refreshMessages:)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                           target:self
                                                                           action:@selector(clearMessages:)];
    self.navigationItem.rightBarButtonItems = @[item1, item2];
    self.navigationItem.title = self.conversation.name;
    self.decryptedMessages = [[NSMutableSet alloc] init];
}

- (void)refreshMessages:(id)sender {
    [[SBMessenger defaultMessenger] refreshConversation:self.conversation
                                            callback:
     ^(BOOL success, NSError *error) {
         if (!success)
             [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COULD_NOT_REFRESH_TITLE", @"Title for the refresh error dialog")
                                         message:[error localizedDescription]
                                        delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"OK_BTN", @"Short title for a button")
                               otherButtonTitles:nil] show];
     }];
}

- (void)clearMessages:(id)sender {
    [self.conversation.messagesSet removeAllObjects];
    [[SBMessenger defaultMessenger] saveContext];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification 
                                               object:nil];
    
    [self scrollToBottomAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];

    for (SBMessage *message in self.decryptedMessages) {
        message.decryptedText = nil;
        message.rowHeight = 0.0f;
    }
    [self.decryptedMessages removeAllObjects];

    self.conversation.unread = @NO;
    [[SBMessenger defaultMessenger] saveContext];
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

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    SBMessage *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *messageText = [message.data base64EncodedStringWithSeparateLines:NO];// [[SBMessenger defaultMessenger] plainTextForMessage:message];
    
    // Set text data
    if (message.decryptedText) {
        cell.textLabel.text = message.decryptedText;
        cell.textLabel.textColor = [UIColor blackColor];
    } else {
        cell.textLabel.text = NSLocalizedString(@"MESSAGE_TAP_TO_DECRYPT", @"Touch this message to decrypt it.");
        cell.textLabel.textColor = [UIColor blueColor];
    }
    cell.detailTextLabel.text = [dateFormatter stringFromDate:message.timestamp];
    
    // Set text appearance
    if (message.incomingValue)
        cell.textLabel.textAlignment = cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    else
        cell.textLabel.textAlignment = cell.detailTextLabel.textAlignment = NSTextAlignmentRight;
    
    // This shouldn't happen, but if for whatever reason the message failed to decrypt, the timestamp label will be red and there'll be no text (a shortened row in the table)
    if (messageText)
        cell.detailTextLabel.textColor = [UIColor grayColor];
    else
        cell.detailTextLabel.textColor = [UIColor redColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SBMessage *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (message.rowHeight > 44)
        return message.rowHeight;
    return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.conversation.managedObjectContext deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        [[SBMessenger defaultMessenger] saveContext];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SBMessage *message = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (!message.decryptedText) {
        message.decryptedText = [[SBMessenger defaultMessenger] plainTextForMessage:message];
        CGSize textSize = [message.decryptedText sizeWithFont:[UIFont systemFontOfSize:18.0]
                                            constrainedToSize:CGSizeMake(300.0, CGFLOAT_MAX)
                                                lineBreakMode:NSLineBreakByCharWrapping];
        message.rowHeight = textSize.height + 20;

        [self.decryptedMessages addObject:message];

        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    NSInteger lastSection = [self.tableView numberOfSections] - 1;
    NSInteger lastRow = [self.tableView numberOfRowsInSection:lastSection] - 1;
    if (lastRow >= 0)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:lastSection]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:animated];
}

#pragma mark - Moving around the send box

-(void) keyboardWillShow:(NSNotification *)note{
    CGRect keyboardBounds = [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [[note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect frame = self.messageEntryView.frame;
    
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    frame.origin.y = self.view.bounds.size.height - (keyboardBounds.size.height + frame.size.height);
    
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]))
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardBounds.size.height), 0.0);
    else
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardBounds.size.width), 0.0);

    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | (curve << 16)
                     animations:^{
                         self.messageEntryView.frame = frame;
                         self.tableView.contentInset = contentInsets;
                         self.tableView.scrollIndicatorInsets = contentInsets;
                         [self scrollToBottomAnimated:NO];
                     }
                     completion:nil];
}

-(void) keyboardWillHide:(NSNotification *)note{
    NSTimeInterval duration = [[note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger curve = [[note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    CGRect frame = self.messageEntryView.frame;
    frame.origin.y = self.view.bounds.size.height - frame.size.height;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | (curve << 16)
                     animations:^{
                         self.messageEntryView.frame = frame;
                         self.tableView.contentInset = UIEdgeInsetsZero;
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
                     }
                     completion:nil];
}

- (void)viewDidUnload {
    [self setMessageEntryView:nil];
    [super viewDidUnload];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
        return _fetchedResultsController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:[SBMessage entityName]
                                              inManagedObjectContext:self.conversation.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:SBMessageAttributes.timestamp
                                                                   ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSPredicate *predicate = [NSComparisonPredicate predicateWithFormat:@"%K == %@", SBMessageRelationships.conversation, self.conversation];
    [fetchRequest setPredicate:predicate];
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.conversation.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
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

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
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
      newIndexPath:(NSIndexPath *)newIndexPath {
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - Sending messages

- (void)messageEntryView:(SBMessageEntryView *)messageEntryView submittedMessage:(NSData *)messageData {
    [SVProgressHUD showWithStatus:NSLocalizedString(@"STATUS_SENDING_MESSAGE", @"Sending message...")
                         maskType:SVProgressHUDMaskTypeGradient];
    [[SBMessenger defaultMessenger] postMessageData:messageData
                                  toConversation:self.conversation
                                        callback:
     ^(BOOL success, NSError *error) {
         [SVProgressHUD dismiss];
         if (success) {
             [messageEntryView clearTextField];
             [self scrollToBottomAnimated:NO];
         } else {
             [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"COULD_NOT_SEND_TITLE", @"Title for the send error dialog")
                                         message:[error localizedDescription]
                                        delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"OK_BTN", @"Short title for a button")
                               otherButtonTitles:nil] show];
         }
     }];
}

@end
