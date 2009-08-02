//
//  ARKViewController.m
//  ARKitDemo
//
//  Created by Zac White on 8/1/09.
//  Copyright 2009 Gravity Mobile. All rights reserved.
//

#import "ARViewController.h"

#import "ChromelessImagePickerViewController.h"

#define VIEWPORT_WIDTH_RADIANS .7392
#define VIEWPORT_HEIGHT_RADIANS .5

@implementation ARViewController

@synthesize locationManager, accelerometerManager;
@synthesize centerCoordinate, locationItems, locationViews;

@synthesize delegate;

@synthesize picker;

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	UIView *contentView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	
	self.picker = [[[ChromelessImagePickerViewController alloc] init] autorelease];
	self.picker.allowsImageEditing = NO;
	
	// make sure camera is avaialble before setting it as source
	//
	if ([ChromelessImagePickerViewController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
#if !TARGET_IPHONE_SIMULATOR
		self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;	
#endif
	}
	
	[contentView addSubview:self.picker.view];
		
	contentView.backgroundColor = [UIColor clearColor];
	
	locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 270.0, 480.0, 30.0)];
	locationLabel.textAlignment = UITextAlignmentCenter;
	locationLabel.text = @"Waiting...";
	
	[contentView addSubview:locationLabel];
	
	self.view = contentView;
	[contentView release];
}

- (void)viewDidLoad {
	self.picker.view.frame = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
	
	NSLog(@"frame: %@", NSStringFromCGRect(self.picker.view.frame));
	
	self.picker.view.transform = CGAffineTransformMakeRotation(- M_PI / 2.0);
}

- (BOOL)viewportContainsCoordinate:(ARCoordinate *)coordinate {
	double centerAzimuth = self.centerCoordinate.azimuth;
	double leftAzimuth = centerAzimuth - VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (leftAzimuth < 0.0) {
		leftAzimuth = 2 * M_PI + leftAzimuth;
	}
	
	double rightAzimuth = centerAzimuth + VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (rightAzimuth > 2 * M_PI) {
		rightAzimuth = rightAzimuth - 2 * M_PI;
	}
	
	BOOL result = (coordinate.azimuth > leftAzimuth && coordinate.azimuth < rightAzimuth);
	
	if(leftAzimuth > rightAzimuth) {
		result = (coordinate.azimuth < rightAzimuth || coordinate.azimuth > leftAzimuth);
	}
	
	double centerInclination = self.centerCoordinate.inclination;
	double bottomInclination = centerInclination - VIEWPORT_HEIGHT_RADIANS / 2.0;
	double topInclination = centerInclination + VIEWPORT_HEIGHT_RADIANS / 2.0;
	
	//check the height.
	result = result && (coordinate.inclination > bottomInclination && coordinate.inclination < topInclination);
	
	return result;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

- (void)startListening {
	
	//start our heading readings and our accelerometer readings.
	
	if (!self.locationManager) {
		self.locationManager = [[[CLLocationManager alloc] init] autorelease];
		
		//we want every move.
		self.locationManager.headingFilter = kCLHeadingFilterNone;
		
		[self.locationManager startUpdatingHeading];
		self.locationManager.delegate = self;
	}
	
	if (!self.accelerometerManager) {
		self.accelerometerManager = [UIAccelerometer sharedAccelerometer];
		self.accelerometerManager.updateInterval = 0.01;
		self.accelerometerManager.delegate = self;
	}
	
	if (!self.centerCoordinate) {
		self.centerCoordinate = [ARCoordinate coordinateWithRadialDistance:0 inclination:0 azimuth:0];
	}
}

- (CGPoint)pointInView:(UIView *)realityView forCoordinate:(ARCoordinate *)coordinate {
	
	CGPoint point;
	
	//x coordinate.
	
	double pointAzimuth = coordinate.azimuth;
	
	//our x numbers are left based.
	double leftAzimuth = self.centerCoordinate.azimuth - VIEWPORT_WIDTH_RADIANS / 2.0;
	
	if (leftAzimuth < 0.0) {
		leftAzimuth = 2 * M_PI + leftAzimuth;
	}
	
	if (pointAzimuth < leftAzimuth) {
		//it's past the 0 point.
		point.x = ((2 * M_PI - leftAzimuth + pointAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.height;
	} else {
		
		point.x = ((pointAzimuth - leftAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.height;
		
		if ([coordinate.title isEqualToString:@"Portland"]) {
			NSLog(@"point.x: %f, pointAzimuth: %f, leftAzimuth: %f", point.x, pointAzimuth, leftAzimuth);
		}
	}
	
	//y coordinate.
	
	double pointInclination = coordinate.inclination;
	
	double topInclination = self.centerCoordinate.inclination - VIEWPORT_HEIGHT_RADIANS / 2.0;
	
	point.y = realityView.frame.size.width - ((pointInclination - topInclination) / VIEWPORT_HEIGHT_RADIANS) * realityView.frame.size.width;
	
	return point;
}

#define kFilteringFactor 0.05
UIAccelerationValue rollingX, rollingZ;

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	// -1 face down.
	// 1 face up.
	
	//update the center coordinate.
	
	rollingX = (acceleration.x * kFilteringFactor) + (rollingX * (1.0 - kFilteringFactor));
    rollingZ = (acceleration.z * kFilteringFactor) + (rollingZ * (1.0 - kFilteringFactor));
			
	if (rollingX > 0.0) {
		self.centerCoordinate.inclination =  - atan(rollingZ / rollingX) - M_PI;
	} else if (rollingX < 0.0) {
		self.centerCoordinate.inclination = - atan(rollingZ / rollingX);// + M_PI;
	} else if (rollingZ < 0) {
		self.centerCoordinate.inclination = M_PI/2.0;
	} else if (rollingZ >= 0) {
		self.centerCoordinate.inclination = 3 * M_PI/2.0;
	}
	
	[self updateLocations];
}

NSComparisonResult LocationSortClosestFirst(ARCoordinate *s1, ARCoordinate *s2, void *ignore) {
    if (s1.radialDistance < s2.radialDistance) {
		return NSOrderedAscending;
	} else if (s1.radialDistance > s2.radialDistance) {
		return NSOrderedDescending;
	} else {
		return NSOrderedSame;
	}
}

- (void)setLocationItems:(NSArray *)newItems {
	[locationItems release];
	locationItems = [newItems retain];
	
	NSMutableArray *sortedArray = [NSMutableArray arrayWithArray:newItems];
	[sortedArray sortUsingFunction:LocationSortClosestFirst context:NULL];
	locationItems = [sortedArray copy];
	
	NSMutableArray *tempArray = [NSMutableArray array];
	
	for (ARCoordinate *coordinate in locationItems) {
		//create the views here.
		
		//call out for the delegate's view.
		if ([self.delegate respondsToSelector:@selector(viewForCoordinate:)]) {
			[tempArray addObject:[self.delegate viewForCoordinate:coordinate]];
		}
	}
	
	self.locationViews = tempArray;
}

- (void)updateLocations {
	//update locations!
	
	if (!self.locationViews || self.locationViews.count == 0) {
		return;
	}
	
	locationLabel.text = [self.centerCoordinate description];
	
	int index = 0;
	for (ARCoordinate *item in self.locationItems) {
		
		UIView *viewToDraw = [self.locationViews objectAtIndex:index];
		
		if ([self viewportContainsCoordinate:item]) {
			CGPoint loc = [self pointInView:self.view forCoordinate:item];
			
			float width = viewToDraw.frame.size.width;
			float height = viewToDraw.frame.size.height;
			
			viewToDraw.frame = CGRectMake(loc.x - width / 2.0, loc.y - width / 2.0, width, height);
			
			[self.view addSubview:viewToDraw];
			
		} else {
			[viewToDraw removeFromSuperview];
		}
		index++;
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {	
	self.centerCoordinate.azimuth = fmod(newHeading.trueHeading + 90.0, 360.0) * (2 * (M_PI / 360.0));
	[self updateLocations];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	return YES;
}

- (void)viewDidAppear:(BOOL)animated {
	[self.picker viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.picker viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	self.picker = nil;
	
    [super dealloc];
}


@end
