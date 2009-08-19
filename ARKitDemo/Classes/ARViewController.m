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
@synthesize centerCoordinate;

@synthesize debugMode = _debugMode;

@synthesize coordinates = ar_coordinates;

@synthesize delegate;

- (id)init {
	if (!(self = [super init])) return nil;
	
	_debugView = [[UILabel alloc] initWithFrame:CGRectMake(0, 270.0, 480.0, 30.0)];
	_debugView.textAlignment = UITextAlignmentCenter;
	_debugView.text = @"Waiting...";
	
	_debugMode = NO;
	
	ar_coordinates = [[NSMutableArray alloc] init];
	ar_coordinateViews = [[NSMutableArray alloc] init];
	
	return self;
}

- (id)initWithLocationManager:(CLLocationManager *)manager {
	
	if (!(self = [super init])) return nil;
	
	//use the passed in location manager instead of ours.
	self.locationManager = manager;
	
	return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	UIView *contentView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
			
	contentView.backgroundColor = [UIColor clearColor];
	
	if (self.debugMode) [contentView addSubview:_debugView];
	
	self.view = contentView;
	[contentView release];
}

- (void)setDebugMode:(BOOL)flag {
	if (self.debugMode == flag) return;
	
	_debugMode = flag;
	
	//we don't need to update the view.
	if (![self isViewLoaded]) return;
	
	if (self.debugMode) [self.view addSubview:_debugView];
	else [_debugView removeFromSuperview];
}

- (void)viewDidLoad {
	[super viewDidLoad];
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
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		
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

- (void)addCoordinate:(ARCoordinate *)coordinate {
	[self addCoordinate:coordinate animated:YES];
}

- (void)addCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated {
	//do some kind of animation?
	[ar_coordinates addObject:coordinate];
	if ([self.delegate respondsToSelector:@selector(viewForCoordinate:)]) {
		[ar_coordinateViews addObject:[self.delegate viewForCoordinate:coordinate]];
	}
}

- (void)addCoordinates:(NSArray *)newCoordinates {
	[ar_coordinates addObjectsFromArray:newCoordinates];
		
	for (ARCoordinate *coordinate in ar_coordinates) {		
		//call out for the delegate's view.
		//there's probably a better time to do this.
		if ([self.delegate respondsToSelector:@selector(viewForCoordinate:)]) {
			[ar_coordinateViews addObject:[self.delegate viewForCoordinate:coordinate]];
		}
	}
}

- (void)removeCoordinate:(ARCoordinate *)coordinate {
	[self removeCoordinate:coordinate animated:YES];
}

- (void)removeCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated {
	//do some kind of animation?
	[ar_coordinates removeObject:coordinate];
}

- (void)removeCoordinates:(NSArray *)coordinates {	
	for (ARCoordinate *coordinateToRemove in coordinates) {
		NSUInteger indexToRemove = [ar_coordinates indexOfObject:coordinateToRemove];
		
		//TODO: Error checking in here.
		
		[ar_coordinates removeObjectAtIndex:indexToRemove];
		[ar_coordinateViews removeObjectAtIndex:indexToRemove];
	}
}

- (void)updateLocations {
	//update locations!
		
	if (!ar_coordinateViews || ar_coordinateViews.count == 0) {
		return;
	}
	
	_debugView.text = [self.centerCoordinate description];
	
	int index = 0;
	for (ARCoordinate *item in ar_coordinates) {
		
		UIView *viewToDraw = [ar_coordinateViews objectAtIndex:index];
				
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
	
	//NSLog(@"x: %f y: %f z: %f", newHeading.x, newHeading.y, newHeading.z);
	
	self.centerCoordinate.azimuth = fmod(newHeading.magneticHeading + 90.0, 360.0) * (2 * (M_PI / 360.0));
	[self updateLocations];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	return YES;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
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
	[_debugView release];
	
	[ar_coordinateViews release];
	[ar_coordinates release];
	
    [super dealloc];
}


@end
