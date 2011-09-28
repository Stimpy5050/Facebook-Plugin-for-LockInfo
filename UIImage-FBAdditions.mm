#import "UIImage-FBAdditions.h"
#import "FBCommon.h"
#include <math.h>

CGMutablePathRef createRectPath(CGRect rect)
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    
    return path;
}

CGMutablePathRef createRoundedRectPath(CGRect rect, CGFloat cornerRadius)
{
    CGFloat startX = rect.origin.x;
    CGFloat startY = rect.origin.y;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, startX, startY + cornerRadius);
    CGPathAddLineToPoint(path, NULL, startX, startY + height - cornerRadius);
    CGPathAddArc(path, NULL, startX + cornerRadius, startY + height - cornerRadius, cornerRadius, M_PI, M_PI / 2, 1);
    CGPathAddLineToPoint(path, NULL, startX + width - cornerRadius, startY + height);
    CGPathAddArc(path, NULL, startX + width - cornerRadius, startY + height - cornerRadius, cornerRadius, M_PI / 2, 0, 1);
    CGPathAddLineToPoint(path, NULL, startX + width, startY + cornerRadius);
    CGPathAddArc(path, NULL, startX + width - cornerRadius, startY + cornerRadius, cornerRadius, 0, -(M_PI / 2), 1);
    CGPathAddLineToPoint(path, NULL, startX + cornerRadius, startY);
    CGPathAddArc(path, NULL, startX + cornerRadius, startY + cornerRadius, cornerRadius, -(M_PI / 2), -M_PI, 1);
    CGPathCloseSubpath(path);
    
    return path;
}

CGMutablePathRef createPointedContainerPath(CGRect rect, CGFloat arrowWidth, CGFloat cornerRadius)
{
    CGFloat startX = rect.origin.x;
    CGFloat startY = rect.origin.y;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    CGFloat arrowAngle = atan(height / (2 * arrowWidth));
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, startX, startY + cornerRadius);
    CGPathAddLineToPoint(path, NULL, startX, startY + height - cornerRadius);
    CGPathAddArc(path, NULL, startX + cornerRadius, startY + height - cornerRadius, cornerRadius, M_PI, M_PI / 2, 1);
    CGPathAddLineToPoint(path, NULL, startX + width - arrowWidth, startY + height);
    CGPathAddArc(path, NULL, startX + width - arrowWidth, startY + height - cornerRadius, cornerRadius, M_PI / 2, ((M_PI / 2) - arrowAngle), 1);
    CGPathAddLineToPoint(path, NULL, startX + width + (cornerRadius * (sin(arrowAngle) - 1)), startY + (height / 2) + (cornerRadius * cos(arrowAngle)));
    CGPathAddArc(path, NULL, startX + width - cornerRadius, startY + (height / 2), cornerRadius, ((M_PI / 2) - arrowAngle), -((M_PI / 2) - arrowAngle), 1);
    CGPathAddLineToPoint(path, NULL, startX + width - arrowWidth + (cornerRadius * sin(arrowAngle)), startY + (cornerRadius * (1 - sin(arrowAngle))));
    CGPathAddArc(path, NULL, startX + width - arrowWidth, startY + cornerRadius, cornerRadius, -((M_PI / 2) - arrowAngle), -(M_PI / 2), 1);
    CGPathAddLineToPoint(path, NULL, startX + cornerRadius, startY);
    CGPathAddArc(path, NULL, startX + cornerRadius, startY + cornerRadius, cornerRadius, -(M_PI / 2), -M_PI, 1);
    CGPathCloseSubpath(path);
    
    return path;
}

@implementation UIImage (FBPluginAdditions)

+ (UIImage*)backgroundGradientImageWithColours:(NSArray*)colours size:(CGSize)size
{
    return [[[UIImage alloc] backgroundGradientImageWithColours:colours size:size roundedCorners:NO cornerRadius:0 options:kNone] autorelease];
}

+ (UIImage*)backgroundGradientImageWithColours:(NSArray*)colours size:(CGSize)size roundedCorners:(BOOL)rounded cornerRadius:(CGFloat)cornerRadius options:(int)options 
{
    return [[[UIImage alloc] backgroundGradientImageWithColours:colours size:size roundedCorners:rounded cornerRadius:cornerRadius options:options] autorelease];
}

+ (UIImage*)pointedContainerWithSize:(CGSize)size arrowWidth:(CGFloat)arrowWidth cornerRadius:(CGFloat)cornerRadius backgroundImage:(UIImage*)background options:(int)options 
{
    return [[[UIImage alloc] pointedContainerWithSize:size arrowWidth:arrowWidth cornerRadius:cornerRadius  backgroundImage:background options:options] autorelease];
}

+ (UIImage*)backgroundSolidColourRoundedRectWithSize:(CGSize)size colour:(CGColorRef)colour cornerRadius:(CGFloat)cornerRadius
{
    return [[[UIImage alloc] backgroundSolidColourRoundedRectWithSize:size colour:colour cornerRadius:cornerRadius] autorelease];
}

- (UIImage*)backgroundGradientImageWithColours:(NSArray*)colours size:(CGSize)size roundedCorners:(BOOL)rounded cornerRadius:(CGFloat)cornerRadius options:(int)options 
{
    // Set up Graphics Context
	
	float scale = 1.0;
    
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
		scale = [[UIScreen mainScreen] scale];
    
	CGFloat width = size.width * scale;
    CGFloat height = size.height * scale;
    CGFloat radius = cornerRadius * scale;
    
	CGContextRef bitmapContext = NULL;
	CGColorSpaceRef colourSpace;
	int bitmapByteCount;
	int bitmapBytesPerRow;
	
	bitmapBytesPerRow = (width * 4);
	bitmapByteCount = (bitmapBytesPerRow * height);
	
	colourSpace = CGColorSpaceCreateDeviceRGB();
	bitmapContext = CGBitmapContextCreate (NULL, width, height, 8, bitmapBytesPerRow,
										   colourSpace, kCGImageAlphaPremultipliedLast);
	
	if (bitmapContext == NULL)
	{
		DLog(@"FB UIImage: No Bitmap Context!!");
		return nil;
	}
    
    CGPathRef outline;
    
    if (rounded)
    {   
        CGPathRef roundedPath = createRoundedRectPath(CGRectMake(0, 0, width, height), radius);
        outline = createRoundedRectPath(CGRectMake(1, 1, width - 2, height - 2), radius - 1);
        CGContextAddPath(bitmapContext, roundedPath);
        CGPathRelease(roundedPath);
    } else {
        CGContextAddRect(bitmapContext, CGRectMake(0, 0, width, height));
        outline = createRectPath(CGRectMake(1, 1, width - 2, height - 2));
    }
    
    // Clip context to shape
    
    CGContextClip(bitmapContext);
    
    // Draw gradient
    CGFloat locations[2] = {0.0, 1.0};
    CGGradientRef gradient = CGGradientCreateWithColors(colourSpace, (CFArrayRef)colours, locations);
	CGContextDrawLinearGradient(bitmapContext, gradient, CGPointMake((int)(width / 2), 0), CGPointMake((int)(width / 2), height), 0);
    
    // Add options
    
    if (options > 0)
    {
        CGContextSaveGState(bitmapContext);
        CGContextAddPath(bitmapContext, outline);
        
        if (options > 1)
        {
            CGColorRef shadowColour = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8].CGColor;
            CGContextSetShadowWithColor(bitmapContext, CGSizeMake(0, 2), 3.0, shadowColour);
        }
        
        if (options == 1 || options == 3)
        {
            CGColorRef lineColour = [UIColor colorWithRed:147.0/255.0 green:152.0/255.0 blue:160.0/255.0 alpha:1.0].CGColor;
            CGContextSetLineWidth(bitmapContext, 2.0);
            CGContextSetStrokeColorWithColor(bitmapContext, lineColour);
        }
        CGContextStrokePath(bitmapContext);
        CGContextRestoreGState(bitmapContext);
    }
    
    // Tidy Up and get image
    
    UIImage* returnImage;
	CGImageRef img = CGBitmapContextCreateImage(bitmapContext);
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        returnImage = [[UIImage imageWithCGImage:img scale:scale orientation:UIImageOrientationUp] retain];
    } else {
        returnImage = [[UIImage imageWithCGImage:img] retain];
    }
    
	CGImageRelease(img);
    
    CGPathRelease(outline);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colourSpace);
	CGContextRelease(bitmapContext);
    
	return returnImage;
}

- (UIImage*)pointedContainerWithSize:(CGSize)size arrowWidth:(CGFloat)arrowWidth cornerRadius:(CGFloat)cornerRadius backgroundImage:(UIImage*)background options:(int)options
{
    // Set up Graphics Context
    
    float scale = 1.0;
    
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
		scale = [[UIScreen mainScreen] scale];
    
	CGFloat width = size.width * scale;
    CGFloat height = size.height * scale;
    CGFloat radius = cornerRadius * scale;
    CGFloat arrowWidthScaled = arrowWidth * scale;
    
	CGContextRef bitmapContext = NULL;
	CGColorSpaceRef colourSpace;
	int bitmapByteCount;
	int bitmapBytesPerRow;
	
	bitmapBytesPerRow = (width * 4);
	bitmapByteCount = (bitmapBytesPerRow * height);
	
	colourSpace = CGColorSpaceCreateDeviceRGB();
	bitmapContext = CGBitmapContextCreate (NULL, width, height, 8, bitmapBytesPerRow,
										   colourSpace, kCGImageAlphaPremultipliedLast);
	
	if (bitmapContext == NULL)
	{
		DLog(@"FB UIImage: No Bitmap Context!!");
		return nil;
	}
	
	// Drawing Code
    
    CGPathRef shape = createPointedContainerPath(CGRectMake(0, 0, width, height), arrowWidthScaled, radius);
    CGPathRef outline = createPointedContainerPath(CGRectMake(1, 1, width - 2, height - 2), arrowWidthScaled - 1, radius - 1);
    CGContextAddPath(bitmapContext, shape);
    
    CGContextClip(bitmapContext);
    
    CGContextDrawImage (bitmapContext, CGRectMake(0, 0, width, height), [background CGImage]);
    
    // Add options
    
    if (options > 0)
    {
        CGContextSaveGState(bitmapContext);
        CGContextAddPath(bitmapContext, outline);
    
        if (options > 1)
        {
            CGColorRef shadowColour = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.8].CGColor;
            CGContextSetShadowWithColor(bitmapContext, CGSizeMake(0, 2), 3.0, shadowColour);
        }
        
        if (options == 1 || options == 3)
        {
            CGColorRef lineColour = [UIColor colorWithRed:109.0/255.0 green:124.0/255.0 blue:147.0/255.0 alpha:1.0].CGColor;
            CGContextSetStrokeColorWithColor(bitmapContext, lineColour);
            CGContextSetLineWidth(bitmapContext, 2.0);
        }
        CGContextStrokePath(bitmapContext);
        CGContextRestoreGState(bitmapContext);
    }
    
	// Tidy up and return Image
	
	UIImage* returnImage;
	CGImageRef img = CGBitmapContextCreateImage(bitmapContext);
    
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
	{
		returnImage = [[UIImage imageWithCGImage:img scale:scale orientation:UIImageOrientationUp] retain];
	} else {
		returnImage = [[UIImage imageWithCGImage:img] retain];
	}
	
	CGImageRelease(img);
    
    CGPathRelease(outline);
    CGPathRelease(shape);
    CGColorSpaceRelease(colourSpace);
    CGContextRelease(bitmapContext);
    
	return returnImage;
}

- (UIImage*)backgroundSolidColourRoundedRectWithSize:(CGSize)size colour:(CGColorRef)colour cornerRadius:(CGFloat)cornerRadius
{
    // Set up Graphics Context
	
	float scale = 1.0;
    
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
		scale = [[UIScreen mainScreen] scale];
    
	CGFloat width = size.width * scale;
    CGFloat height = size.height * scale;
    CGFloat radius = cornerRadius * scale;
    
	CGContextRef bitmapContext = NULL;
	CGColorSpaceRef colourSpace;
	int bitmapByteCount;
	int bitmapBytesPerRow;
	
	bitmapBytesPerRow = (width * 4);
	bitmapByteCount = (bitmapBytesPerRow * height);
	
	colourSpace = CGColorSpaceCreateDeviceRGB();
	bitmapContext = CGBitmapContextCreate (NULL, width, height, 8, bitmapBytesPerRow,
										   colourSpace, kCGImageAlphaPremultipliedLast);
	
	if (bitmapContext == NULL)
	{
		DLog(@"FB UIImage: No Bitmap Context!!");
		return nil;
	}
        
    CGPathRef roundedPath = createRoundedRectPath(CGRectMake(0, 0, width, height), radius);
    CGContextAddPath(bitmapContext, roundedPath);
    CGPathRelease(roundedPath);

    // Fill shape
    CGContextSetFillColorWithColor(bitmapContext, colour);
    CGContextFillPath(bitmapContext);
    
    // Tidy Up and get image
    
    UIImage* returnImage;
	CGImageRef img = CGBitmapContextCreateImage(bitmapContext);
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        returnImage = [[UIImage imageWithCGImage:img scale:scale orientation:UIImageOrientationUp] retain];
    } else {
        returnImage = [[UIImage imageWithCGImage:img] retain];
    }
    
	CGImageRelease(img);
    
    CGColorSpaceRelease(colourSpace);
	CGContextRelease(bitmapContext);
    
	return returnImage;
}

@end
