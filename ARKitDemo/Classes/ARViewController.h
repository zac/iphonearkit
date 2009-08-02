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
	
	NSRange *widthViewportRange;
	NSRange *heightViewportRange;
	
	UILabel *locationLabel;
	
	id delegate;
	
	ChromelessImagePickerViewController *picker;
	
	NSArray *locationItems;
	NSArray *locationViews;
}

- (void)startListening;
- (void)updateLocations;

- (CGPoint)pointInView:(UIView *)realityView forCoordinate:(ARCoordinate *)coordinate;

- (BOOL)viewportContainsCoordinate:(ARCoordinate *)coordinate;

@property (nonatomic, assign) id delegate;

@property (nonatomic, retain) ChromelessImagePickerViewController *picker;

@property (retain) ARCoordinate *centerCoordinate;

@property (nonatomic, retain) NSArray *locationItems;
@property (nonatomic, copy) NSArray *locationViews;

@property (nonatomic, retain) UIAccelerometer *accelerometerManager;
@property (nonatomic, retain) CLLocationManager *locationManager;

@end
