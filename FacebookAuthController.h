#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Preferences/PSDetailController.h>
#import "FacebookAuth.h"

@interface PSDetailController ()

- (void)viewWillBecomeVisible:(id)specifier;
- (void)popControllerWithAnimation:(BOOL)animation;

@end

@interface FacebookAuthController : PSDetailController <UIWebViewDelegate, UIAlertViewDelegate>
{
	UIWebView* webView;
	UIActivityIndicatorView* activity;
	FacebookAuth* auth;
}

@property (nonatomic, retain) UIWebView* webView;
@property (nonatomic, retain) UIActivityIndicatorView* activity;
@property (retain) FacebookAuth* auth;

- (void)startLoad:(UIWebView*)wv;
- (void)initAuth;
- (void)loadURL:(NSURL*)url;
- (void)setBarButton:(UIBarButtonItem*) button;

@end