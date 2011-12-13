#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "FBDownload.h"

static NSArray* pluginImages = [[NSArray arrayWithObjects:@"CommentButton", @"CommentButtonDown", @"CommentsIcon", @"LikeIcon", @"NotificationIcon", @"StatusIcon", nil] retain];

@interface FBSharedDataController : NSObject <FBDownloadDelegate>
{
	NSMutableDictionary* friendsImageCache;
    NSMutableDictionary* pluginImageCache;
    NSMutableArray* downloadQueue;
}

@property (nonatomic, retain) NSMutableDictionary* friendsImageCache;
@property (nonatomic, retain) NSMutableDictionary* pluginImageCache;
@property (nonatomic, retain) NSMutableDictionary* friendsNameCache;
@property (nonatomic, retain) NSMutableArray* downloadQueue;

+ (FBSharedDataController*)sharedInstance;

- (void)initCache;
- (void)loadImages; // Internal method
- (void)processDownloads;

- (void)clearFriendCache;
- (void)addUserToDownloadQueue:(NSString*)userID;
- (void)addUserToNameCache:(NSString*)name userID:(NSString*)userID;
- (UIImage*)getImage:(NSString*)name; // Internal method
- (NSString*)friendsName:(NSString*)userID;
- (UIImage*)pluginImage:(NSString*)name;
- (UIImage*)friendsImage:(NSString*)userID;

@end