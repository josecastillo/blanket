//
//  SBMessageEntryView.h
//  blanket
//
//  Created by Joey Castillo on 7/29/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"

@class SBMessageEntryView;

@protocol SBMessageEntryViewDelegate <NSObject>
- (void)messageEntryView:(SBMessageEntryView *)messageEntryView submittedMessage:(NSData *)messageData;
@end

@interface SBMessageEntryView : UIView <HPGrowingTextViewDelegate> {
    HPGrowingTextView *textView;
    UIButton *sendButton;
}

@property (nonatomic, weak) IBOutlet id <SBMessageEntryViewDelegate> delegate;
- (void)clearTextField;

@end
