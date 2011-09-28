#import "FBNotificationCell.h"

@implementation FBNotificationCell

@synthesize notifView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) 
	{
        
        CGRect nvFrame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
        self.notifView = [[FBNotificationView alloc] initWithFrame:nvFrame];
        self.notifView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.notifView.opaque = YES;
        self.notifView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:self.notifView];
    }
    return self;
}

- (void)dealloc
{
    [notifView release];
    [super dealloc];
}

@end

@implementation FBNotificationView

@synthesize time, image, theme, notification;

- (void)setFrame:(CGRect) r
{
	[super setFrame:r];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect) rect
{
	CGRect r = self.superview.bounds;
    
	int offset = (self.image == (id)[NSNull null] ? 0 : 25);
	
	CGSize s = [self.notification sizeWithFont:self.theme.detailStyle.font constrainedToSize:CGSizeMake(r.size.width - (15 + offset), 4000) lineBreakMode:UILineBreakModeWordWrap];
	[self.notification drawInRect:CGRectMake(10 + offset, 1, s.width, s.height + 1) withFont:self.theme.detailStyle.font lineBreakMode:UILineBreakModeWordWrap];
    
    LIStyle* timeStyle = [self.theme.summaryStyle copy];
	timeStyle.font = [timeStyle.font fontWithSize:timeStyle.font.pointSize - 3];
    CGSize timeSize = [self.time sizeWithFont:timeStyle.font];
    [self.time drawInRect:CGRectMake(10 + offset, (s.height + 2), timeSize.width, timeSize.height) withFont:timeStyle.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
    
    [timeStyle release];
    
	if (self.image != (id)[NSNull null] && self.image != nil)
		[self.image drawInRect:CGRectMake(5, 5, 25, 25)];
}

- (void)dealloc
{
    [notification release];
    [time release];
    [image release];
    [theme release];
    [super dealloc];
}

@end