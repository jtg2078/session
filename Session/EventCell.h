//
//  EventCell.h
//  Session
//
//  Created by jason on 2/19/13.
//  Copyright (c) 2013 jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FastCell.h"

@interface EventCell : FastCell

@property (nonatomic, retain) NSString * date;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, assign) CGFloat contentHeight;

+ (CGFloat)heightForText:(NSString *)text;
+ (CGFloat)minCellHeight;

@end
