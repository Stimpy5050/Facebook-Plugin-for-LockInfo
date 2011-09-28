#include <objc/runtime.h>
#import <Substrate/substrate.h>
#import <sqlite3.h>
#import <SpringBoard/SBTelephonyManager.h>
#import "FacebookAuth.h"
#import "FacebookPlugin.h"
#import "FBPostCell.h"
#import "FBButtonCell.h"
#import "FBPreview.h"
#import "FBSingletons.h"
#import "FBCommon.h"

@implementation FacebookPlugin

@synthesize plugin, feedPosts, previewController, optionsView, currentUserID, currentOptionsCell, theme;

#pragma mark -
#pragma mark Prefernces convenience methods

- (BOOL)newPosts
{
    BOOL newPosts = YES;
    if (NSNumber* n = [self.plugin.preferences objectForKey:@"NewPosts"])
        newPosts = n.boolValue;
    return newPosts;
}

- (BOOL)allowComments
{
    BOOL comments = YES;
    if (NSNumber* c = [self.plugin.preferences objectForKey:@"Comments"])
        comments = c.boolValue;
    return comments;
}

- (BOOL)allowLikes
{
    BOOL likes = YES;
    if (NSNumber* l = [self.plugin.preferences objectForKey:@"Likes"])
        likes = l.boolValue;
    return likes;
}

- (BOOL)showNotifications
{
    BOOL notifications = YES;
    if (NSNumber* n = [self.plugin.preferences objectForKey:@"ShowNotif"])
        notifications = n.boolValue;
    return notifications;
}

- (BOOL)showImages
{
    BOOL images = YES;
    if (NSNumber* i = [self.plugin.preferences objectForKey:@"ShowImages"])
        images = i.boolValue;
    return images;
}

- (int)maxPosts
{
    int max = 10;
	if (NSNumber* m = [self.plugin.preferences objectForKey:@"MaxPosts"])
		max = m.intValue;
    return max;
}

- (NSTimeInterval)refreshInterval
{
    NSTimeInterval refresh = 900;
	if (NSNumber* r = [self.plugin.preferences objectForKey:@"RefreshInterval"])
		refresh = r.intValue;
    return refresh;
}
    
#pragma mark -
#pragma mark Button action methods

- (void)statusButtonTapped
{
    [self.previewController setUserID:self.currentUserID];
    [self displayPreview:kNewPostPreview];
}

- (void)notifButtonTapped
{
    [self displayPreview:kNotificationsPreview];
}

- (void)likeButtonTapped
{
    int index = self.currentOptionsCell;
    FacebookAuth* auth = [[[FacebookAuth alloc] init] autorelease];
	
	NSString* httpMethod;
	
	NSDictionary* elem = [self.feedPosts objectAtIndex:index];
	NSDictionary* likes = [elem objectForKey:@"likes"];
	
	BOOL userLikes = [[likes objectForKey:@"user_likes"] boolValue];
	int noLikes = [[likes objectForKey:@"count"] intValue];
	
	if (userLikes)
		httpMethod = @"DELETE";
	else
		httpMethod = @"POST";
				
	if ([auth authorized])
	{
		NSString* url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/likes", [elem objectForKey:@"post_id"]];
		NSString* fullURL = [[NSString stringWithFormat:@"%@&access_token=%@", url, auth.access_token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullURL]];
		[request setHTTPMethod:httpMethod];
          
		NSError* error = nil;
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];

		if (error)
			DLog(@"LI: FB: Error liking post");
		else
		{
			if (userLikes)
			{
				userLikes = NO;
				noLikes--;
			}
			else
			{
				userLikes = YES;
				noLikes++;
			}
	
			[[[self.feedPosts objectAtIndex:index] objectForKey:@"likes"] setObject:[NSNumber numberWithBool:userLikes] forKey:@"user_likes"];
			[[[self.feedPosts objectAtIndex:index] objectForKey:@"likes"] setObject:[NSNumber numberWithInt:noLikes] forKey:@"count"];
            
            NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];
            [dict setValue:self.feedPosts forKey:@"feed"];
            [self.plugin updateView:dict];
		}
	}
	else
		DLog(@"LI: FB: Auth not authorised to like comment");
}

- (void)commentButtonTapped
{
	int index = self.currentOptionsCell;
	[self.previewController setPostData:[self.feedPosts objectAtIndex:index] forRowAtIndex:index];
    [self.previewController setKeyboardShouldShow:YES];
	[self displayPreview:kCommentsPreview];
}

- (void)removePopover
{  
    [self.optionsView removeFromSuperview];
}

- (void)showOptionsViewForRowAtIndex:(int)index arrowPoint:(CGPoint)arrowPoint
{
    self.currentOptionsCell = index;
    
    if (!self.optionsView)
    {
        self.optionsView = [[[FBOptionsView alloc] init] autorelease];
        self.optionsView.delegate = self;
    }
    
    [self.optionsView setArrowPoint:arrowPoint];
    
    NSDictionary* elem = [self.feedPosts objectAtIndex:index];
   
    BOOL comments = (([[[elem objectForKey:@"comments"] objectForKey:@"can_post"] boolValue]) && ([self allowComments]));
    BOOL likes = (([[[elem objectForKey:@"likes"] objectForKey:@"can_like"] boolValue]) && ([self allowLikes]));
    BOOL userLikes = [[[elem objectForKey:@"likes"] objectForKey:@"user_likes"] boolValue];
                        
    int optionsButtons;
	if (comments && likes)
    {
        if (userLikes)
            optionsButtons = kOptionsViewUnlikeAndCommentButtons;
        else
            optionsButtons = kOptionsViewLikeAndCommentButtons;
    }
	else if (comments)
		optionsButtons = kOptionsViewCommentButtonOnly;
	else if (likes)
    {
        if (userLikes)
            optionsButtons = kOptionsViewUnlikeButtonOnly;
        else
            optionsButtons = kOptionsViewLikeButtonOnly;
    }
		
	[self.optionsView setButtons:optionsButtons];
    
    UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    if (!keyWindow)
    {
        NSArray* windows = [[UIApplication sharedApplication] windows];
        
        for (id window in windows)
        {
            if ([window isKindOfClass:objc_getClass("SBAlertWindow")])
            {
                keyWindow = window;
                break;
            }
        }
    }
       
    if (keyWindow)
        [keyWindow insertSubview:self.optionsView aboveSubview:keyWindow];
    else
        DLog(@"LI: FB: windows: %@", [[UIApplication sharedApplication] windows]);
}

- (void)infoButtonPressedForRowAtIndex:(int)index
{
	self.currentOptionsCell = index;
    [self.previewController setKeyboardShouldShow:NO];
	[self.previewController setPostData:[self.feedPosts objectAtIndex:index] forRowAtIndex:index];
	[self displayPreview:kCommentsPreview];
}

#pragma mark -
#pragma mark Preview methods

- (void)displayKeyboard:(UIView*)keyboard
{
    [self.plugin showKeyboard:keyboard];
}

- (void)resignKeyboard
{
    [self.plugin dismissKeyboard];
}

- (void)displayPreview:(int)preview
{
	[self.previewController setTheme:self.theme];
	[self.previewController displayPreview:preview];
}

#pragma mark -
#pragma mark TableView methods

- (UIView*)tableView:(LITableView*)tableView previewWithFrame:(CGRect)frame forRowAtIndexPath:(NSIndexPath*)indexPath
{
	return self.previewController.view;
}

- (CGFloat)tableView:(LITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    BOOL buttonCell = ([self newPosts] || [self showNotifications]);
    
    if (buttonCell && indexPath.row == 0)
		return 42;
    
    int row = indexPath.row - (buttonCell ? 1 : 0);
	if (row >= self.feedPosts.count)
		return 0;
    
    int width = tableView.frame.size.width;
	int summary = tableView.theme.summaryStyle.font.pointSize;
    
	int leftOffset = ([self showImages] ? 25 : 0);
    int rightOffset = ([self allowComments] ? 27 : 0);
    
    NSDictionary* elem = [self.feedPosts objectAtIndex:row];
    
    NSString* message = [elem objectForKey:@"message"];
	CGSize s = [message sizeWithFont:tableView.theme.detailStyle.font constrainedToSize:CGSizeMake(width - (10 + leftOffset + rightOffset), 4000) lineBreakMode:UILineBreakModeWordWrap];
    
    int infoHeight = ((([[[elem objectForKey:@"likes"] objectForKey:@"count"] intValue] > 0) || ([[[elem objectForKey:@"comments"] objectForKey:@"count"] intValue] > 0)) ? 31 : 0);
    
	return (s.height + (2 * summary) + infoHeight + 10);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfItemsInSection:(NSInteger)section 
{
	int max = [self maxPosts];
    
	return (self.feedPosts.count > max ? max : self.feedPosts.count);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{    
	return [self tableView:tableView numberOfItemsInSection:section] + (([self newPosts] || [self showNotifications]) ? 1 : 0);
}

- (UITableViewCell *)tableView:(LITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	int row = indexPath.row;
    
    if ([self newPosts] || [self showNotifications])
    {
        if (row == 0)
        {
            FBButtonCell* cell = (FBButtonCell*)[tableView dequeueReusableCellWithIdentifier:@"FBButtonCell"];
            
            if (cell == nil) 
                cell = [[[FBButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FBButtonCell"] autorelease];
                
            if (!cell.backgroundLIView.image)
                cell.backgroundLIView.image = tableView.sectionSubheader;
            
            cell.delegate = self;
            cell.allowStatus = [self newPosts];
            cell.allowNotifications = [self showNotifications];
            [cell setNeedsLayout];
            
            return cell;
        }
		
        row--;
    }
	
	if (row == 0)
		self.theme = tableView.theme; // Set here so theme is updated when table redraws
	
	FBPostCell* cell = (FBPostCell*)[tableView dequeueReusableCellWithIdentifier:@"PostCell"];
	
	if (cell == nil) 
		cell = [[[FBPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PostCell"] autorelease];
    
    cell.delegate = self;
    cell.rowIndex = row;
    
	FBPostView* v = cell.postView;
	v.theme = tableView.theme;
    v.name = nil;
	v.message = nil;
	v.time = nil;
	v.image = (id)[NSNull null];

	if (row < self.feedPosts.count)
	{	
		NSDictionary* elem = [self.feedPosts objectAtIndex:row];
		v.message = [elem objectForKey:@"message"];
        
        if ([elem objectForKey:@"target_id"] != (id)[NSNull null])
        {
            v.name = [NSString stringWithFormat:@"%@ ▸ %@", [self nameForUserID:[elem objectForKey:@"actor_id"]], [self nameForUserID:[elem objectForKey:@"target_id"]]];
        } else {
            v.name = [self nameForUserID:[elem objectForKey:@"actor_id"]];
        }
        
        v.allowComments = (([[[elem objectForKey:@"comments"] objectForKey:@"can_post"] boolValue]) && ([self allowComments]));
        v.noComments = [[[elem objectForKey:@"comments"] objectForKey:@"count"] intValue];
        
        v.allowLikes = (([[[elem objectForKey:@"likes"] objectForKey:@"can_like"] boolValue]) && ([self allowLikes]));
		v.noLikes = [[[elem objectForKey:@"likes"] objectForKey:@"count"] intValue];

		if ([self showImages])
		{
			NSString* userID = [elem objectForKey:@"actor_id"];
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

#pragma mark -
#pragma mark Initialisation & Miscellaneous

static void callInterruptedApp(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	DLog(@"LI:Facebook: Call interrupted app");
}

static void activeCallStateChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	DLog(@"LI:Facebook: Call state changed");
}

MSHook(void, _undimScreen, id self, SEL sel)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.burgess.lockinfo.FacebookPlugin.screenUndim" object:nil];
	__undimScreen(self, sel);
}

MSHook(BOOL, clickedMenuButton, id self, SEL sel)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.burgess.lockinfo.FacebookPlugin.screenUndim" object:nil];
	return _clickedMenuButton(self, sel);
}

- (id)initWithPlugin:(LIPlugin*) plugin
{
	self = [super init];
	self.plugin = plugin;
    
    [[FBSharedDataController sharedInstance] initCache];
    
	self.feedPosts = [NSMutableArray arrayWithCapacity:20];
    self.previewController = [[[FBPreviewController alloc] init] autorelease];
    self.previewController.delegate = self;

	lock = [[NSConditionLock alloc] init];

	self.plugin.tableViewDataSource = self;
	self.plugin.tableViewDelegate = self;
	self.plugin.previewDelegate = self.previewController;
    
    Class $SBAwayController = objc_getClass("SBAwayController");
	Hook(SBAwayController, _undimScreen, _undimScreen);
    
    Class $SBUIController = objc_getClass("SBUIController");
    Hook(SBUIController, clickedMenuButton, clickedMenuButton);

	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(update:) name:LITimerNotification object:nil];
	[center addObserver:self selector:@selector(update:) name:LIViewReadyNotification object:nil];
    [center addObserver:self selector:@selector(removePopover) name:@"com.burgess.lockinfo.FacebookPlugin.screenUndim" object:nil];
    [center addObserver:self selector:@selector(removePopover) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];

	return self;
}

- (void)dealloc
{
	[lock release];
    [previewController release];
    [feedPosts release];
	[super dealloc];
}

- (NSString*)nameForUserID:(NSString*)userID
{
	if ([[FBSharedDataController sharedInstance] friendsName:userID])
        return [[FBSharedDataController sharedInstance] friendsName:userID];
    
    NSDictionary* profile = (NSDictionary*)[self loadFBData:[NSString stringWithFormat:@"https://graph.facebook.com/%@?format=JSON", userID]];
    NSString* name = [profile objectForKey:@"name"];
	[[FBSharedDataController sharedInstance] addUserToNameCache:name userID:userID];
    
    return name;
}

- (void)openURL:(NSURL*)url
{
	[self.plugin launchURL:url];
}

#pragma mark -
#pragma mark Update methods

- (void)updateComments:(NSDictionary*)comments forRowAtIndex:(int)index
{
	[[self.feedPosts objectAtIndex:index] setObject:comments forKey:@"comments"];
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:self.feedPosts forKey:@"feed"];
    [self.plugin updateView:dict];
}

- (void)updateLikes:(NSDictionary*)likes forRowAtIndex:(int)index
{
	[[self.feedPosts objectAtIndex:index] setObject:likes forKey:@"likes"];
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:self.feedPosts forKey:@"feed"];
    [self.plugin updateView:dict];
}

- (void)processUsers:(NSArray*)feed
{
    NSMutableArray* feedUsers = [NSMutableArray arrayWithArray:[[feed objectAtIndex:1] objectForKey:@"fql_result_set"]];
    
    for (id user in feedUsers)
    {
        [[FBSharedDataController sharedInstance] addUserToNameCache:[user objectForKey:@"name"] userID:[user objectForKey:@"id"]];
        [[FBSharedDataController sharedInstance] addUserToDownloadQueue:[user objectForKey:@"id"]];
    }

    [[FBSharedDataController sharedInstance] performSelectorOnMainThread:@selector(processDownloads) withObject:nil waitUntilDone:NO];
}

- (NSArray*)processedFeed:(NSArray*)feed
{
	NSMutableArray* newPosts = [NSMutableArray arrayWithArray:[[feed objectAtIndex:0] objectForKey:@"fql_result_set"]];

	return newPosts;
}

- (id)loadFBData:(NSString*) url
{
    FacebookAuth* auth = [[[FacebookAuth alloc] init] autorelease];
	if (!auth.authorized)
	{
		DLog(@"LI:Facebook: Facebook client is not authorized!");
		return nil;
	}

	NSError* error = nil;
                      
	NSString* fullURL = [NSString stringWithFormat:@"%@&access_token=%@", url, [auth.access_token stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSURL* urlObj = [NSURL URLWithString:fullURL];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj];
	request.HTTPMethod = @"GET";
	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
	
    if (error)
    {
        DLog(@"LI: Facebook: Data Request Error: %@", error);
        error = nil;
    }

	if (data)
	{
		id obj = [JSON objectWithData:data options:0 error:&error];
		DLog(@"LI: FB: Loaded Data: %@", obj);
        return obj;
	}
    
	return nil;
}

- (void)_updateFeed
{	
	if (SBTelephonyManager* mgr = [objc_getClass("SBTelephonyManager") sharedTelephonyManager])
	{
		if (mgr.inCall || mgr.incomingCallExists)
		{
			DLog(@"LI:Facebook: No data connection available.");
			return;
		}
	}

	DLog(@"LI:Facebook: Loading feed...");
    
    int noPosts = [self maxPosts];
    NSError* error = nil;
    
    NSString* nfQuery = [NSString stringWithFormat:@"SELECT post_id, actor_id, target_id, created_time, message, comments, likes FROM stream WHERE filter_key in (SELECT filter_key FROM stream_filter WHERE uid=me() AND type='newsfeed') AND is_hidden = 0 AND strlen(message) != 0 AND attachment.media='' AND strlen(attachment.name)=0 AND strlen(attachment.href)=0 AND strlen(attachment.description)=0 LIMIT %d", noPosts];
    NSString* userQuery = @"SELECT id, name FROM profile WHERE id IN (SELECT actor_id FROM #NewsFeed) OR id IN (SELECT comments.comment_list.fromid FROM #NewsFeed) OR id IN (SELECT target_id FROM #NewsFeed)";
    NSArray* multiQuery = [NSDictionary dictionaryWithObjectsAndKeys:nfQuery, @"NewsFeed", userQuery, @"Users", nil];
    NSString* query = [JSON stringWithObject:multiQuery options:0 error:&error];
    
    if (error)
        DLog(@"LI: Facebook: JSON error: %@", error);
    
	NSArray* feed = (NSArray*)[self loadFBData:[NSString stringWithFormat:@"https://api.facebook.com/method/fql.multiquery?queries=%@&format=JSON", [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    NSArray* newFeed = [self processedFeed:feed];
    [self processUsers:feed];
    
    DLog(@"LI: FB: Feed: %@", newFeed);
    
	if ([newFeed count] != 0 && ![newFeed isEqualToArray:self.feedPosts])
	{
		[self.feedPosts setArray:newFeed];
		
		NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setValue:newFeed forKey:@"feed"];
		[self.plugin updateView:dict];
	}
	
	NSDictionary* profile = (NSDictionary*)[self loadFBData:@"https://graph.facebook.com/me?format=JSON"];
	self.currentUserID = [profile objectForKey:@"id"];

	nextUpdate = [[NSDate dateWithTimeIntervalSinceNow:[self refreshInterval]] timeIntervalSinceReferenceDate];
}

- (void)updateFeed:(BOOL) force
{
	if (!self.plugin.enabled)
		return;

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	if ([lock tryLock])
	{
		if(force || nextUpdate < [NSDate timeIntervalSinceReferenceDate])
			[self _updateFeed];

		[lock unlock];
	}

	[pool release];
}

- (void)update:(NSNotification*) notif
{
	[self updateFeed:NO];
}

- (void)tableView:(LITableView*) tableView reloadDataInSection:(NSInteger)section
{
	[self updateFeed:YES];
}

@end
