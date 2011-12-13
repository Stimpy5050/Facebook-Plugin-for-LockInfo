#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FBButtonCell : UITableViewCell
{
    id delegate;
    UIButton* notificationsButton;
    UIButton* statusButton;
    UIImageView* backgroundLIView;
    BOOL allowStatus;
    BOOL allowNotifications;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UIButton* notificationsButton;
@property (nonatomic, retain) UIButton* statusButton;
@property (nonatomic, retain) UIImageView* backgroundLIView;
@property BOOL allowStatus;
@property BOOL allowNotifications;

- (void)statusButtonTapped:(id)sender;
- (void)notifButtonTapped:(id)sender;

@end

