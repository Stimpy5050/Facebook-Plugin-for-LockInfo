#import "FacebookDeAuthController.h"
#import <Preferences/PSRootController.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation FacebookDeAuthController

-(void) initAuth
{
	if (self.auth == nil)
		self.auth = [[[FacebookAuth alloc] init] autorelease];
    
    if ([self.auth authorized])
    {
        [self loadURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.facebook.com/method/auth.expireSession?access_token=%@", [self.auth.access_token stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
        [self.auth forget];
        
        NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray* facebookCookies = [cookies cookiesForURL:
                                    [NSURL URLWithString:@"http://login.facebook.com"]];
        
        for (NSHTTPCookie* cookie in facebookCookies) 
        {
            [cookies deleteCookie:cookie];
        }
        

    }
}

-(void) webViewDidFinishLoad:(UIWebView*) wv
{
	[self.activity stopAnimating];
	[self setBarButton:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:wv action:@selector(reload)] autorelease]];
	
	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = NO;
    
    if ([self.rootController respondsToSelector:@selector(popControllerWithAnimation:)])
        [self.rootController popControllerWithAnimation:YES];
    else
        [self.rootController popViewControllerAnimated:YES];
}

@end
