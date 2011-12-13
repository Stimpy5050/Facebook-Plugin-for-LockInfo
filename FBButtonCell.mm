#import "FBButtonCell.h"
#import "FBSingletons.h"

@implementation FBButtonCell

@synthesize delegate, notificationsButton, statusButton, backgroundLIView, allowStatus, allowNotifications;

#pragma mark -
#pragma mark init and dealloc

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        CGRect frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
        int center = frame.size.width / 2;
        
        self.backgroundLIView = [[UIImageView alloc] initWithFrame:frame];
        self.backgroundLIView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:self.backgroundLIView];
        
        self.statusButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.statusButton.frame = CGRectMake((center - 138), 3, 130, 36);
        self.statusButton.imageEdgeInsets = UIEdgeInsetsMake(0, -3, 0, 3);
        //self.statusButton.adjustsImageWhenHighlighted = NO;
        [self.statusButton setTitle:@"Status" forState:UIControlStateNormal];
        [self.statusButton setImage:[[FBSharedDataController sharedInstance] pluginImage:@"StatusIcon"] forState:UIControlStateNormal];
        [self.statusButton setBackgroundImage:[[[FBSharedDataController sharedInstance] pluginImage:@"ButtonBackground"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] 
                                forState:UIControlStateNormal];
        [self.statusButton setBackgroundImage:[[[FBSharedDataController sharedInstance] pluginImage:@"ButtonBackgroundDown"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] 
                                forState:UIControlStateHighlighted];
        [self.statusButton addTarget:self action:@selector(statusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.statusButton];
        
        self.notificationsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.notificationsButton.frame = CGRectMake((center + 8), 3, 130, 36);
        self.notificationsButton.imageEdgeInsets = UIEdgeInsetsMake(0, -3, 0, 3);
        //self.notificationsButton.adjustsImageWhenHighlighted = NO;
        [self.notificationsButton setTitle:@"Notifications" forState:UIControlStateNormal];
        [self.notificationsButton setImage:[[FBSharedDataController sharedInstance] pluginImage:@"NotificationIcon"] forState:UIControlStateNormal];
        [self.notificationsButton setBackgroundImage:[[[FBSharedDataController sharedInstance] pluginImage:@"ButtonBackground"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] 
                               forState:UIControlStateNormal];
        [self.notificationsButton setBackgroundImage:[[[FBSharedDataController sharedInstance] pluginImage:@"ButtonBackgroundDown"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] 
                               forState:UIControlStateHighlighted];
        [self.notificationsButton addTarget:self action:@selector(notifButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.notificationsButton];
    }
    return self;
}

- (void)statusButtonTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(statusButtonTapped)])
        [self.delegate statusButtonTapped];
}

- (void)notifButtonTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(notifButtonTapped)])
        [self.delegate notifButtonTapped];
    
}

- (void)layoutSubviews;
{
    int center = self.contentView.bounds.size.width / 2;
    
    if ((self.allowStatus) && (self.allowNotifications))
    {
        self.statusButton.hidden = NO;
        self.notificationsButton.hidden = NO;
        self.statusButton.frame = CGRectMake((center - 138), 3, 130, 36);
        self.notificationsButton.frame = CGRectMake((center + 8), 3, 130, 36);
    }
    else if (self.allowStatus)
    {
        self.statusButton.hidden = NO;
        self.notificationsButton.hidden = YES;
        self.statusButton.frame = CGRectMake(center - 65, 3, 130, 36);
    }
    else if (self.allowNotifications)
    {
        self.statusButton.hidden = YES;
        self.notificationsButton.hidden = NO;
        self.notificationsButton.frame = CGRectMake(center - 65, 3, 130, 36);
    }
    else
    {
        self.statusButton.hidden = YES;
        self.notificationsButton.hidden = YES;
    }
}

- (void)dealloc
{
    delegate = nil;
    [notificationsButton release];
    [statusButton release];
    [backgroundLIView release];
    [super dealloc];
}

@end
