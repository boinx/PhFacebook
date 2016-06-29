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
@property (atomic, weak) id delegate;
@property (atomic, strong) PhWebViewController *webViewController;
@property (atomic, strong) PhAuthenticationToken *authToken;
@property (atomic, strong) NSString *permissions;

@end

@implementation PhFacebook

#pragma mark Initialization

- (id)initWithApplicationID:(NSString *)appID existingToken:(PhAuthenticationToken *)token 
{
	self = [super init];
	if (self)
	{
		self.appID = appID;
		self.authToken = token;
		self.webViewController = nil;
		self.authToken = nil;
		self.permissions = nil;
	}
	
	return self;
}

#pragma mark Access

- (void) clearToken
{
    self.authToken = nil;
}

- (void)getAccessTokenForPermissions:(NSArray *)permissions
						   fromView:(NSView *)host
						  completion:(PhTokenRequestCompletionHandler)completion
{
	NSString *scope = [permissions componentsJoinedByString: @","];
	
	if ([self.authToken.permissions isCaseInsensitiveLike: scope])
	{
		// We already have a token for these permissions; check if it has expired or not
		if (self.authToken.expiry == nil || [[self.authToken.expiry laterDate:NSDate.date] isEqual:self.authToken.expiry])
		{
			completion(self.authToken, nil);
			return;
		}
	}
	
	[self clearToken];
	
	// Retrieve token from web page
	if (self.webViewController == nil)
	{
		self.webViewController = [[PhWebViewController alloc] initWithApplicationIdentifier:self.appID permissions:scope];
		[self.webViewController loadView];
	}
	
	[self.webViewController showFromView:host completionHandler:^(PhAuthenticationToken *token, NSError *error) {
		self.authToken = token;
		completion(token, error);
	}];
}

- (NSDictionary*) resultFromRequest:(NSString *)request data:(NSData *)data
{
    NSDictionary *result = nil;
    NSString *responseStr = nil;
    NSDictionary *responseDict = nil;
    id facebookError = nil;
    if (data) {
        responseStr = [[NSString alloc] initWithBytesNoCopy: (void*)[data bytes]
                                                     length: [data length]
                                                   encoding:NSASCIIStringEncoding
                                               freeWhenDone: NO];
        
        // Structured data returned from Facebook
        responseDict = (NSDictionary *) [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        // May contain a Facebook error
        facebookError = [responseDict valueForKey:@"error"];
    }
    // Any nil in parameter list of NSDictionary creation will terminate parameter list
    if (facebookError && [facebookError isKindOfClass:[NSDictionary class]]) {
        result = [NSDictionary dictionaryWithObjectsAndKeys:
                  request, @"request",
                  self, @"sender",
                  facebookError, @"error",
//                  data, @"raw",
                  responseStr, @"result",
                  responseDict, @"resultDict",
                  nil];
    } else {
        result = [NSDictionary dictionaryWithObjectsAndKeys:
                  request, @"request",
                  self, @"sender",
//                  data, @"raw",
                  responseStr, @"result",
                  responseDict, @"resultDict",
                  nil];
    }
    return result;
}

- (NSDictionary *)_doRequest:(NSDictionary *)allParams
{
    NSDictionary *result = nil;
    
    if (self.authToken)
    {
        //        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        NSString *request = [allParams objectForKey: @"request"];
        NSString *str;
        
        // Determine request method
        
        NSString *requestMethod = [allParams objectForKey:@"requestMethod"];
        BOOL postRequest = NO;
        if (requestMethod) {
            if ([requestMethod isEqualToString:@"POST"]) {
                postRequest = YES;
            }
        } else {
            postRequest = [[allParams objectForKey: @"postRequest"] boolValue];
            requestMethod = postRequest ? @"POST" : @"GET";
        }
        
        if (postRequest)
        {
            str = [NSString stringWithFormat: kFBGraphApiPostURL, request];
        }
        else
        {
            // Check if request already has optional parameters
            NSString *formatStr = kFBGraphApiGetURL;
            NSRange rng = [request rangeOfString:@"?"];
            if (rng.length > 0)
                formatStr = kFBGraphApiGetURLWithParams;
            str = [NSString stringWithFormat: formatStr, request, self.authToken.authenticationToken];
        }
        
        
        NSDictionary *params = [allParams objectForKey: @"params"];
        NSMutableString *strPostParams = nil;
        if (params != nil)
        {
            if (postRequest)
            {
                strPostParams = [NSMutableString stringWithFormat: @"access_token=%@", self.authToken.authenticationToken];
                for (NSString *p in [params allKeys])
                    [strPostParams appendFormat: @"&%@=%@", p, [params objectForKey: p]];
            }
            else
            {
                NSMutableString *strWithParams = [NSMutableString stringWithString: str];
                for (NSString *p in [params allKeys])
                    [strWithParams appendFormat: @"&%@=%@", p, [params objectForKey: p]];
                str = strWithParams;
            }
        }
        
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: str]];
        [req setHTTPMethod:requestMethod];
        
        if (postRequest)
        {
            NSData *requestData = [NSData dataWithBytes: [strPostParams UTF8String] length: [strPostParams length]];
            [req setHTTPBody: requestData];
            [req setValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"content-type"];
        }
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        
        NSLog(@"Sending %@ request: %@", requestMethod, req.URL);
        
        NSData *data = [NSURLConnection sendSynchronousRequest: req returningResponse: &response error: &error];
        
        // Error out parameter from sending request is not yet taken into consideration
        
        result = [self resultFromRequest:request data:data];
    }
    return result;
}

- (void) sendFacebookRequest:(NSDictionary *)allParams
{
    if ([self.delegate respondsToSelector:@selector(requestResult:)])
    {
        NSDictionary *result = [self _doRequest:allParams];
        [self.delegate performSelectorOnMainThread:@selector(requestResult:) withObject: result waitUntilDone:YES];
    }
}

- (void) sendRequest:(NSString*) request
{
    NSDictionary *allParams = [self allParams:nil request:request HTTPMethod:@"GET"];
    [NSThread detachNewThreadSelector:@selector(sendFacebookRequest:) toTarget:self withObject:allParams];
}

- (NSDictionary *)sendSynchronousFacebookRequest:(NSDictionary *)allParams
{
    NSDictionary* result = [self _doRequest:allParams];
    return result;
}

- (NSDictionary *)allParams:(NSDictionary*)params request:(NSString *)request HTTPMethod:(NSString *)method
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            request, @"request",
            method, @"requestMethod",
            params, @"params", nil];        // params may be nil
}

- (NSDictionary *)sendSynchronousRequest:(NSString *)request
                              HTTPMethod:(NSString *)method
                                  params:(NSDictionary *)params
{
    NSDictionary *allParams = [self allParams:params request:request HTTPMethod:method];
    return [self sendSynchronousFacebookRequest:allParams];
}

- (NSDictionary *)sendSynchronousRequest:(NSString *)request params:(NSDictionary *)params
{
    return [self sendSynchronousRequest:request HTTPMethod:@"GET" params:params];
}

- (NSDictionary *)sendSynchronousRequest:(NSString *)request
{
    return [self sendSynchronousRequest:request params:nil];
}

/**
 Sends an FQL query synchronously
 
 @returns Dictionary containing the following keys: request (string), sender, result (as string), resultDict, raw (raw result data), Error
 */
- (NSDictionary *)sendSynchronousFQLRequest:(NSString *)query
{
    NSDictionary *result = nil;
    
    if (self.authToken)
    {
        NSString *str = [NSString stringWithFormat: kFBGraphApiFqlURL, [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], self.authToken.authenticationToken];
        
        NSLog(@"FQL query request: %@", str);
        
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: str]];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest: req returningResponse: &response error: &error];
        
        // Error out parameter from sending request is not yet taken into consideration
        
        result = [self resultFromRequest:query data:data];
    }
    return result;
}

- (void) sendFacebookFQLRequest: (NSString*) query
{
    @autoreleasepool {

        if (self.authToken)
        {
            NSString *str = [NSString stringWithFormat: kFBGraphApiFqlURL, [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], self.authToken.authenticationToken];

            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: str]];

            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest: req returningResponse: &response error: &error];

            if ([self.delegate respondsToSelector: @selector(requestResult:)])
            {
                NSString *str = [[NSString alloc] initWithBytesNoCopy: (void*)[data bytes] length: [data length] encoding:NSASCIIStringEncoding freeWhenDone: NO];

                NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                                        str, @"result",
                                        query, @"request",
                                        data, @"raw",
                                        self, @"sender",
                                        nil];
                [self.delegate performSelectorOnMainThread:@selector(requestResult:) withObject: result waitUntilDone:YES];
            }
        }
    }
}

- (void) sendFQLRequest: (NSString*) query
{
    [NSThread detachNewThreadSelector: @selector(sendFacebookFQLRequest:) toTarget: self withObject: query];
}


@end
