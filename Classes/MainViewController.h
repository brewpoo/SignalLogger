//
//  MainViewController.h
//  SignalLogger
//
//  Created by Jon Lochner on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import "SLlocationController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <CoreTelephony/CTCall.h>

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, MFMailComposeViewControllerDelegate> {
	IBOutlet UIActivityIndicatorView *aSpinner;
	IBOutlet UISwitch *aSwitch;
	IBOutlet UITextField *aSignal;
	IBOutlet UITextField *aLatitutde;
	IBOutlet UITextField *aLongitutde;
	IBOutlet UITextField *aCount;
	SLlocationController *locationController;
	CLLocation *currentLocation;
	NSNumber *currentSignal;
	NSObject *voice;
	int oldStrength;
	int runCount;
	NSTimer	*aTimer;
	NSMutableData *aData;
}

- (IBAction)showInfo:(id)sender;
- (IBAction)switchChanged:(id)sender;
- (void)emailData;

@end
