#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define FBDownloadErrorDomain      @"FBDownload Error Domain"
enum 
{
    FBDownloadErrorNoConnection = 1000,
};

@class FBDownload;

@protocol FBDownloadDelegate
@optional
- (void)downloadDidFinishDownloading:(FBDownload *)download;
- (void)download:(FBDownload *)download didFailWithError:(NSError *)error;
@end


@interface FBDownload : NSObject
{
    id <NSObject, FBDownloadDelegate> delegate;
    NSMutableData* receivedData;
    NSString* userID;
    UIImage* profilePic;
    BOOL downloading;
}

@property (nonatomic, retain) NSMutableData* receivedData;
@property (nonatomic, retain) UIImage* profilePic;
@property (nonatomic, retain) NSString* userID;
@property BOOL downloading;
@property (nonatomic, assign) id <NSObject, FBDownloadDelegate> delegate;

- (void)startDownloadWithUserID:(NSString*)userid;

@end