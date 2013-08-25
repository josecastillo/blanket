//
//  SBMessageTableViewCell.m
//  blanket
//
//  Created by Joey Castillo on 8/6/13.
//  Copyright (c) 2013 Panchromatic, LLC. All rights reserved.
//

#import "SBMessageTableViewCell.h"

@implementation SBMessageTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame;
    
    frame = self.textLabel.frame;
    frame.size.width = 300;
    self.textLabel.frame = frame;
    
    frame = self.detailTextLabel.frame;
    frame.size.width = 300;
    self.detailTextLabel.frame = frame;
}

@end
