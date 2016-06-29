//
//  PhWebViewController.h
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PhAuthenticationToken;

typedef void (^PhTokenRequestCompletionHandler)(PhAuthenticationToken *token, NSError *error);

@interface PhWebViewController : NSViewController

- (id)initWithApplicationIdentifier:(NSString *)appID permissions:(NSString *)permissions;
- (void)showFromView:(NSView *)view completionHandler:(PhTokenRequestCompletionHandler)completion;

@end
