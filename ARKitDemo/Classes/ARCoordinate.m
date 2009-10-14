//
//  ARCoordinate.m
//  ARKitDemo
//
//  Created by Zac White on 8/1/09.
//  Copyright 2009 Zac White. All rights reserved.
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
	return ([self.title hash] ^ [self.subtitle hash]) + (int)(self.radialDistance + self.inclination + self.azimuth);
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
		
	if (self.title && otherCoordinate.title || self.title && !otherCoordinate.title || !self.title && otherCoordinate.title) {
		equal = equal && [self.title isEqualToString:otherCoordinate.title];
	}
	
	return equal;
}

- (void)dealloc {
	
	self.title = nil;
	self.subtitle = nil;
	
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ r: %.3fm φ: %.3f° θ: %.3f°", self.title, self.radialDistance, radiansToDegrees(self.azimuth), radiansToDegrees(self.inclination)];
}

@end
