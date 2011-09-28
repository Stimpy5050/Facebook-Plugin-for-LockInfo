#include <objc/runtime.h>
#import "FBPreviewController.h"
#import "FBSingletons.h"
#import "FBCommon.h"

@implementation FBPreviewController

@synthesize commentsPreview, notifPreview, newPostPreview, delegate, previewTheme;

- (id)init
{
    if (self = [super init])
    {        
        self.previewTheme = [[FBPreviewTheme alloc] init];
        
        self.commentsPreview = [[FBCommentsPreview alloc] init];
        self.newPostPreview = [[FBNewPostPreview alloc] init];
        self.notifPreview = [[FBNotificationsPreview alloc] init];
        self.commentsPreview.delegate = self;
        self.newPostPreview.delegate = self;
        self.notifPreview.delegate = self;
        self.viewControllers = [NSArray arrayWithObject:self.commentsPreview];
    }
    
    return self;
}

- (void)dealloc
{
	delegate = nil;
    [commentsPreview release];
    [newPostPreview release];
    [notifPreview release];
    [previewTheme release];
    [super dealloc];
}

- (void)setUserID:(NSString*)userID
{
    self.newPostPreview.userID = userID;
}

- (void)setKeyboardShouldShow:(BOOL)show
{
    self.commentsPreview.shouldLoadWithKeyboard = show;
}

- (void)setTheme:(LITheme*)theme
{
	self.previewTheme.summaryStyle = [theme.summaryStyle copy];
	self.previewTheme.summaryStyle.textColor = [UIColor blackColor];
	
	self.previewTheme.detailStyle = [theme.detailStyle copy];
	self.previewTheme.detailStyle.textColor = [UIColor blackColor];
	
	self.previewTheme.nameStyle = [theme.summaryStyle copy];
	self.previewTheme.nameStyle.textColor = [UIColor colorWithRed:87.0/255.0 green:107.0/255.0 blue:149.0/255.0 alpha:1.0];
	
	self.previewTheme.timeStyle = [theme.summaryStyle copy];
	self.previewTheme.timeStyle.font = [self.previewTheme.timeStyle.font fontWithSize:self.previewTheme.timeStyle.font.pointSize - 3];
    self.previewTheme.timeStyle.textColor = [UIColor darkGrayColor];

	self.previewTheme.likeStyle = [self.previewTheme.timeStyle copy];
	self.previewTheme.likeStyle.textColor = [UIColor colorWithRed:87.0/255.0 green:107.0/255.0 blue:149.0/255.0 alpha:1.0];
	
	self.previewTheme.likeStyleDown = [self.previewTheme.timeStyle copy];
	self.previewTheme.likeStyleDown.textColor = [UIColor whiteColor];
	
	self.previewTheme.detailCellBackgroundColour = [UIColor colorWithRed:237.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0];

	self.commentsPreview.theme = self.previewTheme;
	self.notifPreview.theme = self.previewTheme; 
}

- (void)setPostData:(NSDictionary*)postData forRowAtIndex:(int)index
{
    NSLog(@"LI: FB: Post Data: %@", postData);
    
	// Post Data
	self.commentsPreview.postID = [postData objectForKey:@"post_id"];
	self.commentsPreview.streamRowIndex = index;
	
	if ([postData objectForKey:@"target_id"] != (id)[NSNull null])
		self.commentsPreview.name = [NSString stringWithFormat:@"%@ ▸ %@", [self.delegate nameForUserID:[postData objectForKey:@"actor_id"]], [self.delegate nameForUserID:[postData objectForKey:@"target_id"]]];
    else
        self.commentsPreview.name = [self.delegate nameForUserID:[postData objectForKey:@"actor_id"]];
        
	self.commentsPreview.post = [postData objectForKey:@"message"];
	
	if ([self.delegate showImages])
    {
        NSString* userID = [postData objectForKey:@"actor_id"];
        self.commentsPreview.image = [[FBSharedDataController sharedInstance] friendsImage:userID];
    }
    else
        self.commentsPreview.image = (id)[NSNull null];
	
	NSDate* fbdate = [NSDate dateWithTimeIntervalSince1970:[[postData objectForKey:@"created_time"] doubleValue]];

    int diff = 0 - [fbdate timeIntervalSinceNow];
    if (diff > 86400)
    {
        int n = (int)(diff / 86400);
        self.commentsPreview.time = (n == 1 ? @"1 day ago" : [NSString stringWithFormat:localize(@"%d days ago"), n]);
    }
    else if (diff > 3600)
    {
        int n = (int)(diff / 3600);
        if (diff % 3600 > 1800)
            n++;

        self.commentsPreview.time = (n == 1 ? @"about 1 hour ago" : [NSString stringWithFormat:localize(@"about %d hours ago"), n]);
    }
    else if (diff > 60)
    {
        int n = (int)(diff / 60);
        if (diff % 60 > 30)
            n++;

        self.commentsPreview.time = (n == 1 ? @"1 minute ago" : [NSString stringWithFormat:localize(@"%d minutes ago"), n]);
    }
    else
    {
        self.commentsPreview.time = (diff == 1 ? @"1 second ago" : [NSString stringWithFormat:localize(@"%d seconds ago"), diff]);
    }
	
	// Comment Data
	NSDictionary* comments = [postData objectForKey:@"comments"];
	[self.commentsPreview.comments setArray:[comments objectForKey:@"comment_list"]];
	self.commentsPreview.noComments = [[comments objectForKey:@"count"] intValue];
	self.commentsPreview.allowComments = (([[comments objectForKey:@"can_post"] boolValue]) && ([self.delegate allowComments]));
	
	// Likes Data
	NSDictionary* likes = [postData objectForKey:@"likes"];
	self.commentsPreview.noLikes = [[likes objectForKey:@"count"] intValue];  
	self.commentsPreview.allowLikes = (([[likes objectForKey:@"can_like"] boolValue]) && ([self.delegate allowLikes]));
	self.commentsPreview.userLikes = [[likes objectForKey:@"user_likes"] boolValue];

}

- (void)displayPreview:(int)preview
{
    switch (preview) 
    {
        case kCommentsPreview:
            self.viewControllers = [NSArray arrayWithObject:self.commentsPreview];
            break;
            
        case kNotificationsPreview:
            self.viewControllers = [NSArray arrayWithObject:self.notifPreview];
            break;
            
        case kNewPostPreview:
            self.viewControllers = [NSArray arrayWithObject:self.newPostPreview];
            break;
                        
        default:
            break;
    }
    
    /* Pending LockInfo bug fix
     
     // [[(FacebookPlugin*)[self delegate] plugin] showPreview:self.view];
     
     */
    
    id LockInfoController = objc_getClass("LockInfoController");
    
    [[[LockInfoController sharedInstance] preview] addSubview:self.view];
    [[[LockInfoController sharedInstance] preview] setDelegate:self];
    [[[LockInfoController sharedInstance] preview] show];
}

- (void)clearPreview
{
    /* Pending LockInfo bug fix
     
     // [[(FacebookPlugin*)[self delegate] plugin] dismissPreview];
     
     */
    
    [[[objc_getClass("LockInfoController") sharedInstance] preview] dismiss];
    
    [self.commentsPreview clearData];
    [self.newPostPreview clearData];
    [self.notifPreview clearData];
}

#pragma mark -
#pragma mark LIPreviewDelegate method forwardin

- (void)previewWillShow:(LIPreview*)preview
{
	if ([[self.viewControllers objectAtIndex:0] respondsToSelector:@selector(previewWillShow)])
        [[self.viewControllers objectAtIndex:0] previewWillShow];
}

- (void)previewDidShow:(LIPreview*)preview
{
    if ([[self.viewControllers objectAtIndex:0] respondsToSelector:@selector(previewDidShow)])
        [[self.viewControllers objectAtIndex:0] previewDidShow];
}

- (void)previewWillDismiss:(LIPreview*)preview
{
	if ([[self.viewControllers objectAtIndex:0] respondsToSelector:@selector(previewWillDismiss)])
        [[self.viewControllers objectAtIndex:0] previewWillDismiss];
}

- (void)previewDidDismiss:(LIPreview*)preview
{
	if ([[self.viewControllers objectAtIndex:0] respondsToSelector:@selector(previewDidDismiss)])
        [[self.viewControllers objectAtIndex:0] previewDidDismiss];
}

@end
