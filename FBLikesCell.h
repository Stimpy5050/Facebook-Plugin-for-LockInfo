#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SDK/Plugin.h"
#import "FBPreview.h"

@interface FBLikesView : UIView
{
	FBPreviewTheme* theme;
	int likes;
	BOOL userLikes;
	BOOL likeButtonDown;
	BOOL allowLikes;
    BOOL showImages;
    BOOL changeInProgress;
    UIActivityIndicatorView* activity;
}

@property (nonatomic, retain) FBPreviewTheme* theme;
@property int likes;
@property BOOL userLikes;
@property BOOL likeButtonDown;
@property BOOL allowLikes;
@property BOOL showImages;
@property BOOL changeInProgress;
@property (nonatomic, retain) UIActivityIndicatorView* activity;

@end

@interface FBLikesCell : UITableViewCell
{
    FBLikesView* likesView;
    NSString* postID;
    id delegate;
}

@property (nonatomic, retain) FBLikesView* likesView;
@property (nonatomic, retain) NSString* postID;
@property (nonatomic, assign) id delegate;

- (void)changeUserLikes;
- (void)startLoading;
- (void)finishedLoading;

@end