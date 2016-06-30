//
//  PhAuthenticationToken.h
//  PhFacebook
//
//  Created by Philippe on 10-08-29.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PhAuthenticationToken : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSString *authenticationToken;
@property (nonatomic, strong, readonly) NSDate *expiry;
@property (nonatomic, strong, readonly) NSString *permissions;

- (instancetype)initWithToken:(NSString *)token secondsToExpiry:(NSTimeInterval)seconds permissions:(NSString *)perms;

@end
