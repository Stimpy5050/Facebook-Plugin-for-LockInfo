#import <Foundation/Foundation.h>
#import "FBPreview.h"

@interface FBCommentView : UIView
{
	NSString* name;
	NSString* comment;
	NSString* time;
	UIImage* image;
	FBPreviewTheme* theme;
	BOOL allowLikes;
	int likes;
	BOOL userLikes;
	BOOL likeButtonDown;
    BOOL changeInProgress;
    UIActivityIndicatorView* activity;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* comment;
@property (nonatomic, retain) NSString* time;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, retain) FBPreviewTheme* theme;
@property BOOL allowLikes;
@property int likes;
@property BOOL userLikes;
@property BOOL likeButtonDown;
@property BOOL changeInProgress;
@property (nonatomic, retain) UIActivityIndicatorView* activity;

@end

@interface FBCommentCell : UITableViewCell
{
    FBCommentView* commentView;
    NSString* commentID;
    id delegate;
    int rowIndex;
}

@property (nonatomic, retain) FBCommentView* commentView;
@property (nonatomic, retain) NSString* commentID;
@property (nonatomic, assign) id delegate;
@property int rowIndex;

- (void)changeUserLikes;
- (void)startLoading;
- (void)finishedLoading;

@end

