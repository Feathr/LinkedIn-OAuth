//
//  RDLinkedInAuthorizationView.m
//  LinkedInClientLibrary
//
//  Created by Tommy Goode on 02/06/13.
//  Copyright 2013 Feathr. All rights reserved.
//

#import <OAuthConsumer/OAuthConsumer.h>

#import "RDLinkedInAuthorizationView.h"
#import "RDLinkedInEngine.h"
#import "RDLogging.h"


@interface RDLinkedInAuthorizationView ()

- (void)displayAuthorization;

@end


@implementation RDLinkedInAuthorizationView

@synthesize delegate = rdDelegate, engine = rdEngine, navigationBar = rdNavBar;

+ (id)authorizationViewWithEngine:(RDLinkedInEngine *)engine delegate:(id<RDLinkedInAuthorizationViewDelegate>)delegate {
  if( engine.isAuthorized ) return nil;
  return [[self alloc] initWithEngine:engine delegate:delegate];
}

- (id)initWithEngine:(RDLinkedInEngine *)engine delegate:(id<RDLinkedInAuthorizationViewDelegate>)delegate {
  self = [super initWithFrame:UIScreen.mainScreen.applicationFrame];
  if( self != nil ) {
    RDLOG(@"init with engine %@", engine);
    rdDelegate = delegate;
    rdEngine = engine;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRequestToken:) name:RDLinkedInEngineRequestTokenNotification object:rdEngine];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAccessToken:) name:RDLinkedInEngineAccessTokenNotification object:rdEngine];

    [rdEngine requestRequestToken];

	[self setupWebview];
  }
  return self;
}

- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<RDLinkedInAuthorizationViewDelegate>)delegate {
  return [self initWithEngine:[RDLinkedInEngine engineWithConsumerKey:consumerKey consumerSecret:consumerSecret delegate:nil] delegate:delegate];
}

- (void)dealloc {	
  rdDelegate = nil;
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  rdWebView.delegate = nil;
  [rdWebView stopLoading];

}


- (void)setupWebview {
  self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  rdNavBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
  [rdNavBar setItems:[NSArray arrayWithObject:[[UINavigationItem alloc] initWithTitle:@"LinkedIn Authorization"]]];
  rdNavBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
  [rdNavBar sizeToFit];
  rdNavBar.frame = CGRectMake(0, 0, self.bounds.size.width, rdNavBar.frame.size.height);
  rdNavBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
  [self addSubview:rdNavBar];

  rdWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, rdNavBar.frame.size.height, self.bounds.size.width, self.bounds.size.height - rdNavBar.frame.size.height)];
  rdWebView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  rdWebView.delegate = self;
  rdWebView.scalesPageToFit = NO;
  rdWebView.dataDetectorTypes = UIDataDetectorTypeNone;
  [self addSubview:rdWebView];

  [self displayAuthorization];
}

- (void)show {
  UIWindow* window = [UIApplication sharedApplication].keyWindow;
  if (!window) {
    window = [[UIApplication sharedApplication].windows objectAtIndex:0];
  }

  self.frame = CGRectMake(0, -(self.frame.size.height+20), self.frame.size.width, self.frame.size.height);
  [UIView animateWithDuration:0.5 animations:^{
    self.frame = UIScreen.mainScreen.applicationFrame;
    [window addSubview:self];
  }];
}

- (void)hide {
  [UIView animateWithDuration:0.5 animations:^{
    self.frame = CGRectMake(0, -(self.frame.size.height+20), self.frame.size.width, self.frame.size.height);
  } completion:^(BOOL finished) {
    [self removeFromSuperview];
  }];
}

#pragma mark private

- (void)cancel {
  if( [rdDelegate respondsToSelector:@selector(linkedInAuthorizationViewCanceled:)] ) {
    [rdDelegate linkedInAuthorizationViewCanceled:self];
  }
  [self hide];
}

- (void)denied {
  if( [rdDelegate respondsToSelector:@selector(linkedInAuthorizationViewFailed:)] ) {
    [rdDelegate linkedInAuthorizationViewFailed:self];
  }
  [self hide];
}

- (void)success {
  if( [rdDelegate respondsToSelector:@selector(linkedInAuthorizationViewSucceeded:)] ) {
    [rdDelegate linkedInAuthorizationViewSucceeded:self];
  }
  [self hide];
}

- (void)displayAuthorization {
  if( rdEngine.hasRequestToken ) {
    [rdWebView loadRequest:[rdEngine authorizationFormURLRequest]];
  }
}

- (void)didReceiveRequestToken:(NSNotification *)notification {
  [self displayAuthorization];
}

- (void)didReceiveAccessToken:(NSNotification *)notification {
  [self success];
}

- (BOOL)extractInfoFromHTTPRequest:(NSURLRequest *)request {
  if( !request ) return NO;

  NSArray* tuples = [[request.URL query] componentsSeparatedByString: @"&"];
  for( NSString *tuple in tuples ) {
    NSArray *keyValueArray = [tuple componentsSeparatedByString: @"="];

    if( keyValueArray.count == 2 ) {
      NSString* key   = [keyValueArray objectAtIndex: 0];
      NSString* value = [keyValueArray objectAtIndex: 1];

      if( [key isEqualToString:@"oauth_verifier"] ) {
        rdEngine.verifier = value;
        return YES;
      }
    }
  }

  return NO;
}


#pragma mark UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  RDLOG(@"Failed to load page %@", error);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  NSString* host = [[request.URL host] lowercaseString];
  if( [@"linkedin_oauth" isEqualToString:host] ) {
    if( [[request.URL path] isEqualToString:@"/success"] ) {
      // cancel button will redirect to callback URL with an argument, so check that first
      if( [[[[request.URL query] lowercaseString] componentsSeparatedByString:@"&"] containsObject:@"oauth_problem=user_refused"] ) {
        [self cancel];
      }
      else if( [self extractInfoFromHTTPRequest:request] ) {
        [rdEngine requestAccessToken];
      }
      else {
        NSAssert1(NO, @"Trying to load callback page, but insufficient information: %@", request);
      }
    }
    else if( [[request.URL path] isEqualToString:@"/deny"] ) {
      // leaving this path in for backwards-compatibility
      [self denied];
    }
    else {
      NSAssert1(NO, @"Unknown callback URL variant: %@", request);
    }
    return NO;
  }
  else if( [@"www.linkedin.com" isEqualToString:host] ) {
    if( ![[request.URL path] hasPrefix:@"/uas/"] ) {
      [[UIApplication sharedApplication] openURL:request.URL];
    }
  }
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  RDLOG(@"web view started loading");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  RDLOG(@"web view finished loading");
}

@end
