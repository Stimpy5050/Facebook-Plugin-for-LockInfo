#include <objc/runtime.h>
#import "FBPreview.h"

@implementation FBPreviewTheme
	
@synthesize detailCellBackgroundColour, summaryStyle, nameStyle, detailStyle, timeStyle, likeStyle, likeStyleDown;

- (id)init
{
	if (self = [super init])
	{
		// Nothing to init
	}
	
	return self;
}

- (void)dealloc
{
	if (detailCellBackgroundColour) [detailCellBackgroundColour release];
	if (summaryStyle) [summaryStyle release];
	if (nameStyle) [nameStyle release];
	if (detailStyle) [timeStyle release];
	if (likeStyle) [likeStyle release];
	if (likeStyleDown) [likeStyleDown release];
    [super dealloc];
}

- (LITheme*)LIThemeFromCurrentTheme
{
    LITheme* theme = [[[objc_getClass("LITheme") alloc] init] autorelease];
    theme.summaryStyle = [self.summaryStyle copy];
    theme.detailStyle = [self.detailStyle copy];
    
    return theme;
}

@end
