//
//  EventCell.m
//  Session
//
//  Created by jason on 2/19/13.
//  Copyright (c) 2013 jason. All rights reserved.
//

#import "EventCell.h"

@implementation EventCell

#pragma mark - init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.opaque = YES;
    }
    
    return self;
}

#pragma mark - class method

+ (CGFloat)heightForText:(NSString *)text
{
    CGFloat height = 0;
    
    height = [text sizeWithFont:[UIFont systemFontOfSize:12]
              constrainedToSize:CGSizeMake(300, 100000)].height;
    
    return height;
}

+ (CGFloat)minCellHeight
{
    return 17;
}

#pragma mark - drawing

- (void)drawContentView:(CGRect)r
{
	// subclasses should implement this
    CGRect rect = CGRectZero;
    CGPoint p = CGPointZero;
    
    // time
    p.x = 10;
    p.y = 2;
    [self.date drawAtPoint:p
                  withFont:[UIFont systemFontOfSize:10]];
    
    // content
    rect.origin.x = 10;
    rect.origin.y = 15;
    rect.size.width = 300;
    rect.size.height = self.contentHeight;
    [self.content drawInRect:rect
                     withFont:[UIFont systemFontOfSize:12]];
}


@end
