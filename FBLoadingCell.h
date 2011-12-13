#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SDK/Plugin.h"
#import "FBPreview.h"

@interface FBLoadingView : UIView
{
	FBPreviewTheme* theme;
	BOOL loading;
	UIActivityIndicatorView* activity;
	int noComments;
}

@property (nonatomic, retain) FBPreviewTheme* theme;
@property BOOL loading;
@property int noComments;
@property (nonatomic, retain) UIActivityIndicatorView* activity;

@end

@interface FBLoadingCell : UITableViewCell
{
    FBLoadingView* loadingView;
}

@property (nonatomic, retain) FBLoadingView* loadingView;

- (void)startLoading;
- (void)finishedLoading;

@end
