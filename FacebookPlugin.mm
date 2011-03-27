#import <Foundation/Foundation.h>
#import <Common/LocalizedListController.h>
#import <substrate.h>
#import <sqlite3.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <CommonCrypto/CommonHMAC.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBTelephonyManager.h>
#import <Preferences/PSRootController.h>
#import <Preferences/PSDetailController.h>
#include "KeychainUtils.h"
#include "FacebookAuth.h"
#include "../../SDK/Plugin.h"

static NSString* CLIENT_ID = @"146687422042682";

@interface JSON

+(id) objectWithData:(NSData*) data options:(unsigned) options error:(NSError**) error;

@end

@interface UIScreen (LIAdditions)

-(float) scale;

@end

@interface UIImage (LIAdditions)
- (id)lifacebook_initWithContentsOfResolutionIndependentFile:(NSString *)path;
+ (UIImage*)lifacebook_imageWithContentsOfResolutionIndependentFile:(NSString *)path;
@end

@implementation UIImage (LIAdditions)

- (id)lifacebook_initWithContentsOfResolutionIndependentFile:(NSString *)path
{
        float scale = ( [[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? (float)[[UIScreen mainScreen] scale] : 1.0);
        if ( scale == 2.0)
        {
                NSString *path2x = [[path stringByDeletingLastPathComponent]
                        stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.%@",
                                [[path lastPathComponent] stringByDeletingPathExtension],
                                [path pathExtension]]];

                if ( [[NSFileManager defaultManager] fileExistsAtPath:path2x] )
                {
                        return [self initWithContentsOfFile:path2x];
                }
        }

        return [self initWithContentsOfFile:path];
}

+ (UIImage*) lifacebook_imageWithContentsOfResolutionIndependentFile:(NSString *)path
{
        return [[[UIImage alloc] lifacebook_initWithContentsOfResolutionIndependentFile:path] autorelease];
}

@end


Class $SBTelephonyManager = objc_getClass("SBTelephonyManager");

#define Hook(cls, sel, imp) \
        _ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

@interface FacebookAuthController : PSDetailController <UIWebViewDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) UIWebView* webView;
@property (nonatomic, retain) UIActivityIndicatorView* activity;
@property (retain) FacebookAuth* auth;

@end

@implementation FacebookAuthController

@synthesize webView, activity;
@synthesize auth;

- (void) loadURL:(NSURL*) url
{
	self.activity = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];

	UIView* view = [self view];
	view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	view.autoresizesSubviews = YES;

	self.webView = [[UIWebView alloc] initWithFrame:view.bounds];
	self.webView.autoresizesSubviews = YES;
	self.webView.autoresizingMask=(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
	self.webView.scalesPageToFit = YES;
	self.webView.delegate = self;
	[view addSubview:self.webView];

	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void) initAuth
{
	[self loadURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=http://lockinfo.ashman.com/&display=touch", CLIENT_ID]]];

	if (self.auth == nil)
	{
		self.auth = [[[FacebookAuth alloc] init] autorelease];
/*
		if ([self.auth requestFacebookToken])
		else
			NSLog(@"LI:Facebook: Token request failed!");
*/
	}
}

-(void) viewWillBecomeVisible:(id) spec
{
	[super viewWillBecomeVisible:spec];
	[self initAuth];
}

-(void) viewWillAppear:(BOOL) a
{
	[super viewWillAppear:a];
	[self.view bringSubviewToFront:self.webView];
	[self initAuth];
}

-(void) setBarButton:(UIBarButtonItem*) button
{
	PSRootController* root = self.rootController;
	UINavigationBar* bar = root.navigationBar;
	UINavigationItem* item = bar.topItem;
	item.rightBarButtonItem = button;
}

-(void) startLoad:(UIWebView*) wv
{
	CGRect r = self.activity.frame;
	r.size.width += 5;
	UIView* v = [[[UIView alloc] initWithFrame:r] autorelease];
	v.backgroundColor = [UIColor clearColor];
	[v addSubview:self.activity];
	[self.activity startAnimating];
	UIBarButtonItem* button = [[[UIBarButtonItem alloc] initWithCustomView:v] autorelease];
	[self setBarButton:button];

	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = YES;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSLog(@"LI:Facebook: Should load %@?", request.URL);
	if ([request.URL.host isEqualToString:@"lockinfo.ashman.com"])
	{	
		if ([self.auth authorizeFacebookCode:[request.URL.query substringFromIndex:5]])
			NSLog(@"LI:Facebook: Authorized!");
		else
			NSLog(@"LI:Facebook: Authorization failed!");

		if ([self.rootController respondsToSelector:@selector(popControllerWithAnimation:)])
                	[self.rootController popControllerWithAnimation:YES];
		else
                	[self.rootController popViewControllerAnimated:YES];

		return NO;
	}

	[self startLoad:webView];
	return YES;
}

-(void) webViewDidFinishLoad:(UIWebView*) wv
{
	[self.activity stopAnimating];
	[self setBarButton:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:wv action:@selector(reload)] autorelease]];

	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = NO;
}

-(id) navigationTitle
{
	return @"Authentication";
}

@end

@interface UIProgressIndicator : UIView

+(CGSize) defaultSizeForStyle:(int) size;
-(void) setStyle:(int) style;

@end

extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

#define localize(str) \
        [self.plugin.bundle localizedStringForKey:str value:str table:nil]

#define localizeSpec(str) \
        [self.bundle localizedStringForKey:str value:str table:nil]

#define localizeGlobal(str) \
        [self.plugin.globalBundle localizedStringForKey:str value:str table:nil]

static NSString* TWITTER_SERVICE = @"com.ashman.lockinfo.FacebookPlugin";

static NSInteger sortByDate(id obj1, id obj2, void* context)
{
        double d1 = [[obj1 objectForKey:@"date"] doubleValue];
        double d2 = [[obj2 objectForKey:@"date"] doubleValue];

        if (d1 < d2)
                return NSOrderedDescending;
        else if (d1 > d2)
                return NSOrderedAscending;
        else
                return NSOrderedSame;
}


@interface TweetView : UIView

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* tweet;
@property (nonatomic, retain) NSString* time;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, retain) UIImage* icon;
@property (nonatomic, retain) LITheme* theme;

@end

@implementation TweetView

@synthesize name, time, image, icon, theme, tweet;

-(void) setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

-(void) drawRect:(CGRect) rect
{
	CGRect r = self.superview.bounds;
	int summary = self.theme.summaryStyle.font.pointSize + 3;

	int offset = (self.image == [NSNull null] ? 0 : 10);
	[self.name drawInRect:CGRectMake(25 + offset, 0, (r.size.width - 180), summary) withLIStyle:self.theme.summaryStyle lineBreakMode:UILineBreakModeTailTruncation];
	[self.time drawInRect:CGRectMake(r.size.width - 150, 0, 145, summary) withLIStyle:self.theme.detailStyle lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];

        CGSize s = [self.tweet sizeWithFont:self.theme.detailStyle.font constrainedToSize:CGSizeMake(r.size.width - 40, 4000) lineBreakMode:UILineBreakModeWordWrap];
	[self.tweet drawInRect:CGRectMake(25 + offset, summary, s.width, s.height + 1) withLIStyle:self.theme.detailStyle lineBreakMode:UILineBreakModeWordWrap];

	if (self.image != [NSNull null] && self.image != nil)
		[self.image drawInRect:CGRectMake(5, 5, 25, 25)];

	if (self.icon != nil)
	{
		// center
        	s = [self.name sizeWithFont:self.theme.summaryStyle.font];
		CGPoint p = CGPointMake(25 + offset + s.width + 4, (summary / 2) - (self.icon.size.height / 2) + 2);
		[self.icon drawAtPoint:p];
	}
}

@end

static NSNumber* YES_VALUE = [NSNumber numberWithBool:YES];

@interface UIKeyboardImpl : UIView
@property (nonatomic, retain) id delegate;
@end

@interface UIKeyboard : UIView

+(UIKeyboard*) activeKeyboard;
+(void) initImplementationNow;
+(CGSize) defaultSize;

@end

@interface FacebookPlugin : UIViewController <LIPluginController, LITableViewDelegate, UITableViewDataSource, UITextViewDelegate, LIPreviewDelegate> 
{
	NSTimeInterval nextUpdate;
	NSDateFormatter* formatter;
	NSConditionLock* lock;
}

@property (nonatomic, retain) LIPlugin* plugin;
@property (retain) NSMutableArray* feed;
@property (retain) NSMutableDictionary* imageCache;
@property (nonatomic, retain) UINavigationController* previewController;
@property (nonatomic, retain) UILabel* countLabel;

@property (nonatomic, retain) UIView* newTweetView;

// preview stuff
@property (nonatomic, retain) NSDictionary* previewTweet;
@property (nonatomic, retain) UITextView* previewTextView;

@end

static UITextView* previewTextView;

@implementation FacebookPlugin

@synthesize feed, plugin, imageCache, previewController, countLabel;

@synthesize previewTweet, previewTextView, newTweetView;

-(void) setCount:(int) count
{
	self.countLabel.text = [[NSNumber numberWithInt:count] stringValue];
}

-(void) previewDidShow:(LIPreview*) preview
{
	[self.previewTextView becomeFirstResponder];
	if (Class peripheral = objc_getClass("UIPeripheralHost"))
	{
		[[peripheral sharedInstance] setAutomaticAppearanceEnabled:YES];
		[[peripheral sharedInstance] orderInAutomatic];
	}
	else
	{
		[[UIKeyboard automaticKeyboard] orderInWithAnimation:YES];
	}

	previewTextView = self.previewTextView;
}

-(void) previewWillDismiss:(LIPreview*) preview
{
	previewTextView = nil;

	if (Class peripheral = objc_getClass("UIPeripheralHost"))
	{
		[[peripheral sharedInstance] orderOutAutomatic];
		[[peripheral sharedInstance] setAutomaticAppearanceEnabled:NO];
	}
	else
	{
		[[UIKeyboard automaticKeyboard] orderOutWithAnimation:YES];
	}
}

-(void) loadView
{
	UIView* v = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	v.backgroundColor = [UIColor blackColor];

	UITextView* tv = [[[UITextView alloc] initWithFrame:v.bounds] autorelease];
	tv.backgroundColor = [UIColor blackColor];
	tv.editable = true;
	tv.keyboardAppearance = UIKeyboardAppearanceAlert;
	tv.font = [UIFont systemFontOfSize:20];
	tv.textColor = [UIColor whiteColor];

	if (NSString* name = [self.previewTweet objectForKey:@"screenName"])
		tv.text = [NSString stringWithFormat:@"@%@ ", name];

	tv.delegate = self;
	[v addSubview:tv];
	self.previewTextView = tv;

	UILabel* l = [[[UILabel alloc] initWithFrame:CGRectMake(v.frame.size.width - 60, v.frame.size.height - [UIKeyboard defaultSize].height - 80, 60, 30)] autorelease];
	l.backgroundColor = [UIColor clearColor];
	l.font = [UIFont boldSystemFontOfSize:24];
	l.textColor = [UIColor whiteColor];
	l.textAlignment = UITextAlignmentCenter;
	self.countLabel = l;
	[v addSubview:l];

	[self setCount:140 - tv.text.length];
	self.view = v;
}

- (BOOL) keyboardInputShouldDelete:(UITextView*)input
{
	[self setCount:140 - input.text.length];
       	return YES;
}

-(void) sendTweet:(NSString*) tweet
{
	CGSize sz = [UIProgressIndicator defaultSizeForStyle:5];
        UIProgressIndicator* ind = [[[UIProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, sz.width, sz.height)] autorelease];
	ind.tag = 575933;
        ind.center = self.newTweetView.center;
        [ind setStyle:5];
	[ind startAnimation];

	self.newTweetView.hidden = YES;
	[self.newTweetView.superview addSubview:ind];

	[self performSelectorInBackground:@selector(sendTweetInBackground:) withObject:tweet];
}


-(void) sendTweetInBackground:(NSString*) tweet
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	NSString* url = @"https://api.facebook.com/1/statuses/update.xml";

	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:tweet, @"status", nil];
	if (NSString* id = [self.previewTweet objectForKey:@"id"])
		[params setValue:id forKey:@"in_reply_to_status_id"];

	NSMutableArray* paramArray = [NSMutableArray arrayWithCapacity:params.count];
	for (id key in params)
		[paramArray addObject:[NSString stringWithFormat:@"%@=%@", [key encodedURLParameterString], [[params objectForKey:key] encodedURLParameterString]]];
	NSString* qs = [paramArray componentsJoinedByString:@"&"];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	NSData* body = [qs dataUsingEncoding:NSUTF8StringEncoding];

	FacebookAuth* auth = [[[FacebookAuth alloc] init] autorelease];
	NSString* header = [auth OAuthorizationHeader:request.URL method:@"POST" body:body];
	[request setValue:header forHTTPHeaderField:@"Authorization"];
	[request setHTTPBody:body];

	NSError* error;
	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];

	[[self.newTweetView.superview viewWithTag:575933] removeFromSuperview];
	self.newTweetView.hidden = NO;

	[pool release];
}

-(void) sendButtonPressed
{
	[self sendTweet:self.previewTextView.text];
	[self.plugin dismissPreview];
}

- (BOOL) keyboardInput:(UITextView*)input shouldInsertText:(NSString *)text isMarkedText:(int)marked 
{
	if (input.text.length == 140)
		return NO;

	[self setCount:140 - input.text.length - text.length];
       	return YES;
}

-(UIView*) showTweet:(NSDictionary*) tweet
{
	self.navigationItem.title = localize(@"Facebook");
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:localizeGlobal(@"Cancel") style:UIBarButtonItemStyleBordered target:self.plugin action:@selector(dismissPreview)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:localizeGlobal(@"Send") style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed)] autorelease];

	self.previewTweet = tweet;

	if (self.isViewLoaded)
	{
		if (NSString* name = [self.previewTweet objectForKey:@"screenName"])
			self.previewTextView.text = [NSString stringWithFormat:@"@%@ ", name];
		else
			self.previewTextView.text = @"";

		[self setCount:140 - self.previewTextView.text.length];
		[self.previewTextView becomeFirstResponder];
	}

	self.previewController = [[[UINavigationController alloc] initWithRootViewController:self] autorelease];
	UINavigationBar* bar = self.previewController.navigationBar;
	bar.barStyle = UIBarStyleBlackOpaque;

	return self.previewController.view;
}

-(void) showNewTweet
{
	UIView* v = [self showTweet:[NSDictionary dictionary]];
	[self.plugin showPreview:v];
}

-(UIView*) tableView:(LITableView*) tableView previewWithFrame:(CGRect) frame forRowAtIndexPath:(NSIndexPath*) indexPath
{
	BOOL newFeed = YES;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"NewFeed"])
		newFeed = n.boolValue;
 
	int row = indexPath.row - (newFeed ? 1 : 0);
	if (row < self.feed.count)
	{
		BOOL replies = YES;
		if (NSNumber* n = [self.plugin.preferences objectForKey:@"Replies"])
			replies = n.boolValue;
 
		if (replies)
			return [self showTweet:[self.feed objectAtIndex:row]];
		else
			return nil;
	}
	else
	{
		return [self showTweet:[NSDictionary dictionary]];
	}
}

- (CGFloat)tableView:(LITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	BOOL newFeed = YES;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"NewFeed"])
		newFeed = n.boolValue;

	if (newFeed && indexPath.row == 0)
		return 24;

	int row = indexPath.row - (newFeed ? 1 : 0);
	if (row >= self.feed.count)
		return 0;

	NSDictionary* elem = [self.feed objectAtIndex:row];
        NSString* text = [elem objectForKey:@"tweet"];

	BOOL showImage = true;
	if (NSNumber* b = [self.plugin.preferences objectForKey:@"ShowImages"])
		showImage = b.boolValue;

	int width = tableView.frame.size.width - (showImage ? 40 : 30);
        CGSize s = [text sizeWithFont:tableView.theme.detailStyle.font constrainedToSize:CGSizeMake(width, 480) lineBreakMode:UILineBreakModeWordWrap];
        return (s.height + tableView.theme.summaryStyle.font.pointSize + 8);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfItemsInSection:(NSInteger)section 
{
	int max = 5;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"MaxFeed"])
		max = n.intValue;

	return (self.feed.count > max ? max : self.feed.count);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	BOOL newFeed = YES;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"NewFeed"])
		newFeed = n.boolValue;

	return [self tableView:tableView numberOfItemsInSection:section] + (newFeed ? 1 : 0);
}

- (UITableViewCell *)tableView:(LITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	BOOL newFeed = YES;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"NewFeed"])
		newFeed = n.boolValue;

	int row = indexPath.row;
	if (newFeed)
	{
		if (row == 0)
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NewTweetCell"];
			if (cell == nil) 
			{
				CGRect frame = CGRectMake(0, -1, tableView.frame.size.width, 24);
				cell = [[[UITableViewCell alloc] initWithFrame:frame reuseIdentifier:@"NewTweetCell"] autorelease];

				UIImageView* iv = [[[UIImageView alloc] initWithImage:tableView.sectionSubheader] autorelease];
				iv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
				iv.frame = frame;
				[cell.contentView addSubview:iv];

				UIView* container = [[[UIView alloc] initWithFrame:frame] autorelease];
				container.backgroundColor = [UIColor clearColor];
				container.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
				[cell.contentView addSubview:container];

				int fontSize = tableView.theme.headerStyle.font.pointSize + 3;
				LILabel* l = [tableView labelWithFrame:frame];
				l.backgroundColor = [UIColor clearColor];
				l.style = tableView.theme.headerStyle;
				l.text = localize(@"Compose");
				l.textAlignment = UITextAlignmentCenter;
				[container addSubview:l];

				CGSize sz = [l.text sizeWithFont:l.style.font];
				UIImage* img = [UIImage lifacebook_imageWithContentsOfResolutionIndependentFile:[self.plugin.bundle pathForResource:@"LIFacebookTweet" ofType:@"png"]];
				UIImageView* niv = [[[UIImageView alloc] initWithImage:img] autorelease];
				CGRect r = niv.frame;
				r.origin.x = (frame.size.width / 2) + (int)(sz.width / 2) + 4;
				r.origin.y = 2;
				niv.frame = r;
				self.newTweetView = niv;
				[container addSubview:niv];
			}

			return cell;
		}
		
		row--;
	}

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TweetCell"];
	
	if (cell == nil) 
	{
		CGRect frame = CGRectMake(0, 0, tableView.frame.size.width, 24);
		cell = [[[UITableViewCell alloc] initWithFrame:frame reuseIdentifier:@"TweetCell"] autorelease];
		
		TweetView* v = [[[TweetView alloc] initWithFrame:frame] autorelease];
		v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		v.backgroundColor = [UIColor clearColor];
		v.tag = 57;
		[cell.contentView addSubview:v];
	}

	TweetView* v = [cell.contentView viewWithTag:57];
	v.theme = tableView.theme;
	v.frame = CGRectMake(0, 0, tableView.frame.size.width, [self tableView:tableView heightForRowAtIndexPath:indexPath]);
	v.name = nil;
	v.tweet = nil;
	v.time = nil;
	v.icon = nil;
	v.image = [NSNull null];

	if (row < self.feed.count)
	{	
		NSDictionary* elem = [self.feed objectAtIndex:row];
		v.tweet = [elem objectForKey:@"tweet"];
	
		BOOL screenNames = false;
		if (NSNumber* b = [self.plugin.preferences objectForKey:@"UseScreenNames"])
			screenNames = b.boolValue;
		v.name = [elem objectForKey:(screenNames ? @"screenName" : @"name")];

		BOOL showImage = true;
		if (NSNumber* b = [self.plugin.preferences objectForKey:@"ShowImages"])
			showImage = b.boolValue;

		if (showImage)
		{
			NSString* img = [elem objectForKey:@"image"];
			v.image = [self.imageCache objectForKey:img];
		}
		else
		{
			v.image = [NSNull null];
		}

		if ([elem objectForKey:@"directMessage"])
		{
			v.icon = [UIImage lifacebook_imageWithContentsOfResolutionIndependentFile:[self.plugin.bundle pathForResource:@"LIFacebookDirectMessage" ofType:@"png"]];
		}
		else
		{
			v.icon = nil;
		}
       	 
		NSNumber* dateNum = [elem objectForKey:@"date"];
		int diff = 0 - [[NSDate dateWithTimeIntervalSince1970:dateNum.doubleValue] timeIntervalSinceNow];
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

MSHook(void, setDelegate, id self, SEL sel, id delegate)
{
	if (previewTextView)
		[previewTextView becomeFirstResponder];
	else
		_setDelegate(self, sel, delegate);
	
}
	
MSHook(BOOL, handleKeyEvent, id self, SEL sel, id event)
{
	if (previewTextView)
		return NO;
	else
		return _handleKeyEvent(self, sel, event);
}

static void callInterruptedApp(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSLog(@"LI:Facebook: Call interrupted app");
}

static void activeCallStateChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSLog(@"LI:Facebook: Call state changed");
}

-(id) initWithPlugin:(LIPlugin*) plugin
{
	self = [super init];
	self.plugin = plugin;
	self.imageCache = [NSMutableDictionary dictionaryWithCapacity:10];
	self.feed = [NSMutableArray arrayWithCapacity:10];

	lock = [[NSConditionLock alloc] init];
	formatter = [[NSDateFormatter alloc] init];
	formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
	formatter.dateFormat = @"EEE MMM dd HH:mm:ss Z yyyy";

	plugin.tableViewDataSource = self;
	plugin.tableViewDelegate = self;
	plugin.previewDelegate = self;

	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(update:) name:LITimerNotification object:nil];
	[center addObserver:self selector:@selector(update:) name:LIViewReadyNotification object:nil];

	Class $UIKeyboardImpl = objc_getClass("UIKeyboardImpl");
	Hook(UIKeyboardImpl, setDelegate:, setDelegate);

	Class $SBAwayController = objc_getClass("SBAwayController");
	Hook(SBAwayController, handleKeyEvent:, handleKeyEvent);

	return self;
}

-(void) dealloc
{
	[formatter release];
	[lock release];
	[super dealloc];
}

-(NSArray*) loadFeed:(NSString*) url
{
	FacebookAuth* auth = [[[FacebookAuth alloc] init] autorelease];
	if (!auth.authorized)
	{
		NSLog(@"LI:Facebook: Facebook client is not authorized!");
		return nil;
	}

	NSError* error = nil;

	NSString* fullURL = [NSString stringWithFormat:@"%@?access_token=%@", url, [auth.access_token stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSURL* urlObj = [NSURL URLWithString:fullURL];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj];
	request.HTTPMethod = @"GET";

	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
	NSLog(@"LI:Facebook: Error: %@", error);
	NSLog(@"LI:Facebook: Feed data: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);

	if (data)
	{
		id obj = [JSON objectWithData:data options:0 error:&error];
		NSLog(@"LI:Facebook: Data: %@", obj);
	}

	return nil;
}

-(void) _updateFeed
{	
	if (SBTelephonyManager* mgr = [$SBTelephonyManager sharedTelephonyManager])
	{
                if (mgr.inCall || mgr.incomingCallExists)
		{
			NSLog(@"LI:Facebook: No data connection available.");
                        return;
		}
	}

	NSLog(@"LI:Facebook: Loading feed...");

	NSArray* feed = [self loadFeed:@"https://graph.facebook.com/me/home"];

	if (feed.count != 0 && ![feed isEqualToArray:self.feed])
	{
		[self.feed setArray:feed];

		NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];
		[dict setValue:self.feed forKey:@"feed"];  
		[self.plugin updateView:dict];
	}

	NSTimeInterval refresh = 900;
	if (NSNumber* n = [self.plugin.preferences objectForKey:@"RefreshInterval"])
		refresh = n.intValue;

	nextUpdate = [[NSDate dateWithTimeIntervalSinceNow:refresh] timeIntervalSinceReferenceDate];
}

- (void) updateFeed:(BOOL) force
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

- (void) update:(NSNotification*) notif
{
	[self updateFeed:NO];
}

- (void) tableView:(LITableView*) tableView reloadDataInSection:(NSInteger)section
{
	[self updateFeed:YES];
}

@end
