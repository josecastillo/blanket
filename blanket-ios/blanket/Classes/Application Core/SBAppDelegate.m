//
//  SBAppDelegate.m
//  blanket
//
//  Created by Joey Castillo on 7/26/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBAppDelegate.h"
#import "SBConversationListViewController.h"
#import "SBCryptographer.h"
#import "SBMessenger.h"
#import <SVProgressHUD.h>

@implementation SBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [SVProgressHUD showWithStatus:NSLocalizedString(@"STATUS_INITIALIZING_CRYPTO", @"Initializing cryptography subsystem")
                             maskType:SVProgressHUDMaskTypeGradient];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [SBCryptographer initializeCryptography];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SBSodiumInitializedNotification object:self];
                [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"STATUS_INITIALIZED_CRYPTO", @"Initialized cryptography subsystem")];
                
                if (![[[NSUserDefaults standardUserDefaults] stringForKey:SBBlanketUsernameKey] length]) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ENTER_YOUR_NAME_TITLE", @"Title for an alert asking for the user's name.")
                                                                    message:NSLocalizedString(@"ENTER_YOUR_NAME_MESSAGE", @"Message for an alert asking for the user's name. Explain that other people will see this name in their app, and that it is only stored locally (never transmitted to the server).")
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:NSLocalizedString(@"OK_BTN", @"Short title for a button"), nil];
                    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                    UITextField *nameField = [alertView textFieldAtIndex:0];
                    nameField.placeholder = NSLocalizedString(@"YOUR_NAME_LABEL", @"Short label for the phrase 'Your Name'; appears next to a field asking for the user's name.");
                    [alertView show];
                }
            });
        });
    });
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex]) {
        UITextField *nameField = [alertView textFieldAtIndex:0];
        [[NSUserDefaults standardUserDefaults] setObject:nameField.text forKey:SBBlanketUsernameKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
