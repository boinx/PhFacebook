//
//  PhFacebook.m
//  PhFacebook
//
//  Created by Philippe on 10-08-25.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhFacebook.h"
#import "PhWebViewController.h"
#import "PhFacebook_URLs.h"


@implementation PhFacebook

#pragma mark Initialization

- (id) initWithApplicationID: (const NSString*) appID delegate: (id) delegate
{
    if ((self == [super init]))
    {
        _appID = [appID copy];
        _delegate = delegate; // Don't retain delegate to avoid retain cycles
        _webViewController = nil;
    }
    NSLog(@"Initialized with AppID '%@'", _appID);

    return self;
}

- (void) dealloc
{
    [_appID release];
    [_webViewController release];
    [super dealloc];
}

#pragma mark Access

- (void) getAccessTokenForPermissions: (NSArray*) permissions
{
    NSString *authURL;
    NSString *scope = [permissions componentsJoinedByString: @","];
    if (scope)
        authURL = [NSString stringWithFormat: kFBAuthorizeWithScopeURL, _appID, kFBLoginSuccessURL, scope];
    else
        authURL = [NSString stringWithFormat: kFBAuthorizeURL, _appID, kFBLoginSuccessURL];

    // Retrieve token from web page
    if (_webViewController == nil)
    {
        _webViewController = [[PhWebViewController alloc] init];
        [NSBundle loadNibNamed: @"FacebookBrowser" owner: _webViewController];
    }
    
    _webViewController.parent = self;
    [_webViewController.webView setMainFrameURL: authURL];
    [_webViewController.window makeKeyAndOrderFront: self];
}

- (void) setAccessToken: (NSString*) accessToken expires: (NSString*) tokenExpires error: (NSString*) errorReason
{
    [_webViewController.window orderOut: self];

    if (accessToken)
    {
        NSLog(@"Access token='%@', expires='%@'", accessToken, tokenExpires);
        if ([_delegate respondsToSelector: @selector(validToken:)])
            [_delegate validToken: self];
    }
    else
    {
        NSLog(@"Error! reason='%@'", errorReason);
    }
}

@end
