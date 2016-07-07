//
//  PhFacebook.h
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PhAuthenticationToken;

/*!
 * @name PhTokenRequestCompletionHandler
 * @discussion Block invoked upon receiving a valid authentication token or an error that occured during login
 * @param token:	If successfull contains the facebook authentication token, nil otherwise
 * @param error:	Any error that occured during acquiring of the authentication token
 */

typedef void (^PhTokenRequestCompletionHandler)(PhAuthenticationToken *token, NSError *error);


/*!
 * @name PhRequestCompletionHandler
 * @discussion Block invoked after executing a facebook request
 * @param result:	If successfull contains the facebook result of the request
 * @param error:	Any error that occured during the request
 */

typedef void (^PhRequestCompletionHandler)(NSDictionary *result, NSError *error);


/*!
 * @brief HTTP method to be used for a request
 */

typedef NS_ENUM(NSUInteger, PhRequestMethod) {
    PhRequestMethodGET,
    PhRequestMethodPOST,
};


@interface PhFacebook : NSObject

/*! 
 * @discussion You get the \c appID parameter from the facebook developer homepage: https://developers.facebook.com/apps/
 * @param appID: facebook application identifier
 * @param token: if available a restored authentication (will be cached in memory and used if not expired)
 */

- (id)initWithApplicationID:(NSString *)appID
			  existingToken:(PhAuthenticationToken *)token;


/*!
 * @discussion Use this method to load a token from facebook (e. g. login and request permissions)
 * @param permissions:	an array of required permissions, see: https://developers.facebook.com/docs/authentication/permissions
 * @param view:			view from which to open the popup
 * @param completion:	block invoked when either a token is available or an error occured
 */

- (void)getAccessTokenForPermissions:(NSArray *)permissions
							fromView:(NSView *)host
						  completion:(PhTokenRequestCompletionHandler)completion;


/*!
 * @brief The token which will be used for requests. You can store this in the keychain and reuse it in the \c initWithApplicationID:existingToken call
 */
@property (atomic, strong, readonly) PhAuthenticationToken *authenticationToken;


/*!
 * @brief clears the current active authentication token. Requires a call to \c getAccessTokenForPermissions:fromView:completion: afterwards
 */
- (void)clearAuthenticationToken;


/*!
 * @discussion Use this method to make a simple GET request without parameters
 * @param path:			path of the Graph API to query, see: http://developers.facebook.com/docs/api
 * @param completion:	block invoked when the request finished
 */

- (void)sendRequest:(NSString *)path completionHandler:(PhRequestCompletionHandler)completion;


/*!
 * @discussion Use this method to make a simple GET request
 * @param path:			path of the Graph API to query, see: http://developers.facebook.com/docs/api
 * @param params:		parameter of the request
 * @param completion:	block invoked when the request finished
 */

- (void)sendRequest:(NSString *)path parameters:(NSDictionary *)params completionHandler:(PhRequestCompletionHandler)completion;


/*!
 * @discussion Use this method to make a Graph API request
 * @param path:			path of the Graph API to query, see: http://developers.facebook.com/docs/api
 * @param params:		parameter of the request
 * @param completion:	block invoked when the request finished
 */

- (void)sendRequest:(NSString *)path method:(PhRequestMethod)method parameters:(NSDictionary *)params completionHandler:(PhRequestCompletionHandler)completion;


/*!
 * @discussion Use this method to make a Graph API request with a custom token
 * @param path:			path of the Graph API to query, see: http://developers.facebook.com/docs/api
 * @param params:		parameter of the request
 * @param authToken:	token to use for the request (nil for the default token)
 * @param completion:	block invoked when the request finished
 */

- (void)sendRequest:(NSString *)path method:(PhRequestMethod)method parameters:(NSDictionary *)params authToken:(NSString *)authToken completionHandler:(PhRequestCompletionHandler)completion;

@end
