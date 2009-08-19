//
//  SpookImagePickerViewController.m
//  Spook
//
//  Created by Arshad Tayyeb on 8/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

//  ORIGINALLY: http://www.codza.com/custom-uiimagepickercontroller-camera-view
//  CustomImagePicker.m
//  meanPhoto
//
//  Created by lajos kamocsay on 1/10/09.
//  Copyright 2009 soymint.com. All rights reserved.
//

#import "ChromelessImagePickerViewController.h"


@implementation ChromelessImagePickerViewController

@synthesize pTimer;

-(void)setPreviewTimer:(NSTimer *)timer {
	if (pTimer != timer) {
		[pTimer invalidate];
		[pTimer release];
		pTimer = [timer retain];
	}
}

-(void) dealloc {
	[pTimer release];
	[super dealloc];
}

//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//	return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
//}

#define kPreviewTimerInterval 0.2	// once every five seconds

// in the default camera interface the preview is presented at a slightly different 
// scale than the camera view- this method applies a transformation to the view containg
// the preview image to match the size to the camera view
//
// NOTE: tested only for portrait images
//
-(void)previewCheck {
	// for debug: print view hierarchy
//	[self inspectView:self.view depth:0 path:@""];
	
#if !TARGET_IPHONE_SIMULATOR
	UIView *cameraChrome = [[[[[[[[[[[[self.view subviews] objectAtIndex:0]
												subviews] objectAtIndex: 0]
												subviews] objectAtIndex: 0]
												subviews] objectAtIndex: 0]
												subviews] objectAtIndex: 2]
												subviews] objectAtIndex: 0]
																			;
		[cameraChrome setHidden:YES];	

	// /0/0/0/0/1
	UIView *focusIndicator = [[[[[[[[[[self.view subviews] objectAtIndex:0]
												subviews] objectAtIndex: 0]
												subviews] objectAtIndex: 0]
												subviews] objectAtIndex: 0]
												subviews] objectAtIndex: 1]
																			;
	[focusIndicator setAlpha:0.0];	

#endif
	
}

-(NSString *)stringPad:(int)numPad {
	NSMutableString *pad = [NSMutableString stringWithCapacity:1024];
	for (int i=0; i<numPad; i++) {
		[pad appendString:@"  "];
	}
	return pad; 
}

- (void)viewDidDisappear:(BOOL)animated {
	// stop the preview timer
	//
	self.pTimer = nil;
	
	// make sure to call the same method on the super class!!!
	//
	[super viewDidDisappear:animated];
}

-(void) viewDidAppear: (BOOL)animated {
	// make sure to call the same method on the super class!!!
	//
	[super viewDidAppear:animated];
	
	// this timer will fire previewCheck
	//
	self.pTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/kPreviewTimerInterval 
														 target:self selector:@selector(previewCheck) userInfo:nil repeats:YES];	
}


@end
