//
//  PhFacebook.m
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhFacebook.h"
#import "PhWebViewController.h"
#import "PhAuthenticationToken.h"
#import "PhFacebook_URLs.h"

@interface PhFacebook ()

@property (atomic, strong) NSString *appID;
@property (atomic, strong, readwrite) PhAuthenticationToken *authenticationToken;

@property (atomic, strong) PhWebViewController *webViewController;

@property (atomic, strong) NSURLSession *urlSession;

@end

@implementation PhFacebook


#pragma mark - Initialization

- (id)initWithApplicationID:(NSString *)appID existingToken:(PhAuthenticationToken *)token 
{
	self = [super init];
	if (self)
	{
		self.appID = appID;
		self.authenticationToken = token;
		self.webViewController = nil;
		
		self.urlSession = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
	}
	
	return self;
}


#pragma mark - Tokens

- (void)clearAuthenticationToken
{
    self.authenticationToken = nil;
}

#pragma mark - Requests

- (void)sendRequest:(NSString *)path completionHandler:(PhRequestCompletionHandler)completion
{
	[self sendRequest:path parameters:nil completionHandler:completion];
}

- (void)sendRequest:(NSString *)path parameters:(NSDictionary *)params completionHandler:(PhRequestCompletionHandler)completion
{
	[self sendRequest:path method:PhRequestMethodGET parameters:params completionHandler:completion];
}

- (void)sendRequest:(NSString *)path method:(PhRequestMethod)method parameters:(NSDictionary *)params completionHandler:(PhRequestCompletionHandler)completion
{
	[self sendRequest:path method:method parameters:params authToken:nil completionHandler:completion];
}

- (void)sendRequest:(NSString *)path method:(PhRequestMethod)method parameters:(NSDictionary *)params authToken:(NSString *)authToken completionHandler:(PhRequestCompletionHandler)completion
{
	NSString *token = authToken;
    
	if (!token)
	{
        // NOTE: Some facebook accounts have expiry date and some don't.
        // - The assumption that the expiry date exists is not safe.
        // - The assumption that the expiry date is valid is not safe.
        if (!self.authenticationToken)
        {
            // Warning: 510 is the accessTokenUnavailable BXAccount error code.
            completion(nil, [NSError errorWithDomain:@"PhFacebook" code:510 userInfo:nil]);
            return;
        }
        else
        {
            token = self.authenticationToken.authenticationToken;
        }
	}
	
    /*
        The token is allowed to be nil if the authenticationToken.code is not nil.
        We will receive the proper accessToken and create a new PhAuthenticationToken object.
        if both tokens are nil which shouldn't happen then the user would receive the following error message:
        "An active access token must be used to query information about the current user."
        This user scenario should never happen because of PhAuthenticationToken class structure and init.
     */
    
    // if the token turns out garbage or an empty String:
    // token = @"sdasdasdass";
    // OR
    // token = @"";
    // Host app presents: "Account token expired." with renew option.

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		//Find which method to use for the request
		NSString *httpMethod;
		
		switch (method) {
			case PhRequestMethodGET:
				httpMethod = @"GET";
				break;
				
			case PhRequestMethodPOST:
				httpMethod = @"POST";
				break;
				
			default:
				break;
		}
		
		//Generate the URL to the request
		NSString *fbURL = [NSString stringWithFormat:kFBGraphURL, path];
		
		
		//Append the access token to the parameters
		NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
		if (params)
		{
			parameters = [params mutableCopy];
		}
		parameters[@"access_token"] = token;
		
		NSString *encodedParameters = @"";
		for (NSString *key in parameters.allKeys)
		{
			NSString *value = [self stringByAddingPercentEncodingForFormData:parameters[key]];
			
			encodedParameters = [encodedParameters stringByAppendingFormat:@"%@%@=%@", (encodedParameters.length > 1 ? @"&" : @""), key, value];
		}
		
		if (method == PhRequestMethodGET)
		{
			//Append params
			if ([path rangeOfString:@"?"].location != NSNotFound)
			{
				//What are they doing? Anyway, simply append the parameters
				fbURL = [fbURL stringByAppendingFormat:@"&%@", encodedParameters];
			}
			else
			{
				fbURL = [fbURL stringByAppendingFormat:@"?%@", encodedParameters];
			}
		}
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fbURL]];
		request.HTTPMethod = httpMethod;
		
		if (method == PhRequestMethodPOST)
		{
			NSData *requestData = [encodedParameters dataUsingEncoding:NSUTF8StringEncoding];
			request.HTTPBody = requestData;
			[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
		}
		
		NSURLSessionDataTask *task = [self.urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
			NSDictionary *responseDict = nil;
			
			NSError *returnError = error;
			
			if (!returnError && data)
			{
				responseDict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&returnError];
			}
			
			if (!returnError && responseDict[@"error"])
			{
				NSDictionary *errorDict = responseDict[@"error"];
				
				NSInteger code = -1;
				if (errorDict[@"code"])
				{
					code = [errorDict[@"code"] integerValue];
				}
				
				NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
				
				if (errorDict[@"message"])
				{
					[userInfo setObject:errorDict[@"message"] forKey:NSLocalizedDescriptionKey];
				}
				
				returnError = [NSError errorWithDomain:@"PhFacebookErrorDomain" code:code userInfo:userInfo];
			}
			
			completion(responseDict, returnError);
		}];
		[task resume];
	});
}

- (NSString *)stringByAddingPercentEncodingForFormData:(NSString *)input
{
	NSString *unreserved = @"*-._";
	NSMutableCharacterSet *allowed = [NSMutableCharacterSet
									  alphanumericCharacterSet];
	[allowed addCharactersInString:unreserved];
	
	NSString *encoded = [input stringByAddingPercentEncodingWithAllowedCharacters:allowed];

	return encoded;
}

@end
