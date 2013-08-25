//
//  constants.h
//  blanket
//
//  Created by Joey Castillo on 7/29/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#ifndef blanket_constants_h
#define blanket_constants_h

#import <sodium.h>

// NSUserDefaults key for username
#define SBBlanketUsernameKey @"SBBlanketUsernameKey"

// Notification for startup; do not call any sodium functions until this notification has posted.
#define SBSodiumInitializedNotification @"SBSodiumInitializedNotification"

// Constants related to the Blanket network protocol. Messages are 256 characters in length. Padded messages have a crypto_box_ZEROBYTES pad at the beginning
#define BLANKET_MESSAGE_LENGTH 256
#define BLANKET_MESSAGE_LENGTH_PADDED (BLANKET_MESSAGE_LENGTH + crypto_box_ZEROBYTES)
// Access codes are 16 ASCII characters in length
#define BLANKET_ACCESS_CODE_LENGTH 16

#endif
