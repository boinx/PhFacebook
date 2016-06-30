//
//  PhWebViewController.h
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PhFacebook.h"

@class PhAuthenticationToken;

@interface PhWebViewController : NSViewController

- (id)initWithApplicationID:(NSString *)appID permissions:(NSString *)permissions;

- (void)showFromView:(NSView *)view completionHandler:(PhTokenRequestCompletionHandler)completion;

@end
