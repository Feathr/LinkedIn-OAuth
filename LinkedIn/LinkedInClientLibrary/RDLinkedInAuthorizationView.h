//
//  RDLinkedInAuthorizationView.h
//  LinkedInClientLibrary
//
//  Created by Tommy Goode on 02/06/13.
//  Copyright 2013 Feathr. All rights reserved.
//  
//  Based in large part on RDLinkedInAuthorizationController.h by Sixten Otto.
//	Includes ideas from the iOS FacebookSDK.
//

#import <UIKit/UIKit.h>

#import "RDLinkedInAuthorizationViewDelegate.h"

@class RDLinkedInEngine;


@interface RDLinkedInAuthorizationView : UIView <UIWebViewDelegate> {
  id<RDLinkedInAuthorizationViewDelegate> rdDelegate;
  RDLinkedInEngine* rdEngine;
  UINavigationBar*  rdNavBar;
  UIWebView*        rdWebView;
}

@property (nonatomic, assign)   id<RDLinkedInAuthorizationViewDelegate> delegate;
@property (nonatomic, readonly) RDLinkedInEngine* engine;
@property (nonatomic, readonly) UINavigationBar* navigationBar;

+ (id)authorizationViewWithEngine:(RDLinkedInEngine *)engine delegate:(id<RDLinkedInAuthorizationViewDelegate>)delegate;

- (id)initWithEngine:(RDLinkedInEngine *)engine delegate:(id<RDLinkedInAuthorizationViewDelegate>)delegate;
- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<RDLinkedInAuthorizationViewDelegate>)delegate;

- (void)show;

@end
