//
//  PhFacebook.h
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PhWebViewController;
@class PhAuthenticationToken;

@interface PhFacebook : NSObject
{
@private
    NSString *_appID;
    id _delegate;
    PhWebViewController *_webViewController;
    PhAuthenticationToken *_authToken;
    NSString *_permissions;
}

- (id) initWithApplicationID: (NSString*) appID delegate: (id) delegate;

// permissions: an array of required permissions
//              see http://developers.facebook.com/docs/authentication/permissions
// canCache: save and retrieve token locally if not expired
- (void) getAccessTokenForPermissions: (NSArray*) permissions cached: (BOOL) canCache;

// request: the short version of the Facebook Graph API, e.g. "me/feed"
// see http://developers.facebook.com/docs/api
- (void) sendRequest: (NSString*) request;
- (void) sendRequest: (NSString*) request params: (NSDictionary*) params usePostRequest: (BOOL) postRequest;

- (void) invalidateCachedToken;

- (void) setAccessToken: (NSString*) accessToken expires: (NSTimeInterval) tokenExpires permissions: (NSString*) perms error: (NSString*) errorReason;
- (NSString*) accessToken;

- (void) webViewWillShowUI;
- (void) didDismissUI;

@end

@protocol PhFacebookDelegate

@required
- (void) tokenResult: (NSDictionary*) result;
- (void) requestResult: (NSDictionary*) result;

@optional
// needsAuthentication is called before showing authentication WebView
// if it returns true, default login window will not be shown and
// application is responsible for authentication UI
- (BOOL) needsAuthentication: (NSString*) authURL forPermissions: (NSString*) permissions; 
- (void) willShowUINotification: (PhFacebook*) sender;
- (void) didDismissUI: (PhFacebook*) sender;

@end