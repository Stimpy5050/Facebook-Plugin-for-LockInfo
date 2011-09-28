#import <Foundation/Foundation.h>
#import "SDK/Plugin.h"

typedef enum {
    kCommentsPreview = 0,
    kNotificationsPreview = 1,
    kNewPostPreview = 2
} FBPreviews;

@protocol FBPreviewDelegate <NSObject>
- (void)clearData;
@optional
- (void)previewWillShow;
- (void)previewDidShow;
- (void)previewWillDismiss;
- (void)previewDidDismiss;
@end

@interface FBPreviewTheme : NSObject
{
	UIColor* detailCellBackgroundColour;
	LIStyle* summaryStyle;
	LIStyle* nameStyle;
	LIStyle* detailStyle;
	LIStyle* timeStyle;
	LIStyle* likeStyle;
	LIStyle* likeStyleDown;
}

@property (nonatomic, retain) UIColor* detailCellBackgroundColour;
@property (nonatomic, retain) LIStyle* summaryStyle;
@property (nonatomic, retain) LIStyle* nameStyle;
@property (nonatomic, retain) LIStyle* detailStyle;
@property (nonatomic, retain) LIStyle* timeStyle;
@property (nonatomic, retain) LIStyle* likeStyle;
@property (nonatomic, retain) LIStyle* likeStyleDown;

- (LITheme*)LIThemeFromCurrentTheme;

@end