#import "FBPostCell.h"
#import "FBSingletons.h"

@implementation FBPostCell

@synthesize postView, optionsButtonDown, infoButtonDown, buttonTouch, delegate, rowIndex;

#pragma mark -
#pragma mark init and dealloc

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        CGRect pvFrame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
        self.postView = [[FBPostView alloc] initWithFrame:pvFrame];
        self.postView.backgroundColor = [UIColor clearColor];
        self.postView.optionsButtonName = @"CommentButton";
        self.postView.infoButtonName = @"PostInfoBackground";
        self.postView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.postView];
        [self setUserInteractionEnabled:YES];
    }
    return self;
}

- (void)dealloc
{
    [postView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Event Handling

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect r = self.contentView.bounds;
    if (self.postView.allowComments || self.postView.allowLikes)
    {
        if (CGRectContainsPoint(CGRectMake(r.size.width - 30, (int)((r.size.height / 2) - 16), 28, 32), point))
 		{
 			self.buttonTouch = kOptionsButtonTouch;
            return YES;
        }
    }
    
    if ((self.postView.noLikes > 0) || (self.postView.noComments > 0))
    {
    	int leftOffset = (self.postView.image == (id)[NSNull null] ? 0 : 25);
    
        if ((self.postView.noLikes > 0) && (self.postView.noComments > 0))
    	{
        	CGSize textSize = [[NSString stringWithFormat:@"%i Like%@ %i Comment%@", self.postView.noLikes, ((self.postView.noLikes > 1) ? @"s" : @""), self.postView.noComments, ((self.postView.noComments > 1) ? @"s" : @"")] sizeWithFont:[self.postView.theme.summaryStyle.font fontWithSize:self.postView.theme.summaryStyle.font.pointSize - 3]];
			if (CGRectContainsPoint(CGRectMake(leftOffset + 5, r.size.height - 35, 60 +  textSize.width, 32), point))
			{
				self.buttonTouch = kInfoButtonTouch;
				return YES;
			}
		}
    	else if (self.postView.noLikes > 0)
    	{
        	CGSize likeSize = [[NSString stringWithFormat:@"%i Like%@", self.postView.noLikes, ((self.postView.noLikes > 1) ? @"s" : @"")] sizeWithFont:[self.postView.theme.summaryStyle.font fontWithSize:self.postView.theme.summaryStyle.font.pointSize - 3]];
        	if (CGRectContainsPoint(CGRectMake(leftOffset + 5, r.size.height - 35, 35 +  likeSize.width, 32), point))
			{
				self.buttonTouch = kInfoButtonTouch;
				return YES;
			}
    	}
    	else if (self.postView.noComments > 0)
    	{
        	CGSize commentSize = [[NSString stringWithFormat:@"%i Comment%@", self.postView.noComments, ((self.postView.noComments > 1) ? @"s" : @"")] sizeWithFont:[self.postView.theme.summaryStyle.font fontWithSize:self.postView.theme.summaryStyle.font.pointSize - 3]];
			if (CGRectContainsPoint(CGRectMake(leftOffset + 5, r.size.height - 35, 35 +  commentSize.width, 32), point))
			{
				self.buttonTouch = kInfoButtonTouch;
				return YES;
			}
    	}
    }
    
    return NO;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (self.buttonTouch == kOptionsButtonTouch)
	{
    	self.optionsButtonDown = YES;
    	self.postView.optionsButtonName = @"CommentButtonDown";
    }
    else if (self.buttonTouch == kInfoButtonTouch)
    {
    	self.infoButtonDown = YES;
    	self.postView.infoButtonName = @"PostInfoBackgroundDown";
    }
    
    [self.postView setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.optionsButtonDown = NO;
    self.infoButtonDown = NO;
    self.postView.optionsButtonName = @"CommentButton";
    self.postView.infoButtonName = @"PostInfoBackground";
    [self.postView setNeedsDisplay];
    
    if (self.buttonTouch == kOptionsButtonTouch)
	{
    	CGRect r = self.contentView.bounds;
    	CGPoint windowLocation = [self convertPoint:CGPointMake(r.size.width - 35, (int)(r.size.height / 2)) toView:nil];
    	if ([self.delegate respondsToSelector:@selector(showOptionsViewForRowAtIndex:arrowPoint:)])
        	[self.delegate showOptionsViewForRowAtIndex:self.rowIndex arrowPoint:windowLocation];
	}
	else if (self.buttonTouch == kInfoButtonTouch)
	{
		if ([self.delegate respondsToSelector:@selector(infoButtonPressedForRowAtIndex:)])
			[self.delegate infoButtonPressedForRowAtIndex:self.rowIndex];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.optionsButtonDown)
    {
        self.optionsButtonDown = NO;
        self.postView.optionsButtonName = @"CommentButton";
        [self.postView setNeedsDisplay];
    }
    
    if (self.infoButtonDown)
    {
    	self.infoButtonDown = NO;
    	self.postView.infoButtonName = @"PostInfoBackground";
    	[self.postView setNeedsDisplay];
    }
}

@end

@implementation FBPostView

@synthesize name, time, image, theme, message, noComments, noLikes, allowComments, allowLikes, optionsButtonName, infoButtonName;

- (void)setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect) rect
{
	CGRect r = self.superview.bounds;
	int summary = self.theme.summaryStyle.font.pointSize + 3;
    
	int leftOffset = (self.image == (id)[NSNull null] ? 0 : 25);
    int rightOffset = ((self.allowComments || self.allowLikes) ? 27 : 0);
    
	[self.name drawInRect:CGRectMake(leftOffset + 10, 0, r.size.width - (10 + leftOffset), summary) withLIStyle:self.theme.summaryStyle lineBreakMode:UILineBreakModeTailTruncation];
	
	CGSize s = [self.message sizeWithFont:self.theme.detailStyle.font constrainedToSize:CGSizeMake(r.size.width - (10 + leftOffset + rightOffset), 4000) 
                            lineBreakMode:UILineBreakModeWordWrap];
	[self.message drawInRect:CGRectMake(leftOffset + 10, summary, s.width, s.height + 1) withLIStyle:self.theme.detailStyle lineBreakMode:UILineBreakModeWordWrap];
    
    LIStyle* timeStyle = [self.theme.summaryStyle copy];
	timeStyle.font = [timeStyle.font fontWithSize:timeStyle.font.pointSize - 3];
    CGSize timeSize = [self.time sizeWithFont:timeStyle.font];
    [self.time drawInRect:CGRectMake(leftOffset + 10, summary + s.height + 2, timeSize.width, timeSize.height) withLIStyle:timeStyle lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
    
	if (self.image != (id)[NSNull null] && self.image != nil)
		[self.image drawInRect:CGRectMake(5, 5, 25, 25)];
    
    if (self.allowComments || self.allowLikes)
        [[[FBSharedDataController sharedInstance] pluginImage:self.optionsButtonName] drawInRect:CGRectMake(r.size.width - 25, (int)((r.size.height / 2) - 11), 18, 22)];
    
    int topOfInfo = summary + s.height + timeSize.height + 4;
    timeStyle.textColor = [UIColor colorWithRed:87.0/255.0 green:107.0/255.0 blue:149.0/255.0 alpha:1.0];
    
    if ((self.noLikes > 0) && (self.noComments > 0))
    {
        CGSize likeSize = [[NSString stringWithFormat:@"%i Like%@", self.noLikes, ((self.noLikes > 1) ? @"s" : @"")] sizeWithFont:timeStyle.font];
        CGSize commentSize = [[NSString stringWithFormat:@"%i Comment%@", self.noComments, ((self.noComments > 1) ? @"s" : @"")] sizeWithFont:timeStyle.font];
        [[[[FBSharedDataController sharedInstance] pluginImage:self.infoButtonName] stretchableImageWithLeftCapWidth:5 topCapHeight:5] 
                                                                                    drawInRect:CGRectMake(leftOffset + 10, topOfInfo, 55 +  likeSize.width + commentSize.width, 25)];
        [[[FBSharedDataController sharedInstance] pluginImage:@"LikeIcon"] drawInRect:CGRectMake(leftOffset + 15, topOfInfo + 4, 15, 14)];
        [[[FBSharedDataController sharedInstance] pluginImage:@"CommentsIcon"] drawInRect:CGRectMake(leftOffset + 36 + likeSize.width, topOfInfo + 3, 15, 19)];
        [[NSString stringWithFormat:@"%i Like%@", self.noLikes, ((self.noLikes > 1) ? @"s" : @"")] drawInRect:CGRectMake(leftOffset + 33, topOfInfo + (int)(12 - (likeSize.height / 2)), likeSize.width, likeSize.height) 
                                                              withLIStyle:timeStyle lineBreakMode:UILineBreakModeTailTruncation];
        [[NSString stringWithFormat:@"%i Comment%@", self.noComments, ((self.noComments > 1) ? @"s" : @"")] drawInRect:CGRectMake(leftOffset + 54 + likeSize.width, topOfInfo + (int)(12 - (commentSize.height / 2)), commentSize.width, commentSize.height) withLIStyle:timeStyle lineBreakMode:UILineBreakModeClip];
    }
    else if (self.noLikes > 0)
    {
        CGSize likeSize = [[NSString stringWithFormat:@"%i Like%@", self.noLikes, ((self.noLikes > 1) ? @"s" : @"")] sizeWithFont:timeStyle.font];
        [[[[FBSharedDataController sharedInstance] pluginImage:@"PostInfoBackground"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] 
                                                                                    drawInRect:CGRectMake(leftOffset + 10, topOfInfo, 30 +  likeSize.width, 25)];
        [[[FBSharedDataController sharedInstance] pluginImage:@"LikeIcon"] drawInRect:CGRectMake(leftOffset + 15, topOfInfo + 4, 15, 14)];
        [[NSString stringWithFormat:@"%i Like%@", self.noLikes, ((self.noLikes > 1) ? @"s" : @"")] drawInRect:CGRectMake(leftOffset + 33, topOfInfo + (int)(12 - (likeSize.height / 2)), likeSize.width, likeSize.height) 
                                                              withLIStyle:timeStyle lineBreakMode:UILineBreakModeClip];
    }
    else if (self.noComments > 0)
    {
        CGSize commentSize = [[NSString stringWithFormat:@"%i Comment%@", self.noComments, ((self.noComments > 1) ? @"s" : @"")] sizeWithFont:timeStyle.font];
        [[[[FBSharedDataController sharedInstance] pluginImage:@"PostInfoBackground"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] 
                                                                                    drawInRect:CGRectMake(leftOffset + 10, topOfInfo, 30 +  commentSize.width, 25)];
        [[[FBSharedDataController sharedInstance] pluginImage:@"CommentsIcon"] drawInRect:CGRectMake(leftOffset + 15, topOfInfo + 3, 15, 19)];
        [[NSString stringWithFormat:@"%i Comment%@", self.noComments, ((self.noComments > 1) ? @"s" : @"")] drawInRect:CGRectMake(leftOffset + 33, topOfInfo + (int)(12 - (commentSize.height / 2)), commentSize.width, commentSize.height) withLIStyle:timeStyle lineBreakMode:UILineBreakModeClip];
    }
                           
    [timeStyle release];
}

- (void)dealloc
{
    [name release];
    [time release];
    [optionsButtonName release];
    [infoButtonName release];
    [image release];
    [theme release];
    [message release];
    [super dealloc];
}

@end