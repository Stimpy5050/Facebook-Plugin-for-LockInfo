#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FBLikesCell.h"
#import "FacebookAuth.h"
#import "FBCommon.h"
#import "FBSingletons.h"

@implementation FBLikesCell

@synthesize likesView, postID, delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])
	{
        CGRect lvFrame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
        self.likesView = [[FBLikesView alloc] initWithFrame:lvFrame];
        self.likesView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.likesView.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[self.likesView addSubview:self.likesView.activity];
		self.likesView.activity.hidden == YES;
        [self.contentView addSubview:self.likesView];
        [self setUserInteractionEnabled:YES];
    }
    return self;
}

- (void)dealloc
{
	delegate = nil;
    [likesView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Event Handling

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.likesView.allowLikes)
    {
    	CGRect r = self.contentView.bounds;
        int likeOffset = 8;
        
        if (self.likesView.showImages)
            likeOffset += 17;
        
    	NSString* likeButtonString = ((self.likesView.userLikes) ? @"Unlike"  : @"Like");
    
		CGSize s = [likeButtonString sizeWithFont:self.likesView.theme.summaryStyle.font constrainedToSize:CGSizeMake(r.size.width - 15, 4000) lineBreakMode:UILineBreakModeWordWrap];
	
		if (CGRectContainsPoint(CGRectMake(likeOffset - 2, (int)((r.size.height - s.height) / 2) - 2, s.width + 4, s.height + 4), point))
			return YES;
    }
    return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.likesView.likeButtonDown = YES;
    [self.likesView setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.likesView.likeButtonDown = NO;
    [self.likesView setNeedsDisplay];
    
    [self performSelectorInBackground:@selector(changeUserLikes) withObject:nil];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.likesView.likeButtonDown = NO;
    [self.likesView setNeedsDisplay];
}

- (void)startLoading
{
	self.likesView.changeInProgress = YES;
	self.likesView.activity.hidden = NO;
	[self.likesView.activity startAnimating];
	[self.likesView setNeedsDisplay];
}

- (void)finishedLoading
{
	[self.likesView.activity stopAnimating];
	self.likesView.activity.hidden = YES;
	self.likesView.changeInProgress = NO;
	[self.likesView setNeedsDisplay];
}

- (void)changeUserLikes
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    [self performSelectorOnMainThread:@selector(startLoading) withObject:nil waitUntilDone:NO];
    
	FacebookAuth* auth = [[[FacebookAuth alloc] init] autorelease];
    
	NSString* httpMethod;
	
	if (self.likesView.userLikes)
		httpMethod = @"DELETE";
	else
		httpMethod = @"POST";
		
	if ([auth authorized])
	{
		NSString* url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/likes", self.postID];
		NSString* fullURL = [[NSString stringWithFormat:@"%@&access_token=%@", url, auth.access_token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullURL]];
		[request setHTTPMethod:httpMethod];
          
		NSError* error = nil;
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];

		if (error)
			DLog(@"LI: FB: Error liking post");
		else
		{	
            if (self.likesView.userLikes)
            {
                self.likesView.userLikes = NO;
                self.likesView.likes--;
            }
            else
            {
                self.likesView.userLikes = YES;
                self.likesView.likes++;
            }
            
			if ([self.delegate respondsToSelector:@selector(setUserLikesPost)])
				[self.delegate setUserLikesPost:self.likesView.userLikes];
		}        
	}
	else
		DLog(@"LI: FB: Auth not authorised to like comment");
    
    [self performSelectorOnMainThread:@selector(finishedLoading) withObject:nil waitUntilDone:NO];
	[self.likesView setNeedsDisplay];
	[pool drain];
}

@end

@implementation FBLikesView

@synthesize theme, likes, userLikes, allowLikes, likeButtonDown, showImages, changeInProgress, activity;

- (void)setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect) rect
{
	CGRect r = self.superview.bounds;
    int likeOffset = 8;
    
    if (self.showImages)
        likeOffset += 17;
    
    if (self.changeInProgress)
		self.activity.frame = CGRectMake((int)((r.size.width - 15) / 2), (int)((r.size.height - 15) / 2), 15, 15);
    else {
        
        if (self.allowLikes)
        {
            NSString* likeButtonString = ((self.userLikes) ? @"Unlike"  : @"Like");
            CGSize likeButtonSize = [likeButtonString sizeWithFont:self.theme.summaryStyle.font];
            
            int verticalOffset = ((r.size.height - likeButtonSize.height) / 2);
            
            if (self.likeButtonDown)
                [[[[FBSharedDataController sharedInstance] pluginImage:@"LikeButtonBackground"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] drawInRect:CGRectMake(likeOffset, verticalOffset - 1, likeButtonSize.width + 4, likeButtonSize.height + 2)];
        
            [likeButtonString drawInRect:CGRectMake(likeOffset + 2, verticalOffset, likeButtonSize.width, likeButtonSize.height) withFont:((self.likeButtonDown) ? self.theme.likeStyleDown.font : self.theme.summaryStyle.font) lineBreakMode:UILineBreakModeTailTruncation];
            likeOffset += likeButtonSize.width + 8;
        }
        
        if (self.likes > 0)
        {
            [[[FBSharedDataController sharedInstance] pluginImage:@"LikeIcon"] drawInRect:CGRectMake(likeOffset, (int)((r.size.height - 14) /2), 15, 14)];
            int otherLikes = self.likes;
            NSString* likeString = @"";
            if (self.userLikes)
            {
                otherLikes--;
                
                if (otherLikes > 0)
                    likeString = [NSString stringWithFormat:@"You and %i other %@ this.", otherLikes, ((otherLikes > 1) ? @"people like" : @"person likes")];
                else
                    likeString = @"You like this.";
            }
            else
                likeString = [NSString stringWithFormat:@"%i %@ this.", otherLikes, ((otherLikes > 1) ? @"people like" : @"person likes")];
            CGSize likeSize = [likeString sizeWithFont:self.theme.detailStyle.font];
            int verticalOffset = ((r.size.height - likeSize.height) / 2);
            [likeString drawInRect:CGRectMake(likeOffset + 18, verticalOffset, likeSize.width, likeSize.height) withFont:self.theme.detailStyle.font lineBreakMode:UILineBreakModeTailTruncation];
        }
    }
}

- (void)dealloc
{
    [activity release];
    [theme release];
    [super dealloc];
}

@end