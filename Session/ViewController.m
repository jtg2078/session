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
#import "AFNetworking.h"

@interface ViewController ()
@property (nonatomic, strong) NSFetchedResultsController *frc;
@property (nonatomic, weak) NSManagedObjectContext *context;
@property (nonatomic, strong) NSDateFormatter *df;
@property (nonatomic, strong) Event *currentEvent;
@property (nonatomic, assign) CFAbsoluteTime currentEventStartTime;
@property (nonatomic, assign) CFAbsoluteTime locationStartTime;
@property (nonatomic, strong) Event *lbsEvent;
@end

@implementation ViewController

#pragma mark - memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// misc
    usingProduction = NO;
    [self home:nil];
    
    self.df = [[NSDateFormatter alloc] init];
    [self.df setDateFormat:@"M/dd a h:mm:ss"];
    
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
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.locationStartTime = CFAbsoluteTimeGetCurrent();
    [self.locationManager startMonitoringSignificantLocationChanges];
}

#pragma mark - user interaction

- (IBAction)home:(id)sender
{
    [self loadRelativePath:@""];
}

- (IBAction)user:(id)sender
{
    //[self loadRelativePath:@"/user"];
    
    //[self.myWebView stringByEvaluatingJavaScriptFromString:@"window.location.href='session:msg=abc'"];
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

- (Event *)logEvent:(NSString *)content loadTime:(NSNumber *)loadTime
{
    CGFloat height = [EventCell heightForText:content];
    
    Event *e = [NSEntityDescription insertNewObjectForEntityForName:@"Event"
                                             inManagedObjectContext:self.context];
    e.content = content;
    e.timestamp = [NSDate date];
    e.height = @(height);
    e.loadTime = loadTime;
    
    NSError *error = nil;
    [self.context save:&error];
    
    if(error)
        NSLog(@"error while saving Event: %@", error.description);
    
    return e;
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

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == alertView.firstOtherButtonIndex)
    {
        exit(0);
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *URL = [request URL];
    if ([[URL scheme] isEqualToString:@"session"])
    {
        NSString *urlString = [[request URL] absoluteString];
        NSArray *urlParts = [urlString componentsSeparatedByString:@":"];
        
        if ([urlParts count] > 1)
        {
            NSArray *parameters = [[urlParts objectAtIndex:1] componentsSeparatedByString:@"="];
            NSString *data = @"";
            if(parameters.count > 1)
                data = [parameters objectAtIndex:1];
            
            if(self.lbsEvent)
            {
                NSString *message = [NSString stringWithFormat:@"%@\n訊息: %@", self.lbsEvent.content, data];
                self.lbsEvent.content = message;
                self.lbsEvent.loadTime = @(CFAbsoluteTimeGetCurrent() - self.locationStartTime);
                [self.context save:nil];
                
                NSString *title = [NSString stringWithFormat:@"共花費: %f 秒", self.lbsEvent.loadTime.floatValue];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"確定"
                                                      otherButtonTitles:@"重試", nil];
                [alert show];
                
                self.lbsEvent = nil;
            }
        }
        
        return NO;
    }
    
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

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if(newLocation)
        [self locationManager:manager didUpdateLocations:@[newLocation]];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [self processLocation:[locations lastObject]];
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

#pragma mark - native LBS related

- (void)processLocation:(CLLocation *)location
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&sensor=true&region=zh&language=zh", location.coordinate.latitude, location.coordinate.longitude]]];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSDictionary *reDict = (NSDictionary *)JSON;
        NSArray *results = [reDict objectForKey:@"results"];
        
        if(results.count)
        {
            NSDictionary *partialDict = [results objectAtIndex:0];
            NSString *addr = [partialDict objectForKey:@"formatted_address"];
            
            if (addr && addr.length > 3)
            {
                //取出郵遞區號
                NSString *postCode = [addr substringWithRange:NSMakeRange(0,3)];
                
                NSString *areaCode = [self areaCode:postCode];
                if(areaCode && areaCode.length > 0)
                {
                    self.currentAreaCode = areaCode;
                    
                    CFAbsoluteTime diff = CFAbsoluteTimeGetCurrent() - self.locationStartTime;
                    NSString *msg = [NSString stringWithFormat:@"取得地區代碼: %@", self.currentAreaCode  ];
                    self.lbsEvent = [self logEvent:msg loadTime:@(diff)];
                    [self runLBSCode];
                }
                else
                {
                    NSString *errorMsg = [NSString stringWithFormat:@"取得地區代碼失敗！ %@", postCode];
                    NSLog(@"%@", errorMsg);
                }
                
            }
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        NSLog(@"%@", error.description);
    }];
    
    [op start];
}

//以郵遞區號查詢地區代碼
- (NSString *)areaCode:(NSString *)postCode
{
    if(!postCode || postCode.length == 0) {
        return nil;
    }
    
    //台北市
    NSArray *a01 = [NSArray arrayWithObjects:
                    @"100",@"103",@"104",@"105",@"106",@"108",@"110",@"111",@"112",@"114"
                    ,@"115",@"116", nil];
    //高雄市
    NSArray *a02 = [NSArray arrayWithObjects:
                    @"800",@"801",@"802",@"803",@"804",@"805",@"806",@"807",@"811",@"812"
                    ,@"813", nil];
    //基隆市
    NSArray *a03 = [NSArray arrayWithObjects:
                    @"200",@"201",@"202",@"203",@"204",@"205",@"206", nil];
    //新北市
    NSArray *a04 = [NSArray arrayWithObjects:
                    @"207",@"208",@"220",@"221",@"222",@"223",@"224",@"226",@"227",@"228"
                    ,@"231",@"232",@"233",@"234",@"235",@"236",@"237",@"238",@"239",@"241"
                    ,@"242",@"243",@"244",@"247",@"248",@"249",@"251",@"252",@"253", nil];
    //桃園縣
    NSArray *a05 = [NSArray arrayWithObjects:
                    @"320",@"324",@"325",@"326",@"327",@"328",@"330",@"333",@"334",@"335"
                    ,@"336",@"337",@"338", nil];
    //新竹縣
    NSArray *a06 = [NSArray arrayWithObjects:
                    @"302",@"303",@"304",@"305",@"306",@"307",@"308",@"310",@"311",@"312"
                    ,@"313",@"314",@"315", nil];
    //苗栗縣
    NSArray *a07 = [NSArray arrayWithObjects:
                    @"350",@"351",@"352",@"353",@"354",@"356",@"357",@"358",@"360",@"361"
                    ,@"362",@"363",@"364",@"365",@"366",@"367",@"368",@"369", nil];
    //台中市
    NSArray *a08 = [NSArray arrayWithObjects:
                    @"400",@"401",@"402",@"403",@"404",@"406",@"407",@"408",@"411",@"412"
                    ,@"413",@"414",@"420",@"421",@"422",@"423",@"424",@"426",@"427",@"428"
                    ,@"429",@"432",@"433",@"434",@"435",@"436",@"437",@"438",@"439", nil];
    //彰化縣
    NSArray *a09 = [NSArray arrayWithObjects:
                    @"500",@"502",@"503",@"504",@"505",@"506",@"057",@"508",@"509",@"510"
                    ,@"511",@"512",@"513",@"514",@"515",@"516",@"520",@"521",@"522",@"523"
                    ,@"524",@"525",@"526",@"527",@"528",@"530", nil];
    //南投縣
    NSArray *a10 = [NSArray arrayWithObjects:
                    @"540",@"541",@"542",@"544",@"545",@"546",@"551",@"552",@"553",@"555"
                    ,@"556",@"557",@"558", nil];
    //雲林縣
    NSArray *a11 = [NSArray arrayWithObjects:
                    @"630",@"631",@"632",@"633",@"634",@"635",@"636",@"637",@"638",@"640"
                    ,@"643",@"646",@"647",@"648",@"649",@"651",@"652",@"653",@"654",@"655", nil];
    //嘉義縣
    NSArray *a12 = [NSArray arrayWithObjects:
                    @"602",@"603",@"604",@"605",@"606",@"607",@"608",@"611",@"612",@"613"
                    ,@"614",@"615",@"616",@"621",@"622",@"623",@"624",@"625", nil];
    //台南市
    NSArray *a13 = [NSArray arrayWithObjects:
                    @"710",@"711",@"712",@"713",@"714",@"715",@"716",@"717",@"718",@"719"
                    ,@"720",@"721",@"722",@"723",@"724",@"725",@"726",@"727",@"730",@"731"
                    ,@"732",@"733",@"734",@"735",@"737",@"741",@"742",@"742",@"744",@"745", nil];
    //屏東縣
    NSArray *a15 = [NSArray arrayWithObjects:
                    @"900",@"901",@"902",@"903",@"904",@"905",@"906",@"907",@"908",@"909"
                    ,@"911",@"912",@"913",@"920",@"921",@"922",@"923",@"924",@"925",@"926"
                    ,@"927",@"928",@"929",@"931",@"932",@"940",@"941",@"942",@"943",@"944"
                    ,@"945",@"946",@"947", nil];
    //新竹市
    NSArray *a16 = [NSArray arrayWithObjects:@"300", nil];
    //宜蘭縣
    NSArray *a17 = [NSArray arrayWithObjects:
                    @"260",@"261",@"262",@"263",@"264",@"265",@"266",@"267",@"268",@"269",@"270",@"272", nil];
    //花蓮縣
    NSArray *a18 = [NSArray arrayWithObjects:
                    @"970",@"971",@"972",@"973",@"974",@"975",@"976",@"977",@"978",@"979",@"981",@"982",@"983", nil];
    //台東縣
    NSArray *a19 = [NSArray arrayWithObjects:@"950",@"955",@"961",@"966", nil];
    //澎湖縣
    NSArray *a20 = [NSArray arrayWithObjects:@"880",@"881",@"882",@"883",@"884",@"885",nil];
    //金門線
    NSArray *a21 = [NSArray arrayWithObjects:@"890",@"891",@"892",@"893",@"894",@"896",nil];
    //連江縣
    NSArray *a22 = [NSArray arrayWithObjects:@"209",@"210",@"211",@"212",nil];
    //嘉義市
    NSArray *a23 = [NSArray arrayWithObjects:@"600",nil];
    
    NSArray *countys = [NSArray arrayWithObjects:a01,a02,a03,a04,a05,a06,a07,a08,a09,a10,a11,a12,a13,a15,a16,a17,a18,a19,a20,a21,a22,a23,nil];
    NSArray *codes = [NSArray arrayWithObjects:@"01",@"02",@"03",@"04",@"05",@"06",@"07",@"08",@"09",@"10",@"11",@"12",@"13",@"15",@"16",@"17",@"18",@"19",@"20",@"21",@"22",@"23", nil];
    NSDictionary *codeDic = [[NSDictionary alloc] initWithObjects:countys forKeys:codes];
    
    BOOL stop = false;
    NSString *result = nil;
    for (id key in codeDic) {
        NSArray *ar = [codeDic objectForKey:key];
        for (int j=0; j<[ar count]; j++) {
            NSString *code = [ar objectAtIndex:j];
            if ([postCode isEqualToString:code]) {
                result = key;
                stop = true;
                break;
            }
        }
        if (stop) {
            break;
        }
    }
    
	return result;
}

- (void)runLBSCode
{
    if(self.currentAreaCode)
    {
        NSString *function = [NSString stringWithFormat:@"getMSGByCity('%@');", self.currentAreaCode];
        //run javascript code here
        [self.myWebView stringByEvaluatingJavaScriptFromString:function];
    }
}

@end
