#import "FBLoadingCell.h"

@implementation FBLoadingCell

@synthesize loadingView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        
        CGRect lvFrame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
        self.loadingView = [[FBLoadingView alloc] initWithFrame:lvFrame];
        self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.loadingView.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		[self.loadingView addSubview:self.loadingView.activity];
		self.loadingView.activity.hidden == YES;
        [self.contentView addSubview:self.loadingView];
    }
    return self;
}

- (void)dealloc
{
    [loadingView release];
    [super dealloc];
}

- (void)startLoading
{
	self.loadingView.loading = YES;
	self.loadingView.activity.hidden = NO;
	[self.loadingView.activity startAnimating];
	[self.loadingView setNeedsDisplay];
}

- (void)finishedLoading
{
	[self.loadingView.activity stopAnimating];
	self.loadingView.hidden = YES;
	self.loadingView.loading = NO;
	[self.loadingView setNeedsDisplay];
}

@end

@implementation FBLoadingView

@synthesize theme, loading, noComments, activity;

- (void)setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect) rect
{
	CGRect r = self.superview.bounds;
	
    if (self.loading)
	{
		CGSize activitySize = self.activity.frame.size;
		self.activity.frame = CGRectMake((int)((r.size.width - activitySize.width) / 2), (int)((r.size.height - activitySize.height) / 2), activitySize.width, activitySize.height);
	}
    
    if (!self.loading)
    {
        NSString* text = [NSString stringWithFormat:@"Load all %i comments", self.noComments];
	
        CGSize s = [text sizeWithFont:self.theme.summaryStyle.font constrainedToSize:CGSizeMake(r.size.width - 10, 4000) lineBreakMode:UILineBreakModeWordWrap];
        [self.theme.summaryStyle.textColor set];
        [text drawInRect:CGRectMake((int)((r.size.width - s.width) / 2), (int)((r.size.height - s.height) / 2), s.width, s.height) withFont:self.theme.summaryStyle.font lineBreakMode:UILineBreakModeWordWrap];
    }
}

- (void)dealloc
{
    [activity release];
    [theme release];
    [super dealloc];
}

@end