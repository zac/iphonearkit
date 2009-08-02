//
//  ARGeoCoordinate.h
//  ARKitDemo
//
//  Created by Haseman on 8/1/09.
//  Copyright 2009 Gravity Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARCoordinate.h"

#import <CoreLocation/CoreLocation.h>

@interface ARGeoCoordinate : ARCoordinate {
	CLLocation *geoLocation;
}

@property (nonatomic, retain) CLLocation *geoLocation;

+ (ARGeoCoordinate *)coordinateWithLocation:(CLLocation *)location;

- (void)calibrateUsingOrigin:(CLLocation *)origin;
+ (ARGeoCoordinate *)coordinateWithLocation:(CLLocation *)location fromOrigin:(CLLocation *)origin;

@end
