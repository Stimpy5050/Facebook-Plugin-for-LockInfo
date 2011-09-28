#include <objc/runtime.h>
#import "FBNewPostPreview.h"
#import "FBSingletons.h"
#import "SDK/Plugin.h"
#import "FBCommon.h"
#import "FacebookAuth.h"

@implementation FBNewPostPreview 

@synthesize userID, previewTextView, delegate;

- (id)init
{
    if (self = [super init])
    {      
        self.navigationItem.title = localize(@"Status Update");
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleBordered target:self action:@selector(sendButtonPressed)] autorelease];
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed)] autorelease];
    }
    
    return self;
}

- (void)dealloc
{
    delegate = nil;
    [userID release];
    [previewTextView release];
    [super dealloc];
}

- (void)loadView
{
	UIView* v = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	v.backgroundColor = [UIColor blackColor];
	
	UITextView* tv = [[[UITextView alloc] initWithFrame:v.bounds] autorelease];
	tv.backgroundColor = [UIColor blackColor];
	tv.editable = YES;
	tv.keyboardAppearance = UIKeyboardAppearanceAlert;
	tv.font = [UIFont systemFontOfSize:20];
	tv.textColor = [UIColor whiteColor];
	
	tv.delegate = self;
	[v addSubview:tv];
	self.previewTextView = tv;
	self.view = v;
    
    // Not sure why this is required for some people but adding it anyway.
    
    self.navigationItem.title = localize(@"Status Update");
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleBordered target:self action:@selector(sendButtonPressed)] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed)] autorelease];
}

- (void)sendPost:(NSString*)post
{
	CGSize sz = [UIProgressIndicator defaultSizeForStyle:5];
	UIProgressIndicator* ind = [[[UIProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, sz.width, sz.height)] autorelease];
	ind.tag = 575933;
	ind.center = self.previewTextView.center;
	[ind setStyle:5];
	[ind startAnimation];
	
	self.previewTextView.hidden = YES;
	[self.previewTextView.superview addSubview:ind];
	
	[self performSelectorInBackground:@selector(sendPostInBackground:) withObject:post];
}

- (void)sendPostInBackground:(NSString*)post
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
     
    FacebookAuth* auth = [[[FacebookAuth alloc] init] autorelease];
     
    if ([auth authorized])
    {
        if (!self.userID)
        {
            NSDictionary* profile = (NSDictionary*)[[[self delegate] delegate] loadFBData:@"https://graph.facebook.com/me?format=JSON"];
            self.userID = [profile objectForKey:@"id"];
        }
        
        NSString* url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/feed?message=%@", self.userID, post];
        NSString* fullURL = [[NSString stringWithFormat:@"%@&access_token=%@", url, auth.access_token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullURL]];
        [request setHTTPMethod:@"POST"];
          
        NSError* error;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
    }
    else
        DLog(@"LI: FB: Auth not authorised to post status update");
     
    [self performSelectorOnMainThread:@selector(finishedSendingPost) withObject:nil waitUntilDone:NO];
    
    [pool drain];
}

- (void)finishedSendingPost
{
    [[self.previewTextView.superview viewWithTag:575933] removeFromSuperview];
    self.previewTextView.hidden = NO;
    
    if ([self.delegate respondsToSelector:@selector(clearPreview)])
        [self.delegate clearPreview];
}

- (void)sendButtonPressed
{
    if ([self.previewTextView.text lenght] == 0)
        return;
    
    if ([[[self delegate] delegate] respondsToSelector:@selector(resignKeyboard)])
        [[[self delegate] delegate] resignKeyboard];
    [self sendPost:self.previewTextView.text];
}

- (void)cancelButtonPressed
{
    if ([[[self delegate] delegate] respondsToSelector:@selector(resignKeyboard)])
        [[[self delegate] delegate] resignKeyboard];
    if ([self.delegate respondsToSelector:@selector(clearPreview)])
        [self.delegate clearPreview];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    int newLength = (textView.text.length - range.length) + text.length;
    if(newLength <= 420)
        return YES;
    
    int emptySpace = 420 - (textView.text.length - range.length);
    textView.text = [[[textView.text substringToIndex:range.location] 
                      stringByAppendingString:[text substringToIndex:emptySpace]]
                     stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
    return NO;
}

- (void)clearData
{
    self.userID = nil;
    self.previewTextView.text = @"";
}

- (void)previewDidShow
{
    self.previewTextView.text = @"";
    if ([[[self delegate] delegate] respondsToSelector:@selector(displayKeyboard:)])
        [[[self delegate] delegate] displayKeyboard:self.previewTextView];
}

- (void)previewWillDismiss
{
	if ([[[self delegate] delegate] respondsToSelector:@selector(resignKeyboard)])
        [[[self delegate] delegate] resignKeyboard];
}

@end
