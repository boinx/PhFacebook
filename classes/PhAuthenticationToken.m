//
//  PhAuthenticationToken.m
//  PhFacebook
//
//  Created by Philippe on 10-08-29.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#import "PhAuthenticationToken.h"

@interface PhAuthenticationToken ()

@property (nonatomic, strong, readwrite) NSString *authenticationToken;
@property (nonatomic, strong, readwrite) NSDate *expiry;
@property (nonatomic, strong, readwrite) NSString *permissions;

@property (nonatomic, strong, readwrite) NSString *code;
@property (nonatomic, strong, readwrite) NSString *redirectUrl;

@end

@implementation PhAuthenticationToken

#pragma mark NSCoding Protocol

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.authenticationToken = [coder decodeObjectForKey:@"authenticationToken"];
        self.expiry = [coder decodeObjectForKey:@"expiry"];
        self.permissions = [coder decodeObjectForKey:@"permissions"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.authenticationToken forKey:@"authenticationToken"];
    [coder encodeObject:self.expiry forKey:@"expiry"];
    [coder encodeObject:self.permissions forKey:@"permissions"];
}

#pragma mark Initialization

- (id) initWithToken: (NSString*) token secondsToExpiry: (NSTimeInterval) seconds permissions: (NSString*) perms
{
    if ((self = [super init]))
    {
        self.authenticationToken = token;
        if (seconds != 0)
		{
            self.expiry = [NSDate dateWithTimeIntervalSinceNow: seconds];
		}
        self.permissions = perms;
    }

    return self;
}

- (id) initWithCode: (NSString*) code redirectUrl: (NSString*) redirectUrl permissions: (NSString*) perms
{
    if ((self = [super init]))
    {
        self.code = code;
        self.redirectUrl = redirectUrl;
        self.permissions = perms;
    }
    
    return self;
}

@end
