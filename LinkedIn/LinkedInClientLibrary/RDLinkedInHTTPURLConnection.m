//
//  RDLinkedInHTTPURLConnection.m
//  LinkedInClientLibrary
//
//  Created by Sixten Otto on 12/30/09.
//  Copyright 2010 Results Direct. All rights reserved.
//

#import "RDLinkedInHTTPURLConnection.h"


@implementation RDLinkedInHTTPURLConnection

@synthesize request = rdRequest;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate {
  self = [super initWithRequest:request delegate:delegate];
  if( self != nil ) {
    rdRequest = request;
    rdData = [[NSMutableData alloc] init];
  }
  return self;
}


- (RDLinkedInConnectionID *)identifier {
  if( !rdIdentifier ) {
    rdIdentifier = [[NSProcessInfo processInfo] globallyUniqueString];
  }
  return rdIdentifier;
}

- (NSData *)data {
  return rdData;
}

- (void)appendData:(NSData *)data {
  [rdData appendData:data];
}

- (void)resetData {
  [rdData setLength:0];
}

@end
