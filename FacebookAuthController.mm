#import "FacebookAuthController.h"
#import "KeychainUtils.h"
#import <Preferences/PSRootController.h>
#import <CommonCrypto/CommonHMAC.h>
#import "FacebookAuthPrivate.h"

@implementation FacebookAuthController

@synthesize webView, activity;
@synthesize auth;

- (void)loadURL:(NSURL*)url
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

- (void)initAuth
{
	[self loadURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=http://lockinfo.ashman.com/&display=touch&scope=offline_access,read_stream,publish_stream", CONSUMER_KEY]]];
	
	if (self.auth == nil)
		self.auth = [[[FacebookAuth alloc] init] autorelease];
}

- (void)viewWillBecomeVisible:(id) spec
{
	[super viewWillBecomeVisible:spec];
	[self initAuth];
}

- (void)viewWillAppear:(BOOL) a
{
	[super viewWillAppear:a];
	[self.view bringSubviewToFront:self.webView];
	[self initAuth];
}

- (void)setBarButton:(UIBarButtonItem*) button
{
	PSRootController* root = self.rootController;
	UINavigationBar* bar = root.navigationBar;
	UINavigationItem* item = bar.topItem;
	item.rightBarButtonItem = button;
}

- (void)startLoad:(UIWebView*) wv
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
    NSLog(@"LI: FB: Auth Loading URL: %@", request.URL.absoluteString);
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

- (void)webViewDidFinishLoad:(UIWebView*) wv
{
	[self.activity stopAnimating];
	[self setBarButton:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:wv action:@selector(reload)] autorelease]];
	
	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = NO;
}

- (id)navigationTitle
{
	return @"Authentication";
}

@end
