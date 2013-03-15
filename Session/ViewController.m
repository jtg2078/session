//
//  ViewController.m
//  Session
//
//  Created by jason on 2/19/13.
//  Copyright (c) 2013 jason. All rights reserved.
//

#import "ViewController.h"
#import "Event.h"
#import "AppDelegate.h"
#import "EventCell.h"

@interface ViewController ()
@property (nonatomic, strong) NSFetchedResultsController *frc;
@property (nonatomic, weak) NSManagedObjectContext *context;
@property (nonatomic, strong) NSDateFormatter *df;
@property (nonatomic, strong) Event *currentEvent;
@property (nonatomic, assign) CFAbsoluteTime currentEventStartTime;
@end

@implementation ViewController

#pragma mark - memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// misc
    usingProduction = YES;
    [self home:nil];
    
    self.df = [[NSDateFormatter alloc] init];
    [self.df setDateFormat:@"M/dd a h:mm"];
    
    // table view
    [self.myTableView registerClass:[EventCell class] forCellReuseIdentifier:@"EventCell"];
    self.myTableView.tableFooterView = self.myHeaderView;
    
    // others
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.context = delegate.managedObjectContext;
    
    // feteched results controller
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Event"
                                 inManagedObjectContext:self.context];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp"
                                                              ascending:NO]];
    
    self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                   managedObjectContext:self.context
                                                     sectionNameKeyPath:nil
                                                              cacheName:nil];
    self.frc.delegate = self;
    [self.frc performFetch:nil];
}

#pragma mark - user interaction

- (IBAction)home:(id)sender
{
    [self loadRelativePath:@""];
}

- (IBAction)user:(id)sender
{
    [self loadRelativePath:@"/user"];
}

- (IBAction)favor:(id)sender
{
    //[self loadRelativePath:@"/favorite"];
    
    [self.myWebView stringByEvaluatingJavaScriptFromString:
     @"var username = document.getElementsByName('username')[0];"
     "username.value='a25339306';"
     "var userpassword = document.getElementsByName('password')[0];"
     "userpassword.value='a19841019';"];
    
}

- (IBAction)modeChanged:(id)sender
{
    UISegmentedControl *c = (UISegmentedControl *)sender;
    usingProduction = c.selectedSegmentIndex == 0;
}

- (IBAction)clear:(id)sender
{
    NSArray *logs = nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"Event"
                                 inManagedObjectContext:self.context];
    request.includesPendingChanges = YES;
    
    NSError *error = nil;
    logs = [self.context executeFetchRequest:request error:&error];
    
    if(error == nil)
    {
        for(NSManagedObject *log in logs)
        {
            [self.context deleteObject:log];
        }
        
        [self.context save:&error];
    }
}

#pragma mark - helper methods

- (void)loadRelativePath:(NSString *)path
{
    NSString *root = usingProduction ? @"http://pda4.msg.nat.gov.tw/" :
        @"http://emsgmobile.test.demo2.miniasp.com.tw/";

    NSURL *url = [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:root]];
    
    [self.myWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)logEvent:(NSString *)content
{
    CGFloat height = [EventCell heightForText:content];
    
    Event *e = [NSEntityDescription insertNewObjectForEntityForName:@"Event"
                                             inManagedObjectContext:self.context];
    e.content = content;
    e.timestamp = [NSDate date];
    e.height = @(height);
    
    NSError *error = nil;
    [self.context save:&error];
    
    if(error)
        NSLog(@"error while saving Event: %@", error.description);
    
    self.currentEventStartTime = CFAbsoluteTimeGetCurrent();
    self.currentEvent = e;
}

- (void)updateCurrentEventLoadingTime
{
    if(self.currentEvent)
    {
        CFAbsoluteTime diff = CFAbsoluteTimeGetCurrent() - self.currentEventStartTime;
        self.currentEvent.loadTime = @(diff);
        NSError *error = nil;
        [self.context save:&error];
        
        if(error)
            NSLog(@"error while saving Event: %@", error.description);
    }
}

- (NSString *)convertToRelativeTime:(NSDate *)date
{
    NSString *timeInString = nil;
    
    NSTimeInterval msPerMinute = 60;
    NSTimeInterval msPerHour = msPerMinute * 60;
    NSTimeInterval msPerDay = msPerHour * 24;
    NSTimeInterval msPerMonth = msPerDay * 30;
    NSTimeInterval msPerYear = msPerDay * 365;
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:date];
    
    if (elapsed < msPerMinute) {
        timeInString = [NSString stringWithFormat:@"%.f 秒鐘前", elapsed];
    }
    else if (elapsed < msPerHour) {
        timeInString = [NSString stringWithFormat:@"%.f 分鐘前", elapsed/msPerMinute];
    }
    else if (elapsed < msPerDay ) {
        timeInString = [NSString stringWithFormat:@"%.f 小時前", elapsed/msPerHour];
    }
    else if (elapsed < msPerMonth) {
        timeInString = [NSString stringWithFormat:@"%.f 天前", elapsed/msPerDay];
    }
    else if (elapsed < msPerYear) {
        timeInString = [NSString stringWithFormat:@"%.f 月前", elapsed/msPerMonth];
    }
    else {
        timeInString = [NSString stringWithFormat:@"%.f 年前", elapsed/msPerYear];
    }
    
    return timeInString;
}

- (NSString *)convertToReadableTime:(NSDate *)date
{
    NSString *formattedDateString = [self.df stringFromDate:date];
    return formattedDateString;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSString *msg = [NSString stringWithFormat:@"%@", request.URL.absoluteString];
    [self logEvent:msg];
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.myIndicator.hidden = NO;
    [self.myIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.myIndicator.hidden = YES;
    [self updateCurrentEventLoadingTime];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    self.myIndicator.hidden = YES;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"載入失敗"
                                                    message:error.description
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"確定", nil];
    
    [alert show];
    
    [self logEvent:[NSString stringWithFormat:@"載入失敗: %@", error.description]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int count = self.frc.fetchedObjects.count;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"EventCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Event *event = [self.frc objectAtIndexPath:indexPath];
    float height = event.height.doubleValue + [EventCell minCellHeight];
    
    return height;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    EventCell *eventCell = (EventCell *)cell;
    Event *event = [self.frc objectAtIndexPath:indexPath];
    
    eventCell.content = event.content;
    eventCell.date = [self convertToReadableTime:event.timestamp];
    eventCell.contentHeight = event.height.floatValue;
    if(event.loadTime)
        eventCell.loadTime = [NSString stringWithFormat:@"%f", event.loadTime.floatValue];
    
    [eventCell setNeedsDisplay];
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if (action == @selector(copy:)) {
		return YES;
	}
	
	return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if (action == @selector(copy:)) {
        Event *e = [self.frc objectAtIndexPath:indexPath];
		[UIPasteboard generalPasteboard].string = e.content;
	}
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.myTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.myTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                            withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.myTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                            withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.myTableView;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.myTableView endUpdates];
}

@end
