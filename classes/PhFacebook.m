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

- (void)getAccessTokenForPermissions:(NSArray *)permissions fromView:(NSView *)host completion:(PhTokenRequestCompletionHandler)completion
{
	NSString *scope = [permissions componentsJoinedByString: @","];
	
	if ([self.authenticationToken.permissions isCaseInsensitiveLike: scope])
	{
		// We already have a token for these permissions; check if it has expired or not
		if (self.authenticationToken.expiry == nil || [[self.authenticationToken.expiry laterDate:NSDate.date] isEqual:self.authenticationToken.expiry])
		{
			completion(self.authenticationToken, nil);
			return;
		}
	}
	
	[self clearAuthenticationToken];
	
	// Retrieve token from web page
	if (self.webViewController == nil)
	{
		self.webViewController = [[PhWebViewController alloc] initWithApplicationID:self.appID permissions:scope];
		[self.webViewController loadView];
	}
	
	[self.webViewController showFromView:host completionHandler:^(PhAuthenticationToken *token, NSError *error) {
		self.authenticationToken = token;
		completion(token, error);
	}];
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
	if (!self.authenticationToken || NSDate.date.timeIntervalSince1970 > self.authenticationToken.expiry.timeIntervalSince1970)
	{
		[self clearAuthenticationToken];
		
		completion(nil, [NSError errorWithDomain:@"PhFacebook" code:500 userInfo:nil]);
		return;
	}
	
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
		parameters[@"access_token"] = self.authenticationToken.authenticationToken;
		
		NSString *encodedParameters = @"";
		for (NSString *key in parameters.allKeys)
		{
			NSString *value = [parameters[key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			encodedParameters = [encodedParameters stringByAppendingFormat:@"%@=%@&", key, value];
		}
		encodedParameters = [encodedParameters substringToIndex:encodedParameters.length-1];
		
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
			
			if (data)
			{
				NSError *jsonError = nil;
				responseDict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
			}
			
			completion(responseDict, error);
		}];
		[task resume];
	});
}

@end
