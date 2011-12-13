#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FBPreview.h"

@interface FBNewPostPreview : UIViewController <FBPreviewDelegate, UITextViewDelegate>
{
	NSString* userID;
    UITextView* previewTextView;
    id delegate;
}

@property (nonatomic, retain) NSString* userID;
@property (nonatomic, retain) UITextView* previewTextView;
@property (nonatomic, assign) id delegate;

- (void)sendPost:(NSString*)post;
- (void)sendPostInBackground:(NSString*)post;

- (void)sendButtonPressed;
- (void)cancelButtonPressed;

@end