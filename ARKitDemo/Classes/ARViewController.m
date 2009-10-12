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

@interface ARViewController (Private)

- (CGFloat)_rotationFromOrientation:(UIInterfaceOrientation)oldOrientation toOrientation:(UIInterfaceOrientation)newOrientation;
- (void)_updateCenterCoordinate;
- (double)_widthInRadiansForView:(UIView *)viewToDraw;
- (double)_heightInRadiansForView:(UIView *)viewToDraw;

@end

@implementation ARViewController

@synthesize locationManager, accelerometerManager;
@synthesize centerCoordinate;

@synthesize scaleViewsBasedOnDistance, rotateViewsBasedOnPerspective;
@synthesize maximumScaleDistance;
@synthesize minimumScaleFactor, maximumRotationAngle;

@synthesize updateFrequency;
@synthesize viewInterfaceOrientation;

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
	
	_latestHeading = -1.0f;
	_latestXAcceleration = -1.0f;
	_latestYAcceleration = -1.0f;
	_latestZAcceleration = -1.0f;
	
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
	
	//assign our locationDelegate if it already has a delegate object.
	if (self.locationManager.delegate) self.locationDelegate = self.locationManager.delegate;
	
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
		
	//ar_overlayView.backgroundColor = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:.2];
	
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

- (BOOL)viewportContainsView:(UIView *)viewToDraw forCoordinate:(ARCoordinate *)coordinate {
	double centerAzimuth = self.centerCoordinate.azimuth;
	CGRect viewBounds = viewToDraw.bounds;
	
	
	//autoadjust the width and height of our viewport based on the view's size.
	double viewWidthRadians = VIEWPORT_WIDTH_RADIANS / (self.view.bounds.size.width / viewBounds.size.width);
	double viewHeightRadians = VIEWPORT_HEIGHT_RADIANS / (self.view.bounds.size.height / viewBounds.size.height);
	
	if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || UIInterfaceOrientationLandscapeRight) {
		//swap them.
		double temp = viewWidthRadians;
		viewWidthRadians = viewHeightRadians;
		viewHeightRadians = temp;
	}
	
	double leftAzimuth = centerAzimuth - VIEWPORT_WIDTH_RADIANS / 2.0 - viewWidthRadians;
	
	if (leftAzimuth < 0.0) {
		leftAzimuth = 2 * M_PI + leftAzimuth;
	}
	
	double rightAzimuth = centerAzimuth + VIEWPORT_WIDTH_RADIANS / 2.0 + viewWidthRadians;
	
	if (rightAzimuth > 2 * M_PI) {
		rightAzimuth = rightAzimuth - 2 * M_PI;
	}
	
	BOOL result = (coordinate.azimuth > leftAzimuth && coordinate.azimuth < rightAzimuth);
	
	if(leftAzimuth > rightAzimuth) {
		result = (coordinate.azimuth < rightAzimuth || coordinate.azimuth > leftAzimuth);
	}
	
	double centerInclination = self.centerCoordinate.inclination;
	double bottomInclination = centerInclination - VIEWPORT_HEIGHT_RADIANS / 2.0 - viewHeightRadians;
	double topInclination = centerInclination + VIEWPORT_HEIGHT_RADIANS / 2.0 + viewHeightRadians;
	
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	//steal back the delegate.
	self.locationManager.delegate = self;
	
	if (!self.accelerometerManager) {
		self.accelerometerManager = [UIAccelerometer sharedAccelerometer];
		self.accelerometerManager.updateInterval = 0.01;
		self.accelerometerManager.delegate = self;
	}
	
	if (!self.centerCoordinate) {
		self.centerCoordinate = [ARCoordinate coordinateWithRadialDistance:1.0 inclination:0 azimuth:0];
	}
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
	
	//we only care about responding to these changes if the delegate cares.
	if (self.delegate && [self.delegate respondsToSelector:@selector(shouldAutorotateViewsToInterfaceOrientation:)]) {
		
		UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
		
		BOOL shouldAutorotate = [self.delegate shouldAutorotateViewsToInterfaceOrientation:orientation];
		if (!shouldAutorotate) return;
		
		//remember our old orientation.
		UIInterfaceOrientation oldOrientation = self.viewInterfaceOrientation;
		//assign our new orientation.
		viewInterfaceOrientation = orientation;
		
		//go through and rotate all the views.
		
		CGFloat rotation = [self _rotationFromOrientation:oldOrientation toOrientation:self.viewInterfaceOrientation];
		for (UIView *subview in ar_coordinateViews) {
			subview.transform = CGAffineTransformRotate(subview.transform, rotation);
		}
	}
}

- (CGPoint)pointInView:(UIView *)realityView withView:(UIView *)viewToDraw forCoordinate:(ARCoordinate *)coordinate {
	
	CGPoint point;
	
	double viewWidthRadians = [self _widthInRadiansForView:viewToDraw];
	double viewHeightRadians = [self _heightInRadiansForView:viewToDraw];
	
	double pointAzimuth = coordinate.azimuth;
	
	//our x numbers are left based.
	double leftAzimuth = self.centerCoordinate.azimuth - VIEWPORT_WIDTH_RADIANS / 2.0 - viewWidthRadians;
	
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
	
	double topInclination = self.centerCoordinate.inclination - VIEWPORT_HEIGHT_RADIANS / 2.0 - viewHeightRadians;
	
	point.y = realityView.frame.size.height - ((pointInclination - topInclination) / VIEWPORT_HEIGHT_RADIANS) * realityView.frame.size.height;
	
	return point;
}

#define kFilteringFactor 0.05

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	
	_latestZAcceleration  = (acceleration.z * kFilteringFactor) + (_latestZAcceleration  * (1.0 - kFilteringFactor));
    _latestYAcceleration = (acceleration.y * kFilteringFactor) + (_latestYAcceleration * (1.0 - kFilteringFactor));
	_latestXAcceleration = (acceleration.x * kFilteringFactor) + (_latestXAcceleration * (1.0 - kFilteringFactor));
	
	[self _updateCenterCoordinate];
	
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
	
	//ar_debugView.text = [self.centerCoordinate description];
	
	ar_debugView.text = [NSString stringWithFormat:@"%.4f %.4f %.4f", _latestXAcceleration, _latestYAcceleration, _viewportRotation];
	
	int index = 0;
	for (ARCoordinate *item in ar_coordinates) {
		
		UIView *viewToDraw = [ar_coordinateViews objectAtIndex:index];
		
		if ([self viewportContainsView:viewToDraw forCoordinate:item]) {
			
			CGPoint loc = [self pointInView:ar_overlayView withView:viewToDraw forCoordinate:item];
			
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
				
				//set the scale if it needs it.
				if (self.scalesViewsBasedOnDistance) {
					//viewToDraw.transform = CGAffineTransformScale(viewToDraw.transform, scaleFactor, scaleFactor);
					viewToDraw.layer.anchorPoint = CGPointMake(viewToDraw.bounds.size.width / 2.0, viewToDraw.bounds.size.height / 2.0);
					viewToDraw.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
				}
			}
			
		} else {
			[viewToDraw removeFromSuperview];
			//viewToDraw.transform = CGAffineTransformIdentity;
		}
		index++;
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	
	_latestHeading = fmod(newHeading.magneticHeading, 360.0) * (2 * (M_PI / 360.0));
	
	[self _updateCenterCoordinate];
	
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
	
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	
	[ar_debugView release];
	
	[ar_coordinateViews release];
	[ar_coordinates release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Private Methods

- (void)_updateCenterCoordinate {
	
	UIAccelerationValue downAcceleration = _latestXAcceleration + _latestYAcceleration;
	
	self.centerCoordinate.azimuth = (1.0 - ABS(_latestYAcceleration)) * (M_PI / 2.0) + _latestHeading;
	
	if (_latestZAcceleration > 0.0) {
		self.centerCoordinate.inclination = atan(downAcceleration / _latestZAcceleration) + M_PI / 2.0;
	} else if (_latestZAcceleration < 0.0) {
		self.centerCoordinate.inclination = atan(downAcceleration / _latestZAcceleration) - M_PI / 2.0;// + M_PI;
	} else if (downAcceleration < 0) {
		self.centerCoordinate.inclination = M_PI/2.0;
	} else if (downAcceleration >= 0) {
		self.centerCoordinate.inclination = 3 * M_PI/2.0;
	}
	
	_viewportRotation = atan(_latestXAcceleration / _latestYAcceleration);
	if (_latestXAcceleration > 0.0) _viewportRotation = ABS(_viewportRotation);
	else _viewportRotation = -ABS(_viewportRotation);
	
	
//	if (_latestYAcceleration > 0.0) {
//		if (_latestXAcceleration > 0.0) _viewportRotation = M_PI / 2.0 - _viewportRotation;
//		else _viewportRotation = M_PI / 2.0 - _viewportRotation - _viewportRotation;
//	}
	
	[self updateLocations];
}

- (CGFloat)_rotationFromOrientation:(UIInterfaceOrientation)oldOrientation toOrientation:(UIInterfaceOrientation)newOrientation {
	
	CGFloat originalOffset = 0.0f;
	
	switch (oldOrientation) {
		case UIInterfaceOrientationPortrait:
			originalOffset = 0.0f;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			originalOffset = M_PI;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			originalOffset = M_PI / 2.0;
			break;
		case UIInterfaceOrientationLandscapeRight:
			originalOffset = - M_PI / 2.0;
			break;
		default:
			break;
	}
	
	CGFloat newOffset = 0.0f;
	switch (newOrientation) {
		case UIInterfaceOrientationPortrait:
			newOffset = 0.0f;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			newOffset = M_PI;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			newOffset = M_PI / 2.0;
			break;
		case UIInterfaceOrientationLandscapeRight:
			newOffset = - M_PI / 2.0;
			break;
		default:
			break;
	}
	
	NSLog(@"ROTATING: from %f to %f", originalOffset, newOffset);
	
	return fmod(originalOffset + newOffset, 2 * M_PI);
}

- (double)_widthInRadiansForView:(UIView *)viewToDraw {
	CGRect viewBounds = viewToDraw.bounds;
	
	BOOL sideways = (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight);
	
	//autoadjust the width and height of our viewport based on the view's size.
	
	if (!sideways) {
		return VIEWPORT_WIDTH_RADIANS / (self.view.bounds.size.width / viewBounds.size.width);
	} else {
		return VIEWPORT_HEIGHT_RADIANS / (self.view.bounds.size.height / viewBounds.size.height);
	}
	
	return -1.0;
}

- (double)_heightInRadiansForView:(UIView *)viewToDraw {
	CGRect viewBounds = viewToDraw.bounds;
	
	BOOL sideways = (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight);
	
	//autoadjust the width and height of our viewport based on the view's size.
	
	if (sideways) {
		return VIEWPORT_WIDTH_RADIANS / (self.view.bounds.size.width / viewBounds.size.width);
	} else {
		return VIEWPORT_HEIGHT_RADIANS / (self.view.bounds.size.height / viewBounds.size.height);
	}
	
	return -1.0;
}

@end
