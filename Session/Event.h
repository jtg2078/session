//
//  Event.h
//  Session
//
//  Created by jason on 2/19/13.
//  Copyright (c) 2013 jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Event : NSManagedObject

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * loadTime;

@end
