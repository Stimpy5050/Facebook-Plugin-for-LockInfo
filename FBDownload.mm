#import "FBDownload.h"

@implementation FBDownload

@synthesize delegate, receivedData, profilePic, downloading, userID;

- (void)startDownloadWithUserID:(NSString*)userid
{
    if (userid)
    {
        self.userID = userid;
        NSString* urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", userid];
        
        if (profilePic == nil && !downloading)
        {
            if (urlString != nil && [urlString length] > 0)
            {
                NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
                NSURLConnection *con = [[NSURLConnection alloc]
                                        initWithRequest:req
                                        delegate:self
                                        startImmediately:NO];
                [con scheduleInRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSRunLoopCommonModes];
                [con start];

                if (con) 
                {
                    NSMutableData *data = [[NSMutableData alloc] init];
                    self.receivedData=data;
                    [data release];
                } 
                else 
                {
                    NSError *error = [NSError errorWithDomain:FBDownloadErrorDomain 
                                                         code:FBDownloadErrorNoConnection 
                                                     userInfo:nil];
                    if ([self.delegate respondsToSelector:@selector(download:didFailWithError:)])
                        [delegate download:self didFailWithError:error];
                }   
                [req release];
                
                downloading = YES;
            }
        }
    }
}

- (void)dealloc 
{
    [profilePic release];
    delegate = nil;
    [receivedData release];
    [super dealloc];
}

#pragma mark -
#pragma mark NSURLConnection Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response 
{
    [receivedData setLength:0];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
    [receivedData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
    [connection release];
    
    if ([delegate respondsToSelector:@selector(download:didFailWithError:)])
        [delegate download:self didFailWithError:error];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    self.profilePic = [UIImage imageWithData:receivedData];
    if ([delegate respondsToSelector:@selector(downloadDidFinishDownloading:)])
        [delegate downloadDidFinishDownloading:self];
    
    [connection release];
    self.receivedData = nil;
}

@end