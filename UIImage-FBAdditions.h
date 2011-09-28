#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    kNone = 0,
    kBorderOnly = 1,
    kShadowOnly = 2,
    kBorderAndShadow = 3
} FBImageOptions;

CGMutablePathRef createRectPath(CGRect rect);
CGMutablePathRef createRoundedRectPath(CGRect rect, CGFloat cornerRadius);
CGMutablePathRef createPointedContainerPath(CGRect rect, CGFloat arrowWidth, CGFloat cornerRadius);

@interface UIImage (FBPluginAdditions)

+ (UIImage*)backgroundGradientImageWithColours:(NSArray*)colours size:(CGSize)size;
+ (UIImage*)backgroundGradientImageWithColours:(NSArray*)colours size:(CGSize)size roundedCorners:(BOOL)rounded cornerRadius:(CGFloat)cornerRadius options:(int)options;
+ (UIImage*)pointedContainerWithSize:(CGSize)size arrowWidth:(CGFloat)arrowWidth cornerRadius:(CGFloat)cornerRadius backgroundImage:(UIImage*)background options:(int)options;
+ (UIImage*)backgroundSolidColourRoundedRectWithSize:(CGSize)size colour:(CGColorRef)colour cornerRadius:(CGFloat)cornerRadius;

- (UIImage*)backgroundGradientImageWithColours:(NSArray*)colours size:(CGSize)size roundedCorners:(BOOL)rounded cornerRadius:(CGFloat)cornerRadius options:(int)options;
- (UIImage*)pointedContainerWithSize:(CGSize)size arrowWidth:(CGFloat)arrowWidth cornerRadius:(CGFloat)cornerRadius backgroundImage:(UIImage*)background options:(int)options;
- (UIImage*)backgroundSolidColourRoundedRectWithSize:(CGSize)size colour:(CGColorRef)colour cornerRadius:(CGFloat)cornerRadius;

@end

