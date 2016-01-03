//
//  main.m
//  SignalLogger
//
//  Created by Jon Lochner on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignalLoggerAppDelegate.h"

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([SignalLoggerAppDelegate class]));
    [pool release];
    return retVal;
}
