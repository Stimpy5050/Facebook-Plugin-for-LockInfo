#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    kOptionsViewLikeAndCommentButtons = 0,
    kOptionsViewCommentButtonOnly = 1,
    kOptionsViewLikeButtonOnly = 2,
    kOptionsViewUnlikeAndCommentButtons = 3,
    kOptionsViewUnlikeButtonOnly = 4
} FBOptionsViewButtons;

@interface FBOptionsView : UIView 
{
    id delegate;
    UIView* optionsContainer;
    UIButton* likeButton;
    UIButton* commentButton;
    CGPoint arrowPoint;
    int buttonTypes;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UIView* optionsContainer;
@property (nonatomic, retain) UIButton* likeButton;
@property (nonatomic, retain) UIButton* commentButton;
@property CGPoint arrowPoint;
@property int buttonTypes;

- (void)setButtons:(int)buttons;
- (void)likeButtonTapped:(id)sender;
- (void)commentButtonTapped:(id)sender;
- (void)setArrowPoint:(CGPoint)point;

@end
