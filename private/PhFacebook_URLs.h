//
//  PhFacebook_URLs.h
//  PhFacebook
//
//  URLs used by the Facebook Graph API
//
//  Created by Philippe on 10-08-28.
//  Copyright 2010 Philippe Casgrain. All rights reserved.
//

#define GRAPH_API_VERSION "v2.6"

#define kFBAuthorizeURL @"https://www.facebook.com/dialog/oauth?client_id=%@&redirect_uri=%@&type=user_agent&display=popup"

#define kFBAuthorizeWithScopeURL @"https://www.facebook.com/dialog/oauth?client_id=%@&redirect_uri=%@&scope=%@&type=user_agent&display=popup"

#define kFBLoginSuccessURL @"https://www.facebook.com/connect/login_success.html"

#define kFBAccessToken @"access_token="
#define kFBExpiresIn   @"expires_in="
#define kFBErrorReason @"error_description="

#define kFBGraphURL @"https://graph.facebook.com/" GRAPH_API_VERSION "/%@"

#define kFBURL @"http://facebook.com"
#define kFBSecureURL @"https://facebook.com"
