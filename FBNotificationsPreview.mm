#include <objc/runtime.h>
#import <SpringBoard/SBTelephonyManager.h>
#import "FBNotificationsPreview.h"
#import "FBNotificationCell.h"
#import "FBSingletons.h"
#import "FBCommon.h"

@implementation FBNotificationsPreview

@synthesize theme, notifications, delegate, lastUpdate;

- (id)init
{
    if (self = [super init])
    {
        self.navigationItem.title = localize(@"Notifications");
        self.navigationItem.hidesBackButton = NO;
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self.delegate action:@selector(clearPreview)] autorelease];
        self.notifications = [NSMutableArray arrayWithCapacity:10];
    }
    
    return self;
}

- (void)dealloc
{
    delegate = nil;
    [theme release];
    [notifications release];
    [pull release];
    [super dealloc];
}

- (void)loadView
{
    
	UITableView* tv = [[[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain] autorelease];
	tv.backgroundColor = [UIColor whiteColor];
	tv.delegate = self;
    tv.dataSource = self;
    
    pull = [[PullToRefreshView alloc] initWithScrollView:tv];
    [pull setDelegate:self];
    [tv addSubview:pull];
    
	self.view = tv;
	[self performSelectorInBackground:@selector(updateNotifications) withObject:nil];
}

- (void)updateNotifications
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    if (SBTelephonyManager* mgr = [objc_getClass("SBTelephonyManager") sharedTelephonyManager])
	{
		if (mgr.inCall || mgr.incomingCallExists)
		{
			DLog(@"LI:Facebook: No data connection available.");
			return;
		}
	}
    
	DLog(@"LI:Facebook: Loading notifications...");
    
    NSString* query = @"SELECT sender_id, created_time, title_text FROM notification WHERE recipient_id=me() AND is_hidden = 0 LIMIT 20";
    
	NSArray* newNotifications = (NSArray*)[[[self delegate] delegate] loadFBData:[NSString stringWithFormat:@"https://api.facebook.com/method/fql.query?query=%@&format=JSON", [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    DLog(@"LI: FB: Notifications: %@", newNotifications);
    
    for (NSDictionary* notif in newNotifications)
    {
        [[FBSharedDataController sharedInstance] addUserToDownloadQueue:[notif objectForKey:@"sender_id"]];
    }
    
    [[FBSharedDataController sharedInstance] performSelectorOnMainThread:@selector(processDownloads) withObject:nil waitUntilDone:NO];
    
    if ([newNotifications count] != 0 && ![newNotifications isEqualToArray:self.notifications])
        [self.notifications setArray:newNotifications];
    
    [self performSelectorOnMainThread:@selector(finishedLoadingNotifications) withObject:nil waitUntilDone:NO];
    
    [pool drain];
}

- (void)finishedLoadingNotifications
{
    self.lastUpdate = [NSDate date];      
    [pull finishedLoading];
    [(UITableView*)self.view reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL* url = [NSURL URLWithString:@"fb://notifications"];
    
    if (![[UIApplication sharedApplication] canOpenURL:url])
        url = [NSURL URLWithString:@"htpp://www.facebook.com/notifications"];
    
	if ([[[self delegate] delegate] respondsToSelector:@selector(openURL:)])
		[[[self delegate] delegate] openURL:url];
    
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    int row = indexPath.row;
	if (row >= self.notifications.count)
		return 0;
    
    int width = tableView.frame.size.width;
	int summary = self.theme.summaryStyle.font.pointSize;
    
    NSDictionary* elem = [self.notifications objectAtIndex:row];
    
	int offset = ([[[self delegate] delegate] showImages] ? 25 : 0);
    
    NSString* notification = [elem objectForKey:@"title_text"];
	CGSize s = [notification sizeWithFont:self.theme.detailStyle.font constrainedToSize:CGSizeMake(width - (15 + offset), 4000) lineBreakMode:UILineBreakModeWordWrap];
    
	return (s.height + summary + 6);
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FBNotificationCell* cell = (FBNotificationCell*)[tableView dequeueReusableCellWithIdentifier:@"NotificationCell"];
	
	if (cell == nil) 
		cell = [[[FBNotificationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NotificationCell"] autorelease];
    
    int row = indexPath.row;
    
	FBNotificationView* v = cell.notifView;
	v.theme = self.theme;
	v.notification = nil;
	v.time = nil;
	v.image = (id)[NSNull null];

	if (row < self.notifications.count)
	{	
		NSDictionary* elem = [self.notifications objectAtIndex:row];
		v.notification = [elem objectForKey:@"title_text"];

		if ([[[self delegate] delegate] showImages])
		{
			NSString* userID = [elem objectForKey:@"sender_id"];
			v.image = [[FBSharedDataController sharedInstance] friendsImage:userID];
		}
		else
			v.image = (id)[NSNull null];
        
        NSDate* fbdate = [NSDate dateWithTimeIntervalSince1970:[[elem objectForKey:@"created_time"] doubleValue]];

		int diff = 0 - [fbdate timeIntervalSinceNow];
		if (diff > 86400)
		{
			int n = (int)(diff / 86400);
			v.time = (n == 1 ? @"1 day ago" : [NSString stringWithFormat:localize(@"%d days ago"), n]);
		}
		else if (diff > 3600)
		{
			int n = (int)(diff / 3600);
			if (diff % 3600 > 1800)
				n++;

			v.time = (n == 1 ? @"about 1 hour ago" : [NSString stringWithFormat:localize(@"about %d hours ago"), n]);
		}
		else if (diff > 60)
		{
			int n = (int)(diff / 60);
			if (diff % 60 > 30)
				n++;

			v.time = (n == 1 ? @"1 minute ago" : [NSString stringWithFormat:localize(@"%d minutes ago"), n]);
		}
		else
		{
			v.time = (diff == 1 ? @"1 second ago" : [NSString stringWithFormat:localize(@"%d seconds ago"), diff]);
		}
	}
	
	[v setNeedsDisplay];
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [notifications count];
}

- (void)clearData
{
    // Don't clear anything - keep notifications cached.
}

// called when the user pulls-to-refresh
- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view
{
    [self performSelectorInBackground:@selector(updateNotifications) withObject:nil];
}

// called when the date shown needs to be updated, optional
- (NSDate *)pullToRefreshViewLastUpdated:(PullToRefreshView *)view
{
    return self.lastUpdate;
}

@end