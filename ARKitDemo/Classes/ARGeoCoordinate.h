//
//  ARGeoCoordinate.h
//  ARKitDemo
//
//  Created by Haseman on 8/1/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ARCoordinate.h"

#import <CoreLocation/CoreLocation.h>

@interface ARGeoCoordinate : ARCoordinate {
	CLLocation *geoLocation;
}

@property (nonatomic, retain) CLLocation *geoLocation;

- (float)angleFromCoordinate:(CLLocationCoordinate2D)first toCoordinate:(CLLocationCoordinate2D)second;

+ (ARGeoCoordinate *)coordinateWithLocation:(CLLocation *)location;

- (void)calibrateUsingOrigin:(CLLocation *)origin;
+ (ARGeoCoordinate *)coordinateWithLocation:(CLLocation *)location fromOrigin:(CLLocation *)origin;

@end
