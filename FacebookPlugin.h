#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SDK/Plugin.h"
#import "FBPreviewController.h"
#import "FBOptionsView.h"

@interface FacebookPlugin : UIViewController <LIPluginController, LITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIScrollViewDelegate> 
{
	NSTimeInterval nextUpdate;
	NSDateFormatter* formatter;
	NSConditionLock* lock;
    LIPlugin* plugin;
    NSMutableArray* feedPosts;
    FBPreviewController* previewController;
    FBOptionsView* optionsView;
    NSString* currentUserID;
    int currentOptionsCell;
    LITheme* theme;
}

@property (nonatomic, retain) LIPlugin* plugin;
@property (nonatomic, retain) NSMutableArray* feedPosts;
@property (nonatomic, retain) FBPreviewController* previewController;
@property (nonatomic, retain) FBOptionsView* optionsView;
@property (nonatomic, retain) NSString* currentUserID;
@property (nonatomic, retain) LITheme* theme;
@property int currentOptionsCell;

// Button action methods
- (void)removePopover;
- (void)showOptionsViewForRowAtIndex:(int)index arrowPoint:(CGPoint)arrowPoint;
- (void)infoButtonPressedForRowAtIndex:(int)index;
- (void)notifButtonTapped;
- (void)statusButtonTapped;
- (void)likeButtonTapped;
- (void)commentButtonTapped;

// Preview methods
- (void)displayKeyboard:(UIView*)keyboard;
- (void)resignKeyboard;
- (void)displayPreview:(int)preview;

// Misc. methods
- (NSString*)nameForUserID:(NSString*)userID;
- (void)openURL:(NSURL*)url;

// Convenience methods for accessing preferences
- (BOOL)newPosts;
- (BOOL)allowComments;
- (BOOL)allowLikes;
- (BOOL)showNotifications;
- (BOOL)showImages;
- (int)maxPosts;
- (NSTimeInterval)refreshInterval;
- (BOOL)miniButtons;
- (BOOL)plainComments;

// Update methods
- (void)processUsers:(NSArray*)feed;
- (NSArray*)processedFeed:(NSArray*)feed;
- (id)loadFBData:(NSString*)url;
- (void)updateFeed:(BOOL)force;

- (void)updateComments:(NSDictionary*)comments forRowAtIndex:(int)index;
- (void)updateLikes:(NSDictionary*)likes forRowAtIndex:(int)index;

@end
