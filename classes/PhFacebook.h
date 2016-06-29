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


@interface PhFacebook : NSObject

/*! 
 * @discussion You get the \c appID parameter from the facebook developer homepage: https://developers.facebook.com/apps/
 * @param appID: facebook application identifier
 * @param token: if available a restored authentication (will be cached in memory and used if not expired)
 */
- (id)initWithApplicationID:(NSString *)appID existingToken:(PhAuthenticationToken *)token NS_DESIGNATED_INITIALIZER;

/*!
 * @discussion Use this method to load a token from facebook (e. g. login and request permissions)
 * @param permissions:	an array of required permissions, see: https://developers.facebook.com/docs/authentication/permissions
 * @param view:			view from which to open the popup
 * @param completion:	block invoked when either a token is available or an error occured
 */
- (void)getAccessTokenForPermissions:(NSArray *)permissions
						   fromView:(NSView *)host
						  completion:(PhTokenRequestCompletionHandler)completion;

/*
 * STILL NEEDS TO BE DONE
 */
// request: the short version of the Facebook Graph API, e.g. "me/feed"
// see http://developers.facebook.com/docs/api
- (void) sendRequest: (NSString*) request;
- (NSDictionary *)sendSynchronousRequest:(NSString *)request HTTPMethod:(NSString *)method params:(NSDictionary *)params;

// Method is GET
- (NSDictionary *)sendSynchronousRequest:(NSString *)request params:(NSDictionary *)params;
- (NSDictionary *)sendSynchronousRequest:(NSString *)request;

// query: the query to send to FQL API, e.g. "SELECT uid, sex, name from user WHERE uid = me()"
// see http://developers.facebook.com/docs/reference/fql/
- (void) sendFQLRequest: (NSString*) query;

/**
 Sends an FQL query synchronously
 
 @returns Dictionary containing the following keys: request (string), sender, result (as string), resultDict, raw (raw result data), Error
 */
- (NSDictionary *)sendSynchronousFQLRequest:(NSString *)query;


@end

