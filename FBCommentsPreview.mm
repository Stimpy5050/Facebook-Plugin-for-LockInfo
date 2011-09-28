#include <objc/runtime.h>
#import <SpringBoard/SBTelephonyManager.h>
#import "FBCommentsPreview.h"
#import "FBCommon.h"
#import "FBCommentCell.h"
#import "FBPostCell.h"
#import "FBLoadingCell.h"
#import "FBLikesCell.h"
#import "FBSingletons.h"
#import "FacebookAuth.h"

@implementation FBCommentsPreview

@synthesize theme, comments, postID, name, time, image, post, delegate, loadingDelegate, noComments, noLikes, userLikes, streamRowIndex, allowLikes, allowComments, showingKeyboard, postingComment, lastUpdate, keyboardHeight, shouldLoadWithKeyboard;
@synthesize tableView = _tableView;
@synthesize textView = _textView;

#pragma mark -
#pragma mark Initialisation methods

- (id)init
{
    if (self = [super init])
    {      
        self.navigationItem.title = localize(@"Comments");
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self.delegate action:@selector(clearPreview)] autorelease];
		self.comments = [NSMutableArray arrayWithCapacity:1];
		self.showingKeyboard = NO;
        self.keyboardHeight = 0.0;
        self.shouldLoadWithKeyboard = NO;
    }
    
    return self;
}

- (void)dealloc
{
    delegate = nil;
    loadingDelegate = nil;
    [_textView release];
    [_tableView release];
    [theme release];
    [postID release];
    [comments release];
    [name release];
    [time release];
    [image release];
    [post release];
    [super dealloc];
}

- (void)loadView
{
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect frame = CGRectMake(applicationFrame.origin.x, applicationFrame.origin.y, applicationFrame.size.width, applicationFrame.size.height - self.navigationController.navigationBar.frame.size.height);
	CGRect tableFrame = CGRectMake(0, 0, frame.size.width, frame.size.height - 48);
	CGRect textViewFrame = CGRectMake(5, frame.size.height - 43, frame.size.width - 10, 38);
	UITableView* tv = [[[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain] autorelease];
	tv.backgroundColor = [UIColor whiteColor];
	tv.delegate = self;
    tv.dataSource = self;
    
    pull = [[PullToRefreshView alloc] initWithScrollView:tv];
    [pull setDelegate:self];
    [tv addSubview:pull];
    
    FBTextView* txt = [[[FBTextView alloc] initWithFrame:textViewFrame] autorelease];
	txt.placeholder = @"Write a Comment...";
    txt.placeholderColour = [UIColor lightGrayColor];
	txt.layer.cornerRadius = 5;
    txt.clipsToBounds = YES;
	txt.delegate = self;
	txt.font = [UIFont systemFontOfSize:18];
	txt.textColor = [UIColor darkGrayColor];

	UIView* v = [[[UIView alloc] initWithFrame:frame] autorelease];
    v.backgroundColor = [UIColor lightGrayColor];
	[v addSubview:txt];
	[v addSubview:tv];
	
	self.textView = txt;
    self.tableView = tv;
    self.view = v;
    
    // Not sure why this is required for some people but adding it anyway.
    self.navigationItem.title = localize(@"Comments");
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self.delegate action:@selector(clearPreview)] autorelease];
}

- (void)previewDidShow
{
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:self selector:@selector(keyboardWillShow:) 
		name:UIKeyboardWillShowNotification object:nil];
	[center addObserver:self selector:@selector(keyboardWillHide:)
        name:UIKeyboardWillHideNotification object:nil];
    
    if (self.shouldLoadWithKeyboard)
        [self.textView becomeFirstResponder];
    
    [self.tableView reloadData];
    [self resizeViews];
}

- (void)previewWillDismiss
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    [center removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[center removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark -
#pragma mark TextView & Keyboard Handling

- (void)sendComment:(NSString*)comment
{
	self.postingComment = YES;
	[self insertLoadingCellAtLastIndex];
	[self performSelectorInBackground:@selector(sendCommentInBackground:) withObject:comment];
}

- (void)sendCommentInBackground:(NSString*)comment
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
     
    FacebookAuth* auth = [[[FacebookAuth alloc] init] autorelease];
     
    if ([auth authorized])
    {
        NSString* objectID = [[self.postID componentsSeparatedByString:@"_"] lastObject];
    	NSString* url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/comments?message=%@", objectID, comment];
    	NSString* fullURL = [[NSString stringWithFormat:@"%@&access_token=%@", url, auth.access_token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullURL]];
    	[request setHTTPMethod:@"POST"];
          
    	NSError* error = nil;
    	NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
		
		if (error)
			DLog(@"LI: FB: Error commenting on status");
		else
			[self performSelectorInBackground:@selector(reloadComments) withObject:nil];
    }
    else
    	DLog(@"LI: FB: Auth not authorised to comment on status");

	if ([self.loadingDelegate respondsToSelector:@selector(finishedLoading)])
    	[self.loadingDelegate performSelectorOnMainThread:@selector(finishedLoading) withObject:nil waitUntilDone:NO];
    
	self.postingComment = NO;
	[self.tableView reloadData];
	
	[pool drain];
}

- (void)sendButtonPressed
{
    if ([self.textView.text length] == 0)
        return;
    
	[self sendComment:self.textView.text];
    self.textView.text = @"";
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self.delegate action:@selector(clearPreview)] autorelease];
    if ([[[self delegate] delegate] respondsToSelector:@selector(resignKeyboard)])
        [[[self delegate] delegate] resignKeyboard];
}

- (void)cancelButtonPressed
{
    self.textView.text = @"";
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self.delegate action:@selector(clearPreview)] autorelease];
	if ([[[self delegate] delegate] respondsToSelector:@selector(resignKeyboard)])
        [[[self delegate] delegate] resignKeyboard];
}

- (void)scrollToLastRow
{
  [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([self.comments count] + 1 + (([self.comments count] == self.noComments) ? 0 : 1) + ((self.postingComment) ? 1 : 0)) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)resizeViews
{
	CGRect frame = self.view.frame;
	CGSize textViewSize = self.textView.contentSize;
    
    if ([self.textView.text length] == 0)
        textViewSize.height = 38;
    
    if ((textViewSize.height) > (frame.size.height - (self.keyboardHeight + 20)))
        textViewSize.height = frame.size.height - (self.keyboardHeight + 20);
    
	CGRect tableFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - (self.keyboardHeight + textViewSize.height + 10));
	CGRect textViewFrame = CGRectMake(frame.origin.x + 5, frame.origin.y + frame.size.height - (self.keyboardHeight + textViewSize.height + 5), frame.size.width - 10, textViewSize.height);

	self.tableView.frame = tableFrame;
	self.textView.frame = textViewFrame;
    
    [self scrollToLastRow];
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self resizeViews];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    int newLength = (textView.text.length - range.length) + text.length;
    if(newLength <= 420)
        return YES;
    
    int emptySpace = 420 - (textView.text.length - range.length);
    textView.text = [[[textView.text substringToIndex:range.location] 
                      stringByAppendingString:[text substringToIndex:emptySpace]]
                     stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
    return NO;
}
        
- (void)textViewDidBeginEditing:(UITextView *)textView
{
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleBordered target:self action:@selector(sendButtonPressed)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed)] autorelease];
    if ([[[self delegate] delegate] respondsToSelector:@selector(displayKeyboard:)])
        [[[self delegate] delegate] displayKeyboard:self.textView];
    [self.textView setNeedsDisplay];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.navigationItem.leftBarButtonItem = nil;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self.delegate action:@selector(clearPreview)] autorelease];
    if ([[[self delegate] delegate] respondsToSelector:@selector(resignKeyboard)])
        [[[self delegate] delegate] resignKeyboard];
    [self.textView setNeedsDisplay];
}

- (void)keyboardWillShow:(NSNotification*)notification
{
	if (!self.showingKeyboard)
	{
		self.showingKeyboard = YES;
		self.postingComment = NO;
		
		NSDictionary* userInfo = [notification userInfo];

		// we don't use SDK constants here to be universally compatible with all SDKs ≥ 3.0
		NSValue* keyboardFrameValue = [userInfo objectForKey:@"UIKeyboardBoundsUserInfoKey"];
		if (!keyboardFrameValue)
			keyboardFrameValue = [userInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"];

		// Reduce the tableView height by the part of the keyboard that actually covers the tableView
		CGFloat kbHeight = [keyboardFrameValue CGRectValue].size.height;
        self.keyboardHeight = kbHeight;
        
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
		[UIView setAnimationCurve:(UIViewAnimationCurve)[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
		[self resizeViews];
    	[UIView commitAnimations];

		[self scrollToLastRow];
	}
}

- (void)keyboardWillHide:(NSNotification*)notification
{
	if (self.showingKeyboard)
	{
		self.showingKeyboard = NO;
		
		NSDictionary* userInfo = [notification userInfo];
        self.keyboardHeight = 0.0;
        
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
		[UIView setAnimationCurve:(UIViewAnimationCurve)[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
		[self resizeViews];
		[UIView commitAnimations];

		[self performSelector:@selector(scrollToLastRow) withObject:nil afterDelay:0.1];
	}
}   

#pragma mark -
#pragma mark Update methods

- (void)reloadComments
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    if (SBTelephonyManager* mgr = [objc_getClass("SBTelephonyManager") sharedTelephonyManager])
	{
		if (mgr.inCall || mgr.incomingCallExists)
		{
			DLog(@"LI:Facebook: No data connection available.");
			return;
		}
	}
    
	DLog(@"LI:Facebook: Reloading comments...");
    
    NSString* objectID = [[self.postID componentsSeparatedByString:@"_"] lastObject];
    NSString* query = [NSString stringWithFormat:@"SELECT id, time, text, fromid, likes, user_likes FROM comment WHERE object_id=%@ AND is_private = 0", objectID];
    
	NSArray* newComments = (NSArray*)[[[self delegate] delegate] loadFBData:[NSString stringWithFormat:@"https://api.facebook.com/method/fql.query?query=%@&format=JSON", [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    DLog(@"LI: FB: Comments: %@", newComments);
    
    for (NSDictionary* comment in newComments)
    {
        [[FBSharedDataController sharedInstance] addUserToDownloadQueue:[comment objectForKey:@"fromid"]];
    }
    
    [[FBSharedDataController sharedInstance] performSelectorOnMainThread:@selector(processDownloads) withObject:nil waitUntilDone:NO];
    
    if ([newComments count] != 0 && ![newComments isEqualToArray:self.comments])
    {
        [self.comments setArray:newComments];
        self.noComments = [self.comments count];
        
        [self performSelectorOnMainThread:@selector(updateStreamComments) withObject:nil waitUntilDone:NO];
    }
    
    NSString* likesQuery = [NSString stringWithFormat:@"SELECT user_id FROM like WHERE object_id=%@", objectID];
    NSArray* newLikes = (NSArray*)[[[self delegate] delegate] loadFBData:[NSString stringWithFormat:@"https://api.facebook.com/method/fql.query?query=%@&format=JSON", [likesQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    DLog(@"LI: FB: Likes: %@", newLikes);

    BOOL newUserLikes = NO;
    
    for (NSDictionary* user in newLikes)
    {
        if ([[[user objectForKey:@"user_id"] stringValue] isEqualToString:[[[self delegate] delegate] currentUserID]])
        {
            newUserLikes = YES;
            break;
        }
    }
    
    self.noLikes = [newLikes count];
    self.userLikes = newUserLikes;
    
    [self performSelectorOnMainThread:@selector(updateStreamLikes) withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(finishedLoadingComments) withObject:nil waitUntilDone:NO];
    
    [pool drain];
}

- (void)finishedLoadingComments
{
    if ([self.loadingDelegate respondsToSelector:@selector(finishedLoading)])
    	[self.loadingDelegate finishedLoading];
    
    self.lastUpdate = [NSDate date];      
    [pull finishedLoading];
    [self.tableView reloadData];
}

- (void)setUserLikes:(BOOL)likes forRowAtIndex:(int)index
{
	[[self.comments objectAtIndex:index] setObject:[NSNumber numberWithBool:likes] forKey:@"user_likes"];
	
	int numberLikes = [[[self.comments objectAtIndex:index] objectForKey:@"likes"] intValue];
	if (likes)
		numberLikes++;
	else
		numberLikes--;
		
	[[self.comments objectAtIndex:index] setObject:[NSNumber numberWithInt:numberLikes] forKey:@"likes"];
	
	[self updateStreamComments];
}

- (void)setUserLikesPost:(BOOL)likes
{
	self.userLikes = likes;
	
	if (likes)
		self.noLikes++;
	else
		self.noLikes--;
		
	[self updateStreamLikes];
}

- (void)updateStreamComments
{
	NSMutableDictionary* commentData = [NSMutableDictionary dictionaryWithCapacity:4];
	[commentData setObject:[NSNumber numberWithBool:NO] forKey:@"can_remove"];
	[commentData setObject:[NSNumber numberWithBool:self.allowComments] forKey:@"can_post"];
	[commentData setObject:[NSNumber numberWithInt:[self.comments count]] forKey:@"count"];
	[commentData setObject:[self.comments mutableCopy] forKey:@"comment_list"];
	
	if ([[[self delegate] delegate] respondsToSelector:@selector(updateComments:forRowAtIndex:)])
		[[[self delegate] delegate] updateComments:commentData forRowAtIndex:self.streamRowIndex];
}

- (void)updateStreamLikes
{
	NSMutableDictionary* likeData = [NSMutableDictionary dictionaryWithCapacity:3];
	[likeData setObject:[NSNumber numberWithBool:self.userLikes] forKey:@"user_likes"];
	[likeData setObject:[NSNumber numberWithBool:self.allowLikes] forKey:@"can_like"];
	[likeData setObject:[NSNumber numberWithInt:self.noLikes] forKey:@"count"];
	
	if ([[[self delegate] delegate] respondsToSelector:@selector(updateLikes:forRowAtIndex:)])
		[[[self delegate] delegate] updateLikes:likeData forRowAtIndex:self.streamRowIndex];
}

#pragma mark -
#pragma mark TableView methods

- (void)insertLoadingCellAtLastIndex
{
    NSIndexPath* newRow = [NSIndexPath indexPathForRow:([self.comments count] + 1 + (([self.comments count] == self.noComments) ? 0 : 1) + 1) inSection:0];
    
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newRow] withRowAnimation:UITableViewRowAnimationBottom];
    
    [self scrollToLastRow];
}

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ((self.noComments != [self.comments count]) && (indexPath.row == 2))
    	return indexPath;
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self performSelectorInBackground:@selector(reloadComments) withObject:nil];
	if ([self.loadingDelegate respondsToSelector:@selector(startLoading)])
    	[self.loadingDelegate startLoading];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    int row = indexPath.row;
    int width = tableView.frame.size.width;
    
    int summary = self.theme.summaryStyle.font.pointSize;
    int offset = (([[[self delegate] delegate] showImages]) ? 25 : 0);
    
    if (row == 0)
	{
		CGSize s = [self.post sizeWithFont:self.theme.detailStyle.font constrainedToSize:CGSizeMake(width - (15 + offset), 4000) lineBreakMode:UILineBreakModeWordWrap];
		return (s.height + (2 * summary) + 8);
    }
    
    row--;
    
    if ((self.allowLikes) || (self.noLikes > 0))
    {
    	if (row == 0)
			return 30;
    
    	row--;
    }
    
    if (self.noComments != [self.comments count])
    {
    	if (row == 0)
    		return 30;
    	
    	row--;
    }
    
    if (self.postingComment)
    {
    	if (row == self.comments.count + 1)
    		return 30;
    	
    	row--;
    }
    
	if (row >= self.comments.count)
		return 0;
    
    NSDictionary* elem = [self.comments objectAtIndex:row];
    
    NSString* comment = [elem objectForKey:@"text"];
	CGSize s = [comment sizeWithFont:self.theme.detailStyle.font constrainedToSize:CGSizeMake(width - (15 + offset), 4000) lineBreakMode:UILineBreakModeWordWrap];
    
	return (s.height + (2 * summary) + 8);
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int row = indexPath.row;
	
	if (row == 0)
	{
		FBPostCell* cell = (FBPostCell*)[tableView dequeueReusableCellWithIdentifier:@"PostCell"];
	
		if (cell == nil) 
			cell = [[[FBPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PostCell"] autorelease];
    
    	cell.delegate = nil;
    	cell.rowIndex = row;
    
		FBPostView* v = cell.postView;
		v.theme = [self.theme LIThemeFromCurrentTheme];
    	v.name = nil;
		v.message = nil;
		v.time = nil;
		v.image = (id)[NSNull null];

		v.message = self.post;
        v.name = self.name;
        v.image = self.image;
		v.time = self.time;
		
        v.allowComments = NO;
        v.noComments = 0;
        v.allowLikes = NO; 
        v.noLikes = 0;
	
		[v setNeedsDisplay];
		return cell;
    }
	
	row--;
	
	if ((self.allowLikes) || (self.noLikes > 0))
	{
		if (row == 0)
		{
    		FBLikesCell* cell = (FBLikesCell*)[tableView dequeueReusableCellWithIdentifier:@"LikesCell"];
	
			if (cell == nil) 
				cell = [[[FBLikesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LikesCell"] autorelease];

			cell.delegate = self;
			cell.postID = self.postID;

			FBLikesView* v = cell.likesView;
            
            v.allowLikes = nil;
            v.likes = nil;
            v.userLikes = nil;
            
			v.theme = self.theme;
            v.opaque = YES;
            v.backgroundColor = self.theme.detailCellBackgroundColour;
			v.allowLikes = self.allowLikes;
			v.likes = self.noLikes;
			v.userLikes = self.userLikes;
            v.showImages = [[[self delegate] delegate] showImages];
            
			[v setNeedsDisplay];
			return cell;
		}
	
		row--;
	}
	
	if (self.noComments != [self.comments count])
    {
    	if (row == 0)
    	{
    		FBLoadingCell* cell = (FBLoadingCell*)[tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
	
			if (cell == nil) 
				cell = [[[FBLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadingCell"] autorelease];
		
			self.loadingDelegate = cell;
		
			FBLoadingView* v = cell.loadingView;
            
            v.theme = self.theme;
            v.opaque = YES;
            v.backgroundColor = self.theme.detailCellBackgroundColour;
			v.noComments = self.noComments;
			v.loading = NO;
		
			[v setNeedsDisplay];
			return cell;
    	}
    	
    	row--;
    }
    
    if (self.postingComment)
    {
    	if (row == self.comments.count + 1)
    	{
    		FBLoadingCell* cell = (FBLoadingCell*)[tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
	
			if (cell == nil) 
				cell = [[[FBLoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadingCell"] autorelease];
		
			self.loadingDelegate = cell;
		
			FBLoadingView* v = cell.loadingView;
            
            v.theme = self.theme;
			v.noComments = 0;
			v.loading = NO;
            v.opaque = YES;
            v.backgroundColor = self.theme.detailCellBackgroundColour;
            
			[cell startLoading];
			
			[v setNeedsDisplay];
			return cell;
    	}
    	
    	row--;
    }
	
    FBCommentCell* cell = (FBCommentCell*)[tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
	
	if (cell == nil) 
		cell = [[[FBCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CommentCell"] autorelease];
    
    cell.rowIndex = row;
    cell.delegate = self;
    
	FBCommentView* v = cell.commentView;
	v.theme = self.theme;
	v.allowLikes = nil;
    v.likes = nil;
	v.name = nil;
	v.comment = nil;
	v.time = nil;
	v.image = (id)[NSNull null];
    v.opaque = YES;
    v.backgroundColor = self.theme.detailCellBackgroundColour;

	if (row < self.comments.count)
	{	
		NSDictionary* elem = [self.comments objectAtIndex:row];
		cell.commentID = [elem objectForKey:@"id"];
		v.comment = [elem objectForKey:@"text"];
		v.allowLikes = [[[self delegate] delegate] allowLikes];
		v.likes = [[elem objectForKey:@"likes"] intValue];
        v.userLikes = [[elem objectForKey:@"user_likes"] boolValue];
		NSString* userID = [elem objectForKey:@"fromid"];
		
		if ([[[self delegate] delegate] showImages])
			v.image = [[FBSharedDataController sharedInstance] friendsImage:userID];
		else
			v.image = (id)[NSNull null];
			
		v.name = [[[self delegate] delegate] nameForUserID:userID];
        
        NSDate* fbdate = [NSDate dateWithTimeIntervalSince1970:[[elem objectForKey:@"time"] doubleValue]];

		int diff = 0 - [fbdate timeIntervalSinceNow];
		if (diff > 86400)
		{
			int n = (int)(diff / 86400);
			v.time = (n == 1 ? @"1 day ago" : [NSString stringWithFormat:localize(@"%d days ago"), n]);
		}
		else if (diff > 3600)
		{
			int n = (int)(diff / 3600);
			if (diff % 3600 > 1800)
				n++;

			v.time = (n == 1 ? @"about 1 hour ago" : [NSString stringWithFormat:localize(@"about %d hours ago"), n]);
		}
		else if (diff > 60)
		{
			int n = (int)(diff / 60);
			if (diff % 60 > 30)
				n++;

			v.time = (n == 1 ? @"1 minute ago" : [NSString stringWithFormat:localize(@"%d minutes ago"), n]);
		}
		else
		{
			v.time = (diff == 1 ? @"1 second ago" : [NSString stringWithFormat:localize(@"%d seconds ago"), diff]);
		}
	}
	
	[v setNeedsDisplay];
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.comments count] + 2 + (([self.comments count] == self.noComments) ? 0 : 1) + ((self.postingComment) ? 1 : 0);
}

- (void)clearData
{
    [self.comments removeAllObjects];
    self.noComments = nil;
    self.noLikes = nil;
    self.userLikes = nil;
    self.allowComments = nil;
    self.allowLikes = nil;
    self.streamRowIndex = nil;
    self.postID = nil;
    self.name = nil;
    self.time = nil;
    self.post = nil;
    self.image = (id)[NSNull null];
}

#pragma mark -
#pragma mark Pull to refresh methods

// called when the user pulls-to-refresh
- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view
{
    [self performSelectorInBackground:@selector(reloadComments) withObject:nil];
}

// called when the date shown needs to be updated, optional
- (NSDate *)pullToRefreshViewLastUpdated:(PullToRefreshView *)view
{
    return self.lastUpdate;
}


@end
