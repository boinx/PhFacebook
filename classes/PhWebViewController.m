//
//  PhWebViewController.m
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "PhWebViewController.h"
#import "PhFacebook_URLs.h"
#import "PhFacebook.h"
#import "PhAuthenticationToken.h"

@interface PhWebViewController () <NSPopoverDelegate, WKNavigationDelegate>

@property (strong) WKWebView *webView;
@property (strong) NSPopover *popover;

@property (strong) NSString *appID;
@property (strong) NSString *permissions;

@property (copy) PhTokenRequestCompletionHandler completionHandler;

@end


@implementation PhWebViewController

- (id)initWithApplicationID:(NSString *)appID permissions:(NSString *)permissions
{
	self = [super initWithNibName:self.className bundle:[NSBundle bundleForClass:self.class]];
	
	if (self)
	{
		self.appID = appID;
		self.permissions = permissions;
		
		NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		for (NSHTTPCookie *cookie in [storage cookies])
		{
			if ([cookie.domain rangeOfString:@"facebook.com"].location != NSNotFound)
			{
				[storage deleteCookie:cookie];
			}
		}
		
		WKWebViewConfiguration *config = [WKWebViewConfiguration new];
		
		if ([config respondsToSelector:@selector(setWebsiteDataStore:)])
		{
			config.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
		}
		
		self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
		self.webView.navigationDelegate = self;
		
		self.popover = [NSPopover new];
		self.popover.delegate = self;
		self.popover.contentViewController = self;
		self.popover.behavior = NSPopoverBehaviorSemitransient;
	}
	
	return self;
}

- (void) dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)viewDidDisappear
{
    [super viewDidDisappear];
    [self.popover close];
    if (self.completionHandler)
    {
        self.completionHandler(nil, nil);
    }
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	self.webView.frame = self.view.bounds;
	[self.view addSubview:self.webView];
}

- (void) showFromView:(NSView *)view completionHandler:(PhTokenRequestCompletionHandler)completion
{
    // NSPopovers don't play well with NSOutlineView nodes being expanded or collapsed:
    // The NSPopover will stay at the same position.
    // Therefore, let me know when that happens, so I can close the popover
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(parentViewDidChange:)
                               name:NSOutlineViewItemDidExpandNotification
                             object:view];
    [notificationCenter addObserver:self
                           selector:@selector(parentViewDidChange:)
                               name:NSOutlineViewItemDidCollapseNotification
                             object:view];
	
	NSString *authURL;
	if (self.permissions)
	{
		authURL = [NSString stringWithFormat: kFBAuthorizeWithScopeURL, self.appID, kFBLoginSuccessURL, self.permissions];
	}
	else
	{
		authURL = [NSString stringWithFormat: kFBAuthorizeURL, self.appID, kFBLoginSuccessURL];
	}

	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:authURL]]];
	
	[self.popover showRelativeToRect:view.bounds ofView:view preferredEdge:NSMaxYEdge];
	
	self.completionHandler = completion;
}

/**
 When the view that our login popover or login window is attached to (we call it "parent") changes
 in specific ways (like an outline view expanding a node) we close the login popover/window.
 
 @discussion
 NSPopovers don't play well with NSOutlineView nodes being expanded or collapsed:
 The NSPopover will stay at the same position
 */
- (void) parentViewDidChange:(NSNotification *)notification
{
    [self.popover close];
}

- (void) popoverWillClose: (NSNotification *)notification
{
	if (self.completionHandler)
	{
		self.completionHandler(nil, nil);
	}
}

/**
 Sets the popover property to nil so we break the retain cycle 
 */
- (void) popoverDidClose:(NSNotification *)notification
{
    // Will dealloc popover and in turn self (because no longer retained by popover)
    self.popover = nil;
}

#pragma mark WKWebView delegate

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    [self showError:error];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
	NSString *url = webView.URL.absoluteString;
    NSLog(@"didFinishLoadForFrame: {%@}", [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]);

    NSString *urlWithoutSchema = [url substringFromIndex: [@"http://" length]];
    if ([url hasPrefix: @"https://"])
	{
        urlWithoutSchema = [url substringFromIndex: [@"https://" length]];
	}
	
    NSString *loginSuccessURLWithoutSchema = [kFBLoginSuccessURL substringFromIndex: 8];
    NSComparisonResult res = [urlWithoutSchema compare: loginSuccessURLWithoutSchema options: NSCaseInsensitiveSearch range: NSMakeRange(0, [loginSuccessURLWithoutSchema length])];
    if (res == NSOrderedSame)
    {
        NSString *accessToken = [self extractParameter: kFBAccessToken fromURL: url];
        NSString *tokenExpires = [self extractParameter: kFBExpiresIn fromURL: url];
        NSString *errorReason = [self extractParameter: kFBErrorReason fromURL: url];
        
        if (errorReason)
		{
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      errorReason, NSLocalizedDescriptionKey,
                                      nil];
            // For lack of better code picked arbitrary
			if (self.completionHandler)
			{
				self.completionHandler(nil, [NSError errorWithDomain:@"PhFacebookError" code:-1 userInfo:userInfo]);
				self.completionHandler = nil;
			}
        }
		
		if (self.completionHandler)
		{
			PhAuthenticationToken *token = [[PhAuthenticationToken alloc] initWithToken:accessToken secondsToExpiry:tokenExpires.floatValue permissions:self.permissions];
			self.completionHandler(token, nil);
			self.completionHandler = nil;
		}
		
		
		if ([self.popover isShown])
		{
			[self.popover close];
		}
		else
		{
			// If popover was not shown we have to manually trigger a notification
			[self popoverWillClose:[NSNotification notificationWithName:@"" object:nil]];
		}
    }
}

#pragma mark Utility

- (NSString*) extractParameter: (NSString*) param fromURL: (NSString*) url
{
	NSString *res = nil;
	
	NSRange paramNameRange = [url rangeOfString: param options: NSCaseInsensitiveSearch];
	if (paramNameRange.location != NSNotFound)
	{
		// Search for '&' or end-of-string
		NSRange searchRange = NSMakeRange(paramNameRange.location + paramNameRange.length, [url length] - (paramNameRange.location + paramNameRange.length));
		NSRange ampRange = [url rangeOfString: @"&" options: NSCaseInsensitiveSearch range: searchRange];
		if (ampRange.location == NSNotFound)
			ampRange.location = [url length];
		res = [url substringWithRange: NSMakeRange(searchRange.location, ampRange.location - searchRange.location)];
	}
	
	return res;
}


- (NSError *) errorFromFacebookError:(NSDictionary *)facebookError
{
    if (!facebookError) return nil;
    
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    NSString *errorMessage = [myBundle localizedStringForKey: @"FBAuthWindowErrorGenericMessage" value: @"" table: nil];
    
	NSUInteger errorCode = [[facebookError valueForKey:@"code"] unsignedIntegerValue];

	NSDictionary *userInfo = @{NSLocalizedDescriptionKey: errorMessage};
    return [NSError errorWithDomain:@"PhFacebookError" code:errorCode userInfo:userInfo];
}

- (void) showError:(NSError *)error
{
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    NSString *messagePath = [myBundle pathForResource:@"error_message" ofType:@"html"];
    NSURL *baseURL = [NSURL fileURLWithPath:[messagePath stringByDeletingLastPathComponent]];
    NSError *fileLoadingError = nil;
    NSString *errorIntro = [myBundle localizedStringForKey: @"FBAuthWindowErrorIntro" value: @"" table: nil];
    NSString *messageFormat = [NSString stringWithContentsOfFile:messagePath
                                                        encoding:NSUTF8StringEncoding
                                                           error:&fileLoadingError];
    NSString *errorMessage = [NSString stringWithFormat:messageFormat, errorIntro, error.localizedDescription];
    
    [self.webView loadHTMLString:errorMessage baseURL:baseURL];
    
    // Always log error to console to support support
    NSLog(@"%@: %@", errorIntro, error);
}
@end
