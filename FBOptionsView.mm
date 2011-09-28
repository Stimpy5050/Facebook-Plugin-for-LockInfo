#import "FBOptionsView.h"
#import "FBSingletons.h"
#import "SDK/Plugin.h"

@implementation FBOptionsView

@synthesize delegate, optionsContainer, likeButton, commentButton, buttonTypes, arrowPoint;

- (id)init
{ 
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    if (self = [super initWithFrame:frame])
    {    
        self.optionsContainer = [[[UIView alloc] initWithFrame:CGRectMake(210, 50, 200, 44)] autorelease];
        self.optionsContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        UIImageView* backgroundImage = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)] autorelease];
        backgroundImage.image = [[[FBSharedDataController sharedInstance] pluginImage:@"PopoverBackground"] stretchableImageWithLeftCapWidth:25 topCapHeight:20];
        [self.optionsContainer addSubview:backgroundImage];
        
        self.likeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.likeButton.frame = CGRectMake(5, 7, 70, 30);
        self.likeButton.imageEdgeInsets = UIEdgeInsetsMake(0, -3, 0, 3);
        [self.likeButton setTitle:@"Like" forState:UIControlStateNormal];
        [self.likeButton setImage:[[FBSharedDataController sharedInstance] pluginImage:@"LikeIcon"] forState:UIControlStateNormal];
        [self.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.likeButton setBackgroundImage:[[[FBSharedDataController sharedInstance] pluginImage:@"SmallButtonBackground"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] 
                                   forState:UIControlStateNormal];
        [self.likeButton setBackgroundImage:[[[FBSharedDataController sharedInstance] pluginImage:@"SmallButtonBackgroundDown"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] 
                                   forState:UIControlStateHighlighted];
        [self.optionsContainer addSubview:self.likeButton];
        
        self.commentButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.commentButton.frame = CGRectMake(80, 7, 100, 30);
        self.commentButton.imageEdgeInsets = UIEdgeInsetsMake(0, -3, 0, 3);
        [self.commentButton setTitle:@"Comment" forState:UIControlStateNormal];
        [self.commentButton setImage:[[FBSharedDataController sharedInstance] pluginImage:@"CommentsIcon"] forState:UIControlStateNormal];
        [self.commentButton addTarget:self action:@selector(commentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.commentButton setBackgroundImage:[[[FBSharedDataController sharedInstance] pluginImage:@"SmallButtonBackground"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] 
                                      forState:UIControlStateNormal];
        [self.commentButton setBackgroundImage:[[[FBSharedDataController sharedInstance] pluginImage:@"SmallButtonBackgroundDown"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] 
                                      forState:UIControlStateHighlighted];
        [self.optionsContainer addSubview:self.commentButton];
        
        [self addSubview:self.optionsContainer];
        
        self.buttonTypes = kOptionsViewLikeAndCommentButtons;
    }
    return self;
}

- (void)dealloc
{
    delegate = nil;
    [optionsContainer release];
    [likeButton release];
    [commentButton release];
    [super dealloc];
}

- (void)setButtons:(int)buttons
{
	self.buttonTypes = buttons;
	[self setNeedsLayout];
}

- (void)likeButtonTapped:(id)sender
{
    [self removeFromSuperview];
    
    if ([self.delegate respondsToSelector:@selector(likeButtonTapped)])
        [self.delegate likeButtonTapped];
}

- (void)commentButtonTapped:(id)sender
{
    [self removeFromSuperview];
    
    if ([self.delegate respondsToSelector:@selector(commentButtonTapped)])
        [self.delegate commentButtonTapped];
}

- (void)setArrowPoint:(CGPoint)point
{
	arrowPoint = point;
    self.frame = [[UIScreen mainScreen] bounds];
    self.optionsContainer.frame = CGRectMake(arrowPoint.x - 200, arrowPoint.y-22, 200, 44);
    [self.optionsContainer setNeedsLayout];
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event 
{
    if (CGRectContainsPoint(self.optionsContainer.frame, point))
    {
        return [super hitTest:point withEvent:event];
    } else {
        [self removeFromSuperview];
    }
    
    return [[[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0] hitTest:point withEvent:event];
}

- (void)layoutSubviews
{
	switch (self.buttonTypes)
	{
		case kOptionsViewLikeAndCommentButtons:
            [self.likeButton setTitle:@"Like" forState:UIControlStateNormal];
			self.likeButton.hidden = NO;
			self.commentButton.hidden = NO;
			self.likeButton.frame = CGRectMake(5, 7, 70, 30);
			self.commentButton.frame = CGRectMake(80, 7, 100, 30);
			self.optionsContainer.frame = CGRectMake(self.arrowPoint.x - 200, self.arrowPoint.y-22, 200, 44);
			break;
			
		case kOptionsViewCommentButtonOnly:
			self.likeButton.hidden = YES;
			self.commentButton.hidden = NO;
			self.commentButton.frame = CGRectMake(5, 7, 100, 30);
			self.optionsContainer.frame = CGRectMake(self.arrowPoint.x - 125, self.arrowPoint.y-22, 125, 44);
			break;
		
		case kOptionsViewLikeButtonOnly:
            [self.likeButton setTitle:@"Like" forState:UIControlStateNormal];
			self.likeButton.hidden = NO;
			self.commentButton.hidden = YES;
			self.likeButton.frame = CGRectMake(5, 7, 70, 30);
			self.optionsContainer.frame = CGRectMake(self.arrowPoint.x - 95, self.arrowPoint.y-22, 95, 44);
			break;
            
        case kOptionsViewUnlikeAndCommentButtons:
            [self.likeButton setTitle:@"Unlike" forState:UIControlStateNormal];
            self.likeButton.hidden = NO;
			self.commentButton.hidden = NO;
			self.likeButton.frame = CGRectMake(5, 7, 70, 30);
			self.commentButton.frame = CGRectMake(80, 7, 100, 30);
			self.optionsContainer.frame = CGRectMake(self.arrowPoint.x - 200, self.arrowPoint.y-22, 200, 44);
            break;
            
        case kOptionsViewUnlikeButtonOnly:
            [self.likeButton setTitle:@"Unlike" forState:UIControlStateNormal];
			self.likeButton.hidden = NO;
			self.commentButton.hidden = YES;
			self.likeButton.frame = CGRectMake(5, 7, 70, 30);
			self.optionsContainer.frame = CGRectMake(self.arrowPoint.x - 95, self.arrowPoint.y-22, 95, 44);
			break;
            
		default:
			break;
	}
}

@end
