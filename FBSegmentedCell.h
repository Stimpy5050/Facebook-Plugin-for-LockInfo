#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FBSegmentedCell : UITableViewCell
{
    id delegate;
    UISegmentedControl* segmentedView;
    UIImageView* backgroundLIView;
    BOOL allowStatus;
    BOOL allowNotifications;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UISegmentedControl* segmentedView;
@property (nonatomic, retain) UIImageView* backgroundLIView;
@property BOOL allowStatus;
@property BOOL allowNotifications;

- (void)statusButtonTapped;
- (void)notifButtonTapped;

@end

