#import "FBSegmentedCell.h"
#import "FBSingletons.h"

@implementation FBSegmentedCell

@synthesize delegate, segmentedView, backgroundLIView, allowStatus, allowNotifications;

#pragma mark -
#pragma mark init and dealloc

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) {
        CGRect frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
        
        self.backgroundLIView = [[UIImageView alloc] initWithFrame:frame];
        self.backgroundLIView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:self.backgroundLIView];
        
        NSArray* buttons = [NSArray arrayWithObjects:@"Status", @"Notifications", nil];
        self.segmentedView = [[[UISegmentedControl alloc] initWithItems:buttons] autorelease];
        self.segmentedView.frame = frame;
        self.segmentedView.segmentedControlStyle = UISegmentedControlStyleBar;
        self.segmentedView.momentary = YES;
        self.segmentedView.tintColor = [UIColor clearColor];
        [self.segmentedView addTarget:self action:@selector(segmentTapped:) forControlEvents:UIControlEventValueChanged];
        self.segmentedView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:self.segmentedView];
    }
    return self;
}

- (void)segmentTapped:(id)sender
{
    int selected = [sender selectedSegmentIndex];
    
    switch (selected) 
    {
        case 0:
            
            if (self.allowStatus)
                [self statusButtonTapped];
            
            else if (self.allowNotifications)
                [self notifButtonTapped];
            
            break;
            
        case 1:
            
            if ((self.allowStatus) && (self.allowNotifications))
                [self notifButtonTapped];
            
            break;

        default:
            return;
    }
}

- (void)statusButtonTapped
{
    if ([self.delegate respondsToSelector:@selector(statusButtonTapped)])
        [self.delegate statusButtonTapped];
}

- (void)notifButtonTapped
{
    if ([self.delegate respondsToSelector:@selector(notifButtonTapped)])
        [self.delegate notifButtonTapped];
}

- (void)layoutSubviews;
{
    [self.segmentedView removeAllSegments];
    
    if ((self.allowStatus) && (self.allowNotifications))
    {
        [self.segmentedView insertSegmentWithTitle:@"Status" atIndex:0 animated:NO];
        [self.segmentedView insertSegmentWithTitle:@"Notifications" atIndex:1 animated:NO];
    }
    else if (self.allowStatus)
    {
        [self.segmentedView insertSegmentWithTitle:@"Status" atIndex:0 animated:NO];
    }
    else if (self.allowNotifications)
    {
        [self.segmentedView insertSegmentWithTitle:@"Status" atIndex:0 animated:NO];
    }
}

- (void)dealloc
{
    delegate = nil;
    [segmentedView release];
    [backgroundLIView release];
    [super dealloc];
}

@end
