//
//  OAuth.m
//
//  Created by Jaanus Kase on 12.01.10.
//  Copyright 2010. All rights reserved.
//

#import "FacebookAuth.h"
#import "KeychainUtils.h"
#import <CommonCrypto/CommonHMAC.h>

@interface NSString (FacebookAuthAdditions)

- (NSString *)encodedURLString;
- (NSString *)encodedURLParameterString;
- (NSString *)decodedURLString;
- (NSString *)removeQuotes;

@end

@implementation NSString (FacebookAuthAdditions)

- (NSString *)encodedURLString {
	NSString* result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)self,
                                                                           NULL,                   // characters to leave unescaped (NULL = all escaped sequences are replaced)
                                                                           CFSTR("?=&+"),          // legal URL characters to be escaped (NULL = all legal characters are replaced)
                                                                           kCFStringEncodingUTF8); // encoding
	return [result autorelease];
}

- (NSString *)encodedURLParameterString {
    	NSString* result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)self,
                                                                           NULL,
                                                                           CFSTR(":/=,!$&'()*;[]@#?"),
                                                                           kCFStringEncodingUTF8);
	return [result autorelease];
}

- (NSString *)decodedURLString {
	NSString *result = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
																						  (CFStringRef)self,
																						  CFSTR(""),
																						  kCFStringEncodingUTF8);
	
	return [result autorelease];
	
}

-(NSString *)removeQuotes
{
	NSUInteger length = [self length];
	NSString *ret = self;
	if ([self characterAtIndex:0] == '"') {
		ret = [ret substringFromIndex:1];
	}
	if ([self characterAtIndex:length - 1] == '"') {
		ret = [ret substringToIndex:length - 2];
	}
	
	return ret;
}

@end

static NSString* CONSUMER_KEY = @"";
static NSString* CONSUMER_SECRET  = @"";

@implementation FacebookAuth

@synthesize access_token;
@synthesize oauth_token;
@synthesize oauth_token_secret;
@synthesize oauth_token_authorized;
@synthesize user_id;
@synthesize screen_name;

#pragma mark -
#pragma mark Init and dealloc

/**
 * Initialize an OAuth context object with a given consumer key and secret. These are immutable as you
 * always work in the context of one app.
 */
- (id) init
{
	if (self = [super init]) {
		oauth_consumer_key = CONSUMER_KEY;
		oauth_consumer_secret = CONSUMER_SECRET;
		oauth_signature_method = @"HMAC-SHA1";
		oauth_version = @"1.0";
		srandom(time(NULL)); // seed the random number generator, used for generating nonces
		self.user_id = @"";
		self.screen_name = @"";

		NSError* error;
		self.access_token = [KeychainUtils getPasswordForUsername:@"OAuthToken" andServiceName:@"LockInfoFacebook" error:&error];
		self.oauth_token_authorized = (self.access_token.length > 0);
		if (!self.oauth_token_authorized)
		{
			self.access_token = @"";
		}
	}
	
	return self;
}

- (void) dealloc {
	[oauth_consumer_key release];
	[oauth_consumer_secret release];
	[oauth_token release];
	[oauth_token_secret release];
	[user_id release];
	[screen_name release];
	[super dealloc];
}

#pragma mark -
#pragma mark KVC

/**
 * We specify a set of keys that are known to be returned from OAuth responses, but that we are not interested in.
 * In case of any other keys, we log them since they may indicate changes in API that we are not prepared
 * to deal with, but we continue nevertheless.
 * This is only relevant for the Facebook request/authorize convenience methods that do HTTP calls and parse responses.
 */
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	// KVC: define a set of keys that are known but that we are not interested in. Just ignore them.
	if ([[NSSet setWithObjects:
		  @"oauth_callback_confirmed",
		  nil] containsObject:key]) {
		
	// ... but if we got a new key that is not known, log it.
	} else {
		NSLog(@"Got unknown key from provider response. Key: \"%@\", value: \"%@\"", key, value);
	}
}

#pragma mark -
#pragma mark Public methods

/**
 * When the user invokes the "sign out" function in the app, forget the current OAuth context.
 * We still remember consumer key and secret
 * since those are for an app and don't change, but we forget everything else.
 */
- (void) forget {
	self.oauth_token_authorized = NO;
	self.oauth_token = @"";
	self.oauth_token_secret = @"";
	self.user_id = @"";
	self.screen_name = @"";
}

- (NSString *) description {
	return [NSString stringWithFormat:@"OAuth context object with consumer key \"%@\", token \"%@\". Authorized: %@",
			oauth_consumer_key, self.oauth_token, self.oauth_token_authorized ? @"YES" : @"NO"]; 
}

#pragma mark -
#pragma mark Facebook convenience methods

-(BOOL) authorized
{
	return self.oauth_token_authorized;
}

/**
 * By this point, we have a token, and we have a verifier such as PIN from the user. We combine
 * these together and exchange the unauthorized token for a new, authorized one.
 *
 * This is the request/response specified in OAuth Core 1.0A section 6.3.
 */
- (BOOL) authorizeFacebookCode:(NSString*) code
{
	NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/oauth/access_token?client_id=%@&redirect_uri=http://lockinfo.ashman.com/&scope=read_stream,publish_stream&client_secret=%@&code=%@", CONSUMER_KEY, CONSUMER_SECRET, code];

	NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
	self.access_token = @"";

	NSLog(@"LI:Facebook: Access Token Request: %@", url);
	NSError* error;
        NSHTTPURLResponse* response;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	NSString* responseString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSArray *responseBodyComponents = [responseString componentsSeparatedByString:@"&"];

	// For a successful response, break the response down into pieces and set the properties
	// with KVC. If there's a response for which there is no local property or ivar, this
	// may end up with setValue:forUndefinedKey:.
	for (NSString *component in responseBodyComponents) 
	{
		NSArray *subComponents = [component componentsSeparatedByString:@"="];
		if (subComponents.count == 2)
			[self setValue:[subComponents objectAtIndex:1] forKey:[subComponents objectAtIndex:0]];			
	}

	if (self.access_token.length > 0)
	{
		self.oauth_token_authorized = YES;
		[KeychainUtils storeUsername:@"OAuthToken" andPassword:self.access_token forServiceName:@"LockInfoFacebook" updateExisting:YES error:&error];
		NSLog(@"LI:Facebook: Access Token: %@", self.access_token);

		return YES;
	}

	return NO;
}

#pragma mark -
#pragma mark Internal utilities for crypto, signing.

// http://stackoverflow.com/questions/1353771/trying-to-write-nsstring-sha1-function-but-its-returning-null
- (NSString *)sha1:(NSString *)str {
	const char *cStr = [str UTF8String];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(cStr, strlen(cStr), result);
	NSMutableString *out = [NSMutableString stringWithCapacity:20];
	for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
		[out appendFormat:@"%02X", result[i]];
	}
	return [out lowercaseString];
}


@end
