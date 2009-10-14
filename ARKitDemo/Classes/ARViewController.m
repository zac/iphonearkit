//
//  ARKViewController.m
//  ARKitDemo
//
//  Created by Zac White on 8/1/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import "ARViewController.h"

#import <QuartzCore/QuartzCore.h>

#define VIEWPORT_WIDTH_RADIANS .5
#define VIEWPORT_HEIGHT_RADIANS .7392

@implementation ARViewController

@synthesize locationManager, accelerometerManager;
@synthesize centerCoordinate;

@synthesize scaleViewsBasedOnDistance, rotateViewsBasedOnPerspective;
@synthesize maximumScaleDistance;
@synthesize minimumScaleFactor, maximumRotationAngle;

@synthesize updateFrequency;

@synthesize debugMode = ar_debugMode;

@synthesize coordinates = ar_coordinates;

@synthesize delegate, locationDelegate, accelerometerDelegate;

@synthesize cameraController;

- (id)init {
	if (!(self = [super init])) return nil;
	
	ar_debugView = nil;
	ar_overlayView = nil;
	
	ar_debugMode = NO;
	
	ar_coordinates = [[NSMutableArray alloc] init];
	ar_coordinateViews = [[NSMutableArray alloc] init];
	
	_updateTimer = nil;
	self.updateFrequency = 1 / 20.0;
	
#if !TARGET_IPHONE_SIMULATOR
	
	self.cameraController = [[[UIImagePickerController alloc] init] autorelease];
	self.cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;
	
	self.cameraController.cameraViewTransform = CGAffineTransformScale(self.cameraController.cameraViewTransform,
																	   1.13f,
																	   1.13f);
	
	self.cameraController.showsCameraControls = NO;
	self.cameraController.navigationBarHidden = YES;
#endif
	self.scaleViewsBasedOnDistance = NO;
	self.maximumScaleDistance = 0.0;
	self.minimumScaleFactor = 1.0;
	
	self.rotateViewsBasedOnPerspective = NO;
	self.maximumRotationAngle = M_PI / 6.0;
	
	self.wantsFullScreenLayout = YES;
	
	return self;
}

- (id)initWithLocationManager:(CLLocationManager *)manager {
	
	if (!(self = [super init])) return nil;
	
	//use the passed in location manager instead of ours.
	self.locationManager = manager;
	self.locationManager.delegate = self;
	
	self.locationDelegate = nil;
	
	return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	[ar_overlayView release];
	ar_overlayView = [[UIView alloc] initWithFrame:CGRectZero];
	
	[ar_debugView release];
	
	if (self.debugMode) {
		ar_debugView = [[UILabel alloc] initWithFrame:CGRectZero];
		ar_debugView.textAlignment = UITextAlignmentCenter;
		ar_debugView.text = @"Waiting...";
		
		[ar_overlayView addSubview:ar_debugView];
	}
		
	self.view = ar_overlayView;
}

- (void)setUpdateFrequency:(double)newUpdateFrequency {
	
	updateFrequency = newUpdateFrequency;
	
	if (!_updateTimer) return;
	
	[_updateTimer invalidate];
	[_updateTimer release];
	
	_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:self.updateFrequency
													 target:self
												   selector:@selector(updateLocations:)
												   userInfo:nil
													repeats:YES] retain];
}

- (void)setDebugMode:(BOOL)flag {
	if (self.debugMode == flag) return;
	
	ar_debugMode = flag;
	
	//we don't need to update the view.
	if (![self isViewLoaded]) return;
	
	if (self.debugMode) [ar_overlayView addSubview:ar_debugView];
	else [ar_debugView removeFromSuperview];
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
	
	//NSLog(@"coordinate: %@ result: %@", coordinate, result?@"YES":@"NO");
	
	return result;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)startListening {
	
	//start our heading readings and our accelerometer readings.
	
	if (!self.locationManager) {
		self.locationManager = [[[CLLocationManager alloc] init] autorelease];
		
		//we want every move.
		self.locationManager.headingFilter = kCLHeadingFilterNone;
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		
		[self.locationManager startUpdatingHeading];
	}
	
	//steal back the delegate.
	self.locationManager.delegate = self;
	
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
		point.x = ((2 * M_PI - leftAzimuth + pointAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.width;
	} else {
		point.x = ((pointAzimuth - leftAzimuth) / VIEWPORT_WIDTH_RADIANS) * realityView.frame.size.width;
	}
	
	//y coordinate.
	
	double pointInclination = coordinate.inclination;
	
	double topInclination = self.centerCoordinate.inclination - VIEWPORT_HEIGHT_RADIANS / 2.0;
	
	point.y = realityView.frame.size.height - ((pointInclination - topInclination) / VIEWPORT_HEIGHT_RADIANS) * realityView.frame.size.height;
	
	return point;
}

#define kFilteringFactor 0.05
UIAccelerationValue rollingX, rollingZ;

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	// -1 face down.
	// 1 face up.
	
	//update the center coordinate.
	
	//NSLog(@"x: %f y: %f z: %f", acceleration.x, acceleration.y, acceleration.z);
	
	//this should be different based on orientation.
	
	rollingZ  = (acceleration.z * kFilteringFactor) + (rollingZ  * (1.0 - kFilteringFactor));
    rollingX = (acceleration.y * kFilteringFactor) + (rollingX * (1.0 - kFilteringFactor));
	
	if (rollingZ > 0.0) {
		self.centerCoordinate.inclination = atan(rollingX / rollingZ) + M_PI / 2.0;
	} else if (rollingZ < 0.0) {
		self.centerCoordinate.inclination = atan(rollingX / rollingZ) - M_PI / 2.0;// + M_PI;
	} else if (rollingX < 0) {
		self.centerCoordinate.inclination = M_PI/2.0;
	} else if (rollingX >= 0) {
		self.centerCoordinate.inclination = 3 * M_PI/2.0;
	}
	
	if (self.accelerometerDelegate && [self.accelerometerDelegate respondsToSelector:@selector(accelerometer:didAccelerate:)]) {
		//forward the acceleromter.
		[self.accelerometerDelegate accelerometer:accelerometer didAccelerate:acceleration];
	}
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
		
	if (coordinate.radialDistance > self.maximumScaleDistance) {
		self.maximumScaleDistance = coordinate.radialDistance;
	}
	
	//message the delegate.
	[ar_coordinateViews addObject:[self.delegate viewForCoordinate:coordinate]];
}

- (void)addCoordinates:(NSArray *)newCoordinates {
	
	//go through and add each coordinate.
	for (ARCoordinate *coordinate in newCoordinates) {
		[self addCoordinate:coordinate animated:NO];
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

- (void)updateLocations:(NSTimer *)timer {
	//update locations!
	
	if (!ar_coordinateViews || ar_coordinateViews.count == 0) {
		return;
	}
	
	ar_debugView.text = [self.centerCoordinate description];
	
	int index = 0;
	for (ARCoordinate *item in ar_coordinates) {
		
		UIView *viewToDraw = [ar_coordinateViews objectAtIndex:index];
		
		if ([self viewportContainsCoordinate:item]) {
			
			CGPoint loc = [self pointInView:ar_overlayView forCoordinate:item];
			
			CGFloat scaleFactor = 1.0;
			if (self.scaleViewsBasedOnDistance) {
				scaleFactor = 1.0 - self.minimumScaleFactor * (item.radialDistance / self.maximumScaleDistance);
			}
			
			float width = viewToDraw.bounds.size.width * scaleFactor;
			float height = viewToDraw.bounds.size.height * scaleFactor;
			
			viewToDraw.frame = CGRectMake(loc.x - width / 2.0, loc.y - height / 2.0, width, height);
						
			CATransform3D transform = CATransform3DIdentity;
			
			//set the scale if it needs it.
			if (self.scaleViewsBasedOnDistance) {
				//scale the perspective transform if we have one.
				transform = CATransform3DScale(transform, scaleFactor, scaleFactor, scaleFactor);
			}
			
			if (self.rotateViewsBasedOnPerspective) {
				transform.m34 = 1.0 / 300.0;
				
				double itemAzimuth = item.azimuth;
				double centerAzimuth = self.centerCoordinate.azimuth;
				if (itemAzimuth - centerAzimuth > M_PI) centerAzimuth += 2*M_PI;
				if (itemAzimuth - centerAzimuth < -M_PI) itemAzimuth += 2*M_PI;
				
				double angleDifference = itemAzimuth - centerAzimuth;
				transform = CATransform3DRotate(transform, self.maximumRotationAngle * angleDifference / (VIEWPORT_HEIGHT_RADIANS / 2.0) , 0, 1, 0);
			}
			
			viewToDraw.layer.transform = transform;
			
			//if we don't have a superview, set it up.
			if (!(viewToDraw.superview)) {
				[ar_overlayView addSubview:viewToDraw];
				[ar_overlayView sendSubviewToBack:viewToDraw];
			}
			
		} else {
			[viewToDraw removeFromSuperview];
			viewToDraw.transform = CGAffineTransformIdentity;
		}
		index++;
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
		
	self.centerCoordinate.azimuth = fmod(newHeading.magneticHeading, 360.0) * (2 * (M_PI / 360.0));
	
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didUpdateHeading:)]) {
		//forward the call.
		[self.locationDelegate locationManager:manager didUpdateHeading:newHeading];
	}
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManagerShouldDisplayHeadingCalibration:)]) {
		//forward the call.
		return [self.locationDelegate locationManagerShouldDisplayHeadingCalibration:manager];
	}
	
	return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
		//forward the call.
		[self.locationDelegate locationManager:manager didUpdateToLocation:newLocation fromLocation:oldLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	if (self.locationDelegate && [self.locationDelegate respondsToSelector:@selector(locationManager:didFailWithError:)]) {
		//forward the call.
		return [self.locationDelegate locationManager:manager didFailWithError:error];
	}
}

- (void)viewDidAppear:(BOOL)animated {
#if !TARGET_IPHONE_SIMULATOR
	[self.cameraController setCameraOverlayView:ar_overlayView];
	[self presentModalViewController:self.cameraController animated:NO];
	
	[ar_overlayView setFrame:self.cameraController.view.bounds];
#endif
	
	if (!_updateTimer) {
		_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:self.updateFrequency
													 target:self
												   selector:@selector(updateLocations:)
												   userInfo:nil
													repeats:YES] retain];
	}
	
	[super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if (self.debugMode) {
		[ar_debugView sizeToFit];
		[ar_debugView setFrame:CGRectMake(0,
										  ar_overlayView.frame.size.height - ar_debugView.frame.size.height,
										  ar_overlayView.frame.size.width,
										  ar_debugView.frame.size.height)];
	}
	
	
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[ar_overlayView release];
	ar_overlayView = nil;
}


- (void)dealloc {
	[ar_debugView release];
	
	[ar_coordinateViews release];
	[ar_coordinates release];
	
    [super dealloc];
}

@end
