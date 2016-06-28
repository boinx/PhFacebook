//
//  PhWebViewController.h
//  PhFacebook
//
//  Created by Philippe on 10-08-27.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@class PhFacebook;

@interface PhWebViewController : NSViewController <NSWindowDelegate, NSFileManagerDelegate>

@property (weak) IBOutlet WebView *webView;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) PhFacebook *parent;
@property (nonatomic, strong) NSString *permissions;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (void) setRelativeToRect:(NSRect)relativeToRect ofView:(NSView *)view;
- (IBAction) cancel: (id) sender;

@end
