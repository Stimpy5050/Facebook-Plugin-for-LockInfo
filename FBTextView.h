#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FBTextView : UITextView 
{
    NSString *placeholder;
    UIColor *placeholderColour;
}

@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColour;

-(void)textChanged:(NSNotification*)notification;

@end
