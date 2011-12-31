#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PullToRefreshView.h"
#import "SDK/Plugin.h"
#import "FBPreview.h"
#import "FBTextView.h"

@interface FBCommentsPreview : UIViewController <UITableViewDataSource, UITableViewDelegate, FBPreviewDelegate, PullToRefreshViewDelegate, UITextViewDelegate>
{
	FBPreviewTheme* theme;
	NSMutableArray* comments;
	FBTextView* _textView;
	UITableView* _tableView;
	NSString* postID;
    NSString* name;
    NSString* post;
    NSString* time;
    UIImage* image;
    id delegate;
    id loadingDelegate;
    int streamRowIndex;
    int noComments;
    int noLikes;
    BOOL userLikes;
    BOOL allowLikes;
    BOOL allowComments;
    BOOL shouldLoadWithKeyboard;
    PullToRefreshView* pull;
    NSDate* lastUpdate;
    BOOL showingKeyboard;
    CGFloat keyboardHeight;
    BOOL postingComment;
    BOOL loadingData;
    BOOL pendingClear;
}

@property (nonatomic, retain) FBPreviewTheme* theme;
@property (nonatomic, retain) NSMutableArray* comments;
@property (nonatomic, retain) FBTextView* textView;
@property (nonatomic, retain) UITableView* tableView;
@property (nonatomic, retain) NSString* postID;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* post;
@property (nonatomic, retain) NSString* time;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, retain) NSDate* lastUpdate;
@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) id loadingDelegate;
@property int noComments;
@property int noLikes;
@property BOOL userLikes;
@property BOOL allowLikes;
@property BOOL allowComments;
@property BOOL shouldLoadWithKeyboard;
@property int streamRowIndex;
@property BOOL showingKeyboard;
@property CGFloat keyboardHeight;
@property BOOL postingComment;
@property BOOL loadingData;
@property BOOL pendingClear;

// Keyboard methods
- (void)scrollToLastRow;
- (void)resizeViews;
- (void)insertLoadingCellAtLastIndex;
- (void)keyboardWillShow:(NSNotification*)notification;
- (void)keyboardWillHide:(NSNotification*)notification;

// Comment methods
- (void)sendComment:(NSString*)comment;
- (void)sendCommentInBackground:(NSString*)comment;
- (void)sendButtonPressed;
- (void)cancelButtonPressed;

// Update methods
- (void)reloadComments;
- (void)finishedLoadingComments;
- (void)setUserLikes:(BOOL)likes forRowAtIndex:(int)index;
- (void)setUserLikesPost:(BOOL)likes;
- (void)updateStreamComments;
- (void)updateStreamLikes;

@end