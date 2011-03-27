//
//  OAuth.h
//
//  Created by Jaanus Kase on 12.01.10.
//  Copyright 2010. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FacebookAuth : NSObject {
	NSString
		// my app credentials
		*oauth_consumer_key,
		*oauth_consumer_secret,
	
		// fixed to "HMAC-SHA1"
		*oauth_signature_method,
	
		// calculated at runtime for each signature
		*oauth_timestamp,
		*oauth_nonce,
	
		// Fixed to "1.0"
		*oauth_version,
	
		// We obtain these from the provider.
		// These may be either request token (oauth 1.0a 6.1.2) or access token (oauth 1.0a 6.3.2);
		// determine semantics with oauth_token_authorized and call synchronousVerifyCredentials
		// if you want to be really sure.
		*access_token,
		*oauth_token,
		*oauth_token_secret,	
		
		// From Facebook. May or may not be applicable to other providers.
		*user_id,
		*screen_name;
	
	// YES if this token has been authorized and can be used for production calls.
	// You need to save and load the state of this yourself, but you don't need to
	// modify it during runtime.
	BOOL oauth_token_authorized;	
}

// This is really the only critical oAuth method you need.
- (NSString *) oAuthHeaderForMethod:(NSString *)method andUrl:(NSString *)url andParams:(NSDictionary *)params;	

// If you detect a login state inconsistency in your app, use this to reset the context back to default,
// not-logged-in state.
- (void) forget;
-(BOOL) authorized;

// Facebook convenience methods
- (BOOL) requestFacebookToken;
- (BOOL) authorizeFacebookToken;

// Internal methods, no need to call these directly from outside.
- (NSString *) OAuthorizationHeader:(NSURL*) url method:(NSString *)method body:(NSData*) body;
- (NSString *) sha1:(NSString *)str;

@property (assign) BOOL oauth_token_authorized;
@property (copy) NSString *access_token;
@property (copy) NSString *oauth_token;
@property (copy) NSString *oauth_token_secret;
@property (copy) NSString *user_id;
@property (copy) NSString *screen_name;

@end
