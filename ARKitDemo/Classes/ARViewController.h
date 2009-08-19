//
//  ARKViewController.h
//  ARKitDemo
//
//  Created by Zac White on 8/1/09.
//  Copyright 2009 Gravity Mobile. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>

#import "ARCoordinate.h"

#import "ChromelessImagePickerViewController.h"

@protocol ARViewDelegate

- (UIView *)viewForCoordinate:(ARCoordinate *)coordinate;

@end


@interface ARViewController : UIViewController <UIAccelerometerDelegate, CLLocationManagerDelegate> {
	CLLocationManager *locationManager;
	UIAccelerometer *accelerometerManager;
	
	ARCoordinate *centerCoordinate;
		
	UILabel *_debugView;
	
	id delegate;
	
@private
	BOOL _debugMode;
	
	NSMutableArray *ar_coordinates;
	NSMutableArray *ar_coordinateViews;
}

@property (readonly) NSArray *coordinates;

@property BOOL debugMode;

//adding coordinates to the 
- (void)addCoordinate:(ARCoordinate *)coordinate;
- (void)addCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated;

- (void)addCoordinates:(NSArray *)newCoordinates;


//removing coordinates
- (void)removeCoordinate:(ARCoordinate *)coordinate;
- (void)removeCoordinate:(ARCoordinate *)coordinate animated:(BOOL)animated;

- (void)removeCoordinates:(NSArray *)coordinates;

- (id)initWithLocationManager:(CLLocationManager *)manager;

- (void)startListening;
- (void)updateLocations;

- (CGPoint)pointInView:(UIView *)realityView forCoordinate:(ARCoordinate *)coordinate;

- (BOOL)viewportContainsCoordinate:(ARCoordinate *)coordinate;

@property (nonatomic, assign) id delegate;

@property (retain) ARCoordinate *centerCoordinate;

@property (nonatomic, retain) UIAccelerometer *accelerometerManager;
@property (nonatomic, retain) CLLocationManager *locationManager;

@end
