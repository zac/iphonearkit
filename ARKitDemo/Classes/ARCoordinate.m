//
//  ARCoordinate.m
//  ARKitDemo
//
//  Created by Zac White on 8/1/09.
//  Copyright 2009 Gravity Mobile. All rights reserved.
//

#import "ARCoordinate.h"


@implementation ARCoordinate

@synthesize radialDistance, inclination, azimuth;

@synthesize title, subtitle;

+ (ARCoordinate *)coordinateWithRadialDistance:(double)newRadialDistance inclination:(double)newInclination azimuth:(double)newAzimuth {
	ARCoordinate *newCoordinate = [[ARCoordinate alloc] init];
	newCoordinate.radialDistance = newRadialDistance;
	newCoordinate.inclination = newInclination;
	newCoordinate.azimuth = newAzimuth;
	
	newCoordinate.title = @"";
	
	return [newCoordinate autorelease];
}

- (NSUInteger)hash{
	return [self.title hash];
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToCoordinate:other];
}

- (BOOL)isEqualToCoordinate:(ARCoordinate *)otherCoordinate {
    if (self == otherCoordinate) return YES;
    
	BOOL equal = self.radialDistance == otherCoordinate.radialDistance;
	equal = equal && self.inclination == otherCoordinate.inclination;
	equal = equal && self.azimuth == otherCoordinate.azimuth;
	equal = equal && [self.title isEqualToString:otherCoordinate.title];
	
	return equal;
}

- (void)dealloc {
	
	self.title = nil;
	self.subtitle = nil;
	
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ r: %f φ: %f θ: %f", self.title, self.radialDistance, self.azimuth * (180.0/M_PI), self.inclination * (180.0/M_PI)];
}

@end
