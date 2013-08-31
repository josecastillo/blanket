//
//  SBMessageEntryView.m
//  blanket
//
//  Created by Joey Castillo on 7/29/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBMessageEntryView.h"

@implementation SBMessageEntryView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        textView = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(6, 3, 240, 40)];
        textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
        
        textView.minNumberOfLines = 1;
        textView.maxNumberOfLines = 6;
        // you can also set the maximum height in points with maxHeight
        // textView.maxHeight = 200.0f;
        textView.returnKeyType = UIReturnKeyGo; //just as an example
        textView.font = [UIFont systemFontOfSize:15.0f];
        textView.delegate = self;
        textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        textView.backgroundColor = [UIColor whiteColor];

        UIImage *rawEntryBackground = [UIImage imageNamed:@"MessageEntryInputField.png"];
        UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
        UIImageView *entryImageView = [[UIImageView alloc] initWithImage:entryBackground];
        entryImageView.frame = CGRectMake(5, 0, 248, 40);
        entryImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        UIImage *rawBackground = [UIImage imageNamed:@"MessageEntryBackground.png"];
        UIImage *background = [rawBackground stretchableImageWithLeftCapWidth:13 topCapHeight:22];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:background];
        imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        // view hierachy
        [self addSubview:imageView];
        [self addSubview:textView];
        [self addSubview:entryImageView];
        
        UIImage *sendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
        UIImage *selectedSendBtnBackground = [[UIImage imageNamed:@"MessageEntrySendButton.png"] stretchableImageWithLeftCapWidth:13 topCapHeight:0];
        
        UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        doneBtn.frame = CGRectMake(self.frame.size.width - 69, 8, 63, 27);
        doneBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
        [doneBtn setTitle:NSLocalizedString(@"SEND_BTN", @"Send, verb, short title for a button") forState:UIControlStateNormal];
        
        [doneBtn setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.4] forState:UIControlStateNormal];
        doneBtn.titleLabel.shadowOffset = CGSizeMake (0.0, -1.0);
        doneBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        
        [doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [doneBtn setBackgroundImage:sendBtnBackground forState:UIControlStateNormal];
        [doneBtn setBackgroundImage:selectedSendBtnBackground forState:UIControlStateSelected];
        
        [doneBtn addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:doneBtn];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    return self;
}

#pragma mark - Received actions

- (void)sendButtonPressed:(id)sender {
    [textView resignFirstResponder];
    if ([self.delegate respondsToSelector:@selector(messageEntryView:submittedMessage:)])
        [self.delegate messageEntryView:self submittedMessage:[textView.text dataUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark - Growing text view delegate

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView
shouldChangeTextInRange:(NSRange)range
        replacementText:(NSString *)text {
#warning Working around a bug in growing text view; this use case should be handled in growingTextViewShouldReturn. Need to fix this in HPGrowingTextView and submit a pull request.
    if ([text isEqualToString:@"\n"])
        return [self growingTextViewShouldReturn:growingTextView];
    NSString *newString = [growingTextView.text stringByReplacingCharactersInRange:range withString:text];
    NSUInteger length = [newString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    return length <= BLANKET_MESSAGE_LENGTH;
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView
       willChangeHeight:(float)height {
    float diff = (growingTextView.frame.size.height - height);
    
	CGRect r = self.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	self.frame = r;
}

- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)growingTextView {
    [self sendButtonPressed:growingTextView];
    return NO;
}

- (void)clearTextField
{
    textView.text = nil;
}

@end