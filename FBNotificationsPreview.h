#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PullToRefreshView.h"
#import "FBPreview.h"
#import "SDK/Plugin.h"

@interface FBNotificationsPreview : UIViewController <UITableViewDataSource, UITableViewDelegate, FBPreviewDelegate, PullToRefreshViewDelegate>
{
	FBPreviewTheme* theme;
	NSMutableArray* notifications;
    id delegate;
    PullToRefreshView* pull;
    NSDate* lastUpdate;
    UITableView* _tableView;
}

@property (nonatomic, retain) FBPreviewTheme* theme;
@property (nonatomic, retain) NSMutableArray* notifications;
@property (nonatomic, retain) NSDate* lastUpdate;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UITableView* tableView;

- (void)updateNotifications;

@end