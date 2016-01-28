//
//  MainViewController.m
//  SignalLogger
//
//  Created by Jon Lochner on 3/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "CoreTelephony.h"
#include <dlfcn.h>

@implementation MainViewController


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	locationController = [[SLlocationController alloc] init];
	
	aData = [[NSMutableData alloc] init];
	runCount = 0;
}


- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo:(id)sender {    
	return;
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


- (IBAction)switchChanged:(id)sender {
	// Check switch state
	if (aSwitch.on) {
		NSLog(@"Switched On");
		[locationController.locationManager startUpdatingLocation];
		aTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(timerTriggered:) userInfo:nil repeats:YES];
		[aSpinner setHidden:false];
		[aSpinner startAnimating];
	} else {
		NSLog(@"Switched Off");
		[locationController.locationManager stopUpdatingLocation];
		[aTimer invalidate];
		[aSpinner setHidden:true];
		[aSpinner stopAnimating];
		[self emailData];
	}
}

- (void)timerTriggered:(id)sender {
	NSLog(@"Timer triggered");
	runCount += 1;
	currentLocation = locationController.locationManager.location;
	currentSignal = getSignalStrength();
	
	NSString *string = [NSString stringWithFormat:@"%@, %3.8f, %3.8f ,%d\n", [currentLocation.timestamp description], currentLocation.coordinate.latitude,
						currentLocation.coordinate.longitude, currentSignal];
	aCount.text = [NSString stringWithFormat:@"%d", runCount];
	aSignal.text = [NSString stringWithFormat:@"%d", currentSignal];
	aLatitutde.text = [NSString stringWithFormat:@"%3.8f", currentLocation.coordinate.latitude];
	aLongitutde.text = [NSString stringWithFormat:@"%3.8f", currentLocation.coordinate.longitude];
	NSLog(@"%@", string);
	[aData appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)emailData {
	MFMailComposeViewController *aMail = [[MFMailComposeViewController alloc] init];
    aMail.mailComposeDelegate = self;
    
    [aMail setSubject:@"Data from Signal Logger"];
    [aMail addAttachmentData:aData mimeType:@"file/csv" fileName:@"signal-logger.csv"];
    // Fill out the email body text
    NSString *emailBody = @"Data is attached";
    [aMail setMessageBody:emailBody isHTML:NO];
    
    [self presentModalViewController:aMail animated:YES];
	[aMail release];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
	[aData setLength:0];
	runCount = 0;
	aCount.text = [NSString stringWithFormat:@""];
	aSignal.text = [NSString stringWithFormat:@""];
	aLatitutde.text = [NSString stringWithFormat:@""];
	aLongitutde.text = [NSString stringWithFormat:@""];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[aData release];
	[locationController release];
	[aTimer release];
	[aSwitch release];
	[aSpinner release];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)dealloc {
    [super dealloc];
}

@end

CFMachPortRef mach_port;
CTServerConnectionRef conn;
CFRunLoopSourceRef source;	

void ConnectionCallback(CTServerConnectionRef connection, CFStringRef string, CFDictionaryRef dictionary, void *data) {
	NSLog(@"ConnectionCallback");
	CFShow(dictionary);
}

void NotifCallback() {
	NSLog(@"NotifCallback");
}

void Dump(void* x, int size) {
	char* c = (char*)x;
	int i;
	for (i = 0; i < size; i++) {
		printf(" %x ", c[i]);
	}
	NSLog(@"Dumped");
}

void start_monitor() {
	conn = _CTServerConnectionCreate(kCFAllocatorDefault, ConnectionCallback,NULL);
	NSLog(@"connection=%d",conn);	
	//Dump(conn, sizeof(struct __CTServerConnection));	
	mach_port_t port  = _CTServerConnectionGetPort(conn);
	NSLog(@"port=%d",port);		
	mach_port = CFMachPortCreateWithPort(kCFAllocatorDefault,port,NULL,NULL, NULL);	
	NSLog(@"mach_port=%x",CFMachPortGetPort(mach_port));	
	source = CFMachPortCreateRunLoopSource ( kCFAllocatorDefault, mach_port, 0);
	CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], source, kCFRunLoopCommonModes);
	_CTServerConnectionCellMonitorStart(mach_port,conn);	
	
}

void register_notification() {
	if (!mach_port || !conn) return;	
	void *libHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LOCAL | RTLD_LAZY);
	void *kCTCellMonitorUpdateNotification = dlsym(libHandle, "kCTIndicatorsSignalStrengthNotification");
	if( kCTCellMonitorUpdateNotification== NULL) NSLog(@"Could not find kCTCellMonitorUpdateNotification");	
	int x = 0; //placehoder for callback
	_CTServerConnectionRegisterForNotification(conn,kCTCellMonitorUpdateNotification,&x); 	
}

void printInfo() {
	if (!mach_port || !conn) return;
	
	int count = 0;
	_CTServerConnectionCellMonitorGetCellCount(mach_port, conn, &count);
	
	if (count > 0) {
		int i;
		for (i = 0; i < count; i++) {
			CellInfoRef cellinfo;
			_CTServerConnectionCellMonitorGetCellInfo(mach_port, conn, i, &cellinfo);
			NSLog(@"Cell site: %d, MNC: %d ", i, cellinfo->servingmnc);
			NSLog(@"Location: %d, Cell ID: %d, Station: %d, ", cellinfo->location,cellinfo->cellid, cellinfo->station);
			NSLog(@"Freq: %d, RxLevel: %d, ", cellinfo->freq, cellinfo->rxlevel);
			NSLog(@"C1: %d, C2: %d", cellinfo->c1, cellinfo->c2);
		}		
	}else {
		NSLog(@"No Cell info");		
	}
}


int getSignalStrength() {
    
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *subviews = [[[app valueForKey:@"statusBar"]     valueForKey:@"foregroundView"] subviews];
    NSString *dataNetworkItemView = nil;
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarSignalStrengthItemView") class]])
        {
            dataNetworkItemView = subview;
            break;
        }
    }
    if (dataNetworkItemView){
        int signalStrength = [[dataNetworkItemView valueForKey:@"signalStrengthRaw"] intValue];
        NSLog(@"signal %d", signalStrength);
        return signalStrength;
    }
    return 0;
    
    /*
	void *libHandle = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
	int (*CTGetSignalStrength)();
	CTGetSignalStrength = dlsym(libHandle, "CTGetSignalStrength");
	if( CTGetSignalStrength == NULL) NSLog(@"Could not find CTGetSignalStrength");	
	int result = CTGetSignalStrength();
	dlclose(libHandle);	
	return result;
     */
}

