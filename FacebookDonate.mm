#import "FacebookDonate.h"
#import <Preferences/PSRootController.h>

@implementation PSViewController (FacebookAdditions)

- (void)FacebookDonateButtonPressed:(id)param;
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=GA5GYDVR3XULY"]];
}

@end
