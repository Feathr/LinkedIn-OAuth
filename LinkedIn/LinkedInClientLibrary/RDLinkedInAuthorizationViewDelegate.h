//
//  RDLinkedInAuthorizationView.h
//  LinkedInClientLibrary
//
//  Created by Tommy Goode on 02/06/13.
//  Copyright 2013 Feathr. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RDLinkedInAuthorizationView;


@protocol RDLinkedInAuthorizationViewDelegate <NSObject>

@optional

- (void)linkedInAuthorizationViewSucceeded:(RDLinkedInAuthorizationView *)view;

- (void)linkedInAuthorizationViewFailed:(RDLinkedInAuthorizationView *)view;

- (void)linkedInAuthorizationViewCanceled:(RDLinkedInAuthorizationView *)view;

@end
