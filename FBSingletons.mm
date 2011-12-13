#import "FBSingletons.h"
#import "UIImage-FBAdditions.h"
#import "SDK/LIPlugin.h"
#import "FBCommon.h"

static FBSharedDataController* FBDataShared = nil;

@implementation FBSharedDataController

@synthesize friendsImageCache, friendsNameCache, pluginImageCache, downloadQueue;

#pragma mark -
#pragma mark Singleton Initialisation

+ (FBSharedDataController*)sharedInstance
{
	@synchronized(self) 
	{
		if (FBDataShared == nil)
			FBDataShared = [[super allocWithZone:NULL] init];
    }
   return FBDataShared;
}

+ (id)allocWithZone:(NSZone *)zone 
{
    return [self sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain 
{
    return self;
}

- (unsigned)retainCount 
{
    return UINT_MAX;  // denotes an object that cannot be released
}

- (void)release 
{
    //do nothing
}

- (id)autorelease 
{
    return self;
}

#pragma mark -
#pragma mark Image Loading

- (void)loadImages
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    int i=0;
	
	NSBundle* bundle = [NSBundle bundleWithIdentifier:@"com.burgess.lockinfo.FacebookPlugin"];
    
	for (i; i<6; i++)
	{		
		NSString* imagePath = [bundle pathForResource:[pluginImages objectAtIndex:i] ofType:@"png"];
		UIImage* image = [UIImage li_imageWithContentsOfResolutionIndependentFile:imagePath];
        
		if (image)
			[self.pluginImageCache setObject:image forKey:[pluginImages objectAtIndex:i]];
	}
    
    UIColor* topColour = [UIColor colorWithRed:226.0/255.0 green:239.0/255.0 blue:235.0/255.0 alpha:1.0];
    UIColor* bottomColour = [UIColor colorWithRed:247.0/255.0 green:249.0/255.0 blue:252.0/255.0 alpha:1.0];
    UIColor* topColourDown = [UIColor colorWithRed:206.0/255.0 green:219.0/255.0 blue:215.0/255.0 alpha:1.0];
    UIColor* bottomColourDown = [UIColor colorWithRed:227.0/255.0 green:229.0/255.0 blue:232.0/255.0 alpha:1.0];
    UIColor* postInfo = [UIColor colorWithRed:237.0/255.0 green:239.0/255.0 blue:244.0/255.0 alpha:1.0];
	UIColor* postInfoDown = [UIColor colorWithRed:217.0/255.0 green:219.0/255.0 blue:224.0/255.0 alpha:1.0];
	UIColor* likeButton = [UIColor colorWithRed:100.0/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:0.5];
    
    NSArray* colours = [NSArray arrayWithObjects:(id)[topColour CGColor], (id)[bottomColour CGColor], nil];
    NSArray* downColours = [NSArray arrayWithObjects:(id)[topColourDown CGColor], (id)[bottomColourDown CGColor], nil];
    
    UIImage* buttonBackground = [UIImage backgroundGradientImageWithColours:colours size:CGSizeMake(21, 30) roundedCorners:YES cornerRadius:7 options:kBorderAndShadow];
    UIImage* buttonBackgroundDown = [UIImage backgroundGradientImageWithColours:downColours size:CGSizeMake(21, 30) roundedCorners:YES cornerRadius:7 options:kBorderAndShadow];
    UIImage* smallButtonBackground = [UIImage backgroundGradientImageWithColours:colours size:CGSizeMake(21, 30) roundedCorners:YES cornerRadius:4 options:kBorderAndShadow];
    UIImage* smallButtonBackgroundDown = [UIImage backgroundGradientImageWithColours:downColours size:CGSizeMake(21, 30) roundedCorners:YES cornerRadius:4 options:kBorderAndShadow];
    UIImage* popoverBackground = [UIImage pointedContainerWithSize:CGSizeMake(60, 44) arrowWidth:20 cornerRadius:10 
                                                   backgroundImage:[UIImage backgroundGradientImageWithColours:colours size:CGSizeMake(22, 40)] options:kBorderOnly];
    UIImage* postInfoBackground = [UIImage backgroundSolidColourRoundedRectWithSize:CGSizeMake(11, 11) colour:postInfo.CGColor cornerRadius:5];
	UIImage* postInfoBackgroundDown = [UIImage backgroundSolidColourRoundedRectWithSize:CGSizeMake(11, 11) colour:postInfoDown.CGColor cornerRadius:5];
	UIImage* likeButtonBackground = [UIImage backgroundSolidColourRoundedRectWithSize:CGSizeMake(11, 11) colour:likeButton.CGColor cornerRadius:3];
    
    if (buttonBackground)
        [self.pluginImageCache setObject:buttonBackground forKey:@"ButtonBackground"];
    
    if (buttonBackgroundDown)
        [self.pluginImageCache setObject:buttonBackgroundDown forKey:@"ButtonBackgroundDown"];
    
    if (smallButtonBackground)
        [self.pluginImageCache setObject:smallButtonBackground forKey:@"SmallButtonBackground"];
    
    if (smallButtonBackgroundDown)
        [self.pluginImageCache setObject:smallButtonBackgroundDown forKey:@"SmallButtonBackgroundDown"];
    
    if (popoverBackground)
        [self.pluginImageCache setObject:popoverBackground forKey:@"PopoverBackground"];
    
    if (postInfoBackground)
        [self.pluginImageCache setObject:postInfoBackground forKey:@"PostInfoBackground"];

	if (postInfoBackgroundDown)
		[self.pluginImageCache setObject:postInfoBackgroundDown forKey:@"PostInfoBackgroundDown"];

	if (likeButtonBackground)
		[self.pluginImageCache setObject:likeButtonBackground forKey:@"LikeButtonBackground"];
    
    [pool drain];
}

- (void)initCache
{	
	self.pluginImageCache = [NSMutableDictionary dictionaryWithCapacity:14];
	self.friendsImageCache = [NSMutableDictionary dictionaryWithCapacity:20];
    self.friendsNameCache = [NSMutableDictionary dictionaryWithCapacity:20];
    self.downloadQueue = [NSMutableArray arrayWithCapacity:20];
    
    [self performSelectorInBackground:@selector(loadImages) withObject:nil];
}

#pragma mark -
#pragma mark FBDownload Delegate Methods

- (void)downloadDidFinishDownloading:(FBDownload*)download
{
    if (download.profilePic)
        [self.friendsImageCache setObject:download.profilePic forKey:download.userID];
    else
        DLog(@"LI: FB: No image returned from download");
    
    download.delegate = nil;
    if ([self.downloadQueue count] > 0)
        [self.downloadQueue removeObjectAtIndex:0];
    [self processDownloads];
}

- (void)download:(FBDownload*)download didFailWithError:(NSError*)error
{
    DLog(@"Error: %@", [error localizedDescription]);
    download.delegate = nil;
    if ([self.downloadQueue count] > 0)
        [self.downloadQueue removeObjectAtIndex:0];
    [self processDownloads];
}

#pragma mark -
#pragma mark Download Processing

- (void)processDownloads
{
    if ([self.downloadQueue count] > 0)
    {
        NSString* userID = [self.downloadQueue objectAtIndex:0];
        FBDownload* download = [[FBDownload alloc] init];
        download.delegate = self;
        [download startDownloadWithUserID:userID];
    }
}

#pragma mark -
#pragma mark Private Accessors

- (UIImage*)getImage:(NSString*)name
{
	NSBundle* bundle = [NSBundle bundleWithIdentifier:@"com.burgess.lockinfo.FacebookPlugin"];
	
	NSString* imagePath = [bundle pathForResource:name ofType:@"png"];
	UIImage* image = [UIImage li_imageWithContentsOfResolutionIndependentFile:imagePath];
    
	if (image)
		[self.pluginImageCache setObject:image forKey:name];
	
	return image;
}

#pragma mark -
#pragma mark Cache Accessors

- (void)clearFriendCache
{
    [self.friendsImageCache removeAllObjects];
}

- (void)addUserToDownloadQueue:(NSString*)userID
{
    if (userID && !([self.downloadQueue containsObject:userID]) && !([[self.friendsImageCache allKeys] containsObject:userID]))
        [self.downloadQueue addObject:userID];
}

- (void)addUserToNameCache:(NSString*)name userID:(NSString*)userID
{
    [self.friendsNameCache setObject:name forKey:userID];
}

- (NSString*)friendsName:(NSString*)userID
{
    return [self.friendsNameCache objectForKey:userID];
}
     
- (UIImage*)friendsImage:(NSString*)userID
{	
	return [self.friendsImageCache objectForKey:userID];
}

- (UIImage*)pluginImage:(NSString*)name;
{	
	UIImage* image = [self.pluginImageCache objectForKey:name];
	
	if (image)
		return image;
	else
		return [self getImage:name];
}

@end

