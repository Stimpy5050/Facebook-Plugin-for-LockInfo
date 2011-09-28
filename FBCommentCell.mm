#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SDK/Plugin.h"
#import "FBCommentCell.h"
#import "FacebookAuth.h"
#import "FBCommon.h"
#import "FBSingletons.h"

@implementation FBCommentCell

@synthesize commentView, commentID, rowIndex, delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        CGRect cvFrame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
        self.commentView = [[FBCommentView alloc] initWithFrame:cvFrame];
        self.commentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.commentView.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[self.commentView addSubview:self.commentView.activity];
		self.commentView.activity.hidden == YES;
        [self.contentView addSubview:self.commentView];
        [self setUserInteractionEnabled:YES];
    }
    return self;
}

- (void)dealloc
{
	delegate = nil;
    [commentView release];
    [super dealloc];
}


#pragma mark -
#pragma mark Event Handling

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.commentView.allowLikes)
    {
    	CGRect r = self.contentView.bounds;
    	int summary = self.commentView.theme.summaryStyle.font.pointSize + 3;
    
		int offset = (self.commentView.image == (id)[NSNull null] ? 0 : 25);
	
		CGSize s = [self.commentView.comment sizeWithFont:self.commentView.theme.detailStyle.font constrainedToSize:CGSizeMake(r.size.width - (15 + offset), 4000) lineBreakMode:UILineBreakModeWordWrap];
		CGSize timeSize = [self.commentView.time sizeWithFont:self.commentView.theme.timeStyle.font];
	
    	int likeOffset = offset + timeSize.width + 15;
	
		NSString* likeButtonString = ((self.commentView.userLikes) ? @"Unlike"  : @"Like");
		CGSize likeButtonSize = [likeButtonString sizeWithFont:self.commentView.theme.likeStyle.font];
	
		if (CGRectContainsPoint(CGRectMake(likeOffset, summary + s.height + 1, likeButtonSize.width + 4, likeButtonSize.height + 2), point))
			return YES;
    }
    return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.commentView.likeButtonDown = YES;
    [self.commentView setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.commentView.likeButtonDown = NO;
    [self.commentView setNeedsDisplay];
    
    [self performSelectorInBackground:@selector(changeUserLikes) withObject:nil];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.commentView.likeButtonDown = NO;
    [self.commentView setNeedsDisplay];
}

- (void)startLoading
{
	self.commentView.changeInProgress = YES;
	self.commentView.activity.hidden = NO;
	[self.commentView.activity startAnimating];
	[self.commentView setNeedsDisplay];
}

- (void)finishedLoading
{
	[self.commentView.activity stopAnimating];
	self.commentView.activity.hidden = YES;
	self.commentView.changeInProgress = NO;
	[self.commentView setNeedsDisplay];
}

- (void)changeUserLikes
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    [self performSelectorOnMainThread:@selector(startLoading) withObject:nil waitUntilDone:NO];
    
	FacebookAuth* auth = [[[FacebookAuth alloc] init] autorelease];
	
	NSString* httpMethod;
	
	if (self.commentView.userLikes)
		httpMethod = @"DELETE";
	else
		httpMethod = @"POST";
			
	if ([auth authorized])
	{
		NSString* url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/likes", self.commentID];
		NSString* fullURL = [[NSString stringWithFormat:@"%@&access_token=%@", url, auth.access_token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullURL]];
		[request setHTTPMethod:httpMethod];
          
		NSError* error = nil;
		NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
		
		if (error)
			DLog(@"LI: FB: Error liking comment");
		else
		{
			if (self.commentView.userLikes)
			{
				self.commentView.userLikes = NO;
				self.commentView.likes--;
			}
			else
			{
				self.commentView.userLikes = YES;
				self.commentView.likes++;
			}
				
			if ([self.delegate respondsToSelector:@selector(setUserLikes:forRowAtIndex:)])
				[self.delegate setUserLikes:self.commentView.userLikes forRowAtIndex:self.rowIndex];
        }
    }
	else
		DLog(@"LI: FB: Auth not authorised to like comment");
	
    [self performSelectorOnMainThread:@selector(finishedLoading) withObject:nil waitUntilDone:NO];
	[self.commentView setNeedsDisplay];
	[pool drain];
}

@end

@implementation FBCommentView

@synthesize name, time, image, theme, comment, allowLikes, likes, userLikes, likeButtonDown, changeInProgress, activity;

- (void)setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect) rect
{
	CGRect r = self.superview.bounds;
	int summary = self.theme.summaryStyle.font.pointSize + 3;
    
	int offset = (self.image == (id)[NSNull null] ? 0 : 25);
	[self.name drawInRect:CGRectMake(10 + offset, 0, (r.size.width - (15 + offset)), summary) withFont:self.theme.summaryStyle.font lineBreakMode:UILineBreakModeTailTruncation];
    
	CGSize s = [self.comment sizeWithFont:self.theme.detailStyle.font constrainedToSize:CGSizeMake(r.size.width - (15 + offset), 4000) lineBreakMode:UILineBreakModeWordWrap];
	[self.comment drawInRect:CGRectMake(10 + offset, summary, s.width, s.height + 1) withFont:self.theme.detailStyle.font lineBreakMode:UILineBreakModeWordWrap];
    
    CGSize timeSize = [self.time sizeWithFont:self.theme.timeStyle.font];
    [self.time drawInRect:CGRectMake(10 + offset, (summary + s.height + 2), timeSize.width, timeSize.height) withFont:self.theme.timeStyle.font lineBreakMode:UILineBreakModeClip];
	
    int likeOffset = offset + timeSize.width + 15;
    
    if (self.changeInProgress)
		self.activity.frame = CGRectMake(likeOffset + 5, summary + s.height + 2, timeSize.height, timeSize.height);
    else {
    
        if (self.allowLikes)
        {
            NSString* likeButtonString = ((self.userLikes) ? @"Unlike"  : @"Like");
            CGSize likeButtonSize = [likeButtonString sizeWithFont:self.theme.likeStyle.font];
        
            if (self.likeButtonDown)
                [[[[FBSharedDataController sharedInstance] pluginImage:@"LikeButtonBackground"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] drawInRect:CGRectMake(likeOffset, summary + s.height + 3, likeButtonSize.width + 4, likeButtonSize.height + 2)];
        
            [likeButtonString drawInRect:CGRectMake(likeOffset + 2, summary + s.height + 4, likeButtonSize.width, likeButtonSize.height) withFont:((self.likeButtonDown) ? self.theme.likeStyleDown.font : self.theme.likeStyle.font) lineBreakMode:UILineBreakModeTailTruncation];

            likeOffset += likeButtonSize.width + 7;
        }
        
        if (self.likes > 0)
        {
            [[[FBSharedDataController sharedInstance] pluginImage:@"LikeIcon"] drawInRect:CGRectMake(likeOffset, summary + s.height + 2, 15, 14)];
            CGSize likeSize = [[NSString stringWithFormat:@"%i Like%@", self.likes, ((self.likes > 1) ? @"s" : @"")] sizeWithFont:self.theme.likeStyle.font];
            [[NSString stringWithFormat:@"%i Like%@", self.likes, ((self.likes > 1) ? @"s" : @"")] drawInRect:CGRectMake(likeOffset + 18, summary + s.height + 4, likeSize.width, likeSize.height) withFont:self.theme.likeStyle.font lineBreakMode:UILineBreakModeTailTruncation];
        }
    }
    
	if (self.image != (id)[NSNull null] && self.image != nil)
		[self.image drawInRect:CGRectMake(5, 5, 25, 25)];
}

- (void)dealloc
{
    [activity release];
    [name release];
    [time release];
    [image release];
    [theme release];
    [comment release];
    [super dealloc];
}

@end