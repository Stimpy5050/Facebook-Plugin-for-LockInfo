#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SDK/Plugin.h"
#import "FBPreview.h"

@interface FBNotificationView : UIView
{

	NSString* notification;
	NSString* time;
	UIImage* image;
	FBPreviewTheme* theme;
}

@property (nonatomic, retain) NSString* notification;
@property (nonatomic, retain) NSString* time;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, retain) FBPreviewTheme* theme;

@end

@interface FBNotificationCell : UITableViewCell
{
    FBNotificationView* notifView;
}

@property (nonatomic, retain) FBNotificationView* notifView;

@end
