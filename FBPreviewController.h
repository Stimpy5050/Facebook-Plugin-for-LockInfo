#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SDK/Plugin.h"
#import "FBNewPostPreview.h"
#import "FBNotificationsPreview.h"
#import "FBCommentsPreview.h"
#import "FBPreview.h"

@interface  FBPreviewController : UINavigationController <LIPreviewDelegate>
{
    FBCommentsPreview* commentsPreview;
    FBNewPostPreview* newPostPreview;
    FBNotificationsPreview* notifPreview;
    id delegate;
    FBPreviewTheme* previewTheme;
}

@property (nonatomic, retain) FBCommentsPreview* commentsPreview;
@property (nonatomic, retain) FBNewPostPreview* newPostPreview;
@property (nonatomic, retain) FBNotificationsPreview* notifPreview;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) FBPreviewTheme* previewTheme;

- (void)setUserID:(NSString*)userID;
- (void)setKeyboardShouldShow:(BOOL)show;
- (void)setPostData:(NSDictionary*)postData forRowAtIndex:(int)index;
- (void)displayPreview:(int)preview;
- (void)clearPreview;
- (void)setTheme:(LITheme*)theme;

@end