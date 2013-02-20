//
//  ViewController.h
//  Session
//
//  Created by jason on 2/19/13.
//  Copyright (c) 2013 jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIWebViewDelegate, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>
{
    BOOL usingProduction;
}

@property (weak, nonatomic) IBOutlet UIWebView *myWebView;
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (strong, nonatomic) IBOutlet UIView *myHeaderView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *myIndicator;

- (IBAction)home:(id)sender;
- (IBAction)user:(id)sender;
- (IBAction)favor:(id)sender;
- (IBAction)modeChanged:(id)sender;
- (IBAction)clear:(id)sender;

@end
