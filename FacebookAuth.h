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
		// determine semantics with oauth_token_authorized.
		*access_token,
		*oauth_token,
    *oauth_token_secret;	
	
	// YES if this token has been authorized and can be used for production calls.
	// Don't access directly; use the authorized method to get the current state.
	BOOL oauth_token_authorized;	
}

// If you detect a login state inconsistency in your app, use this to reset the context back to default,
// not-logged-in state.
- (void) forget;
- (BOOL) authorized;

// Facebook convenience methods
- (NSString *) description;
- (BOOL) authorizeFacebookCode:(NSString*)code;

// Internal methods, no need to call these directly from outside.
- (NSString *) sha1:(NSString *)str;

@property (assign) BOOL oauth_token_authorized;
@property (copy) NSString *access_token;
@property (copy) NSString *oauth_token;
@property (copy) NSString *oauth_token_secret;

@end
