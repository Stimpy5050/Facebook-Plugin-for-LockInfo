#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SDK/Plugin.h"

typedef enum {
    kOptionsButtonTouch = 0,
    kInfoButtonTouch = 1
} FBPostTouch;

@interface FBPostView : UIView
{
	NSString* name;
	NSString* message;
	NSString* time;
	NSString* optionsButtonName;
	NSString* infoButtonName;
	UIImage* image;
	LITheme* theme;
	int noComments;
	int noLikes;
	BOOL allowLikes;
	BOOL allowComments;
    BOOL plainStyle;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* message;
@property (nonatomic, retain) NSString* time;
@property (nonatomic, retain) NSString* optionsButtonName;
@property (nonatomic, retain) NSString* infoButtonName;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, retain) LITheme* theme;
@property int noComments;
@property int noLikes;
@property BOOL allowLikes;
@property BOOL allowComments;
@property BOOL plainStyle;

@end

@interface FBPostCell : UITableViewCell
{
    FBPostView* postView;
    BOOL optionsButtonDown;
    BOOL infoButtonDown;
    int buttonTouch;
    id delegate;
    int rowIndex;
}

@property (nonatomic, retain) FBPostView* postView;
@property BOOL optionsButtonDown;
@property BOOL infoButtonDown;
@property int buttonTouch;
@property (nonatomic, assign) id delegate;
@property int rowIndex;


@end

