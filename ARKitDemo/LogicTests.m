//
//  LogicTests.m
//  ARKitDemo
//
//  Created by Zac White on 9/26/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import "LogicTests.h"


@implementation LogicTests


@end

#pragma mark -
#pragma mark ARGeoCoordinate Tests

@implementation LogicTests (ARGeoCoordinateTests)
@end

#pragma mark -
#pragma mark ARCoordinate Tests


@implementation LogicTests (ARCoordinateTests)

- (void)testCoordinateEqual {
	
	ARCoordinate *coordinate1 = [[ARCoordinate alloc] init];
	ARCoordinate *coordinate2 = [[ARCoordinate alloc] init];
	
	coordinate1.azimuth = coordinate2.azimuth = 10.0;
	coordinate1.inclination = coordinate2.inclination = 10.0;
	coordinate1.radialDistance = coordinate2.radialDistance = 10.0;
	coordinate1.title = coordinate2.title = @"Testing";
	
	STAssertTrue([coordinate1 isEqualToCoordinate:coordinate2], @"Coordinates with the same values aren't equal.");
	
	STAssertTrue([coordinate1 isEqualToCoordinate:coordinate2] == [coordinate2 isEqualToCoordinate:coordinate1], @"Coordinate 1 == Coordinate 2 but Coordinate 2 != Coordinate 1");
	
	coordinate1.title = @"";
	coordinate2.title = @"a";
	
	STAssertFalse([coordinate1 isEqualToCoordinate:coordinate2], @"Coordinates with different titles are considered equal.");
	
	coordinate1.title = nil;
	coordinate2.title = @"a";
	
	STAssertFalse([coordinate1 isEqualToCoordinate:coordinate2], @"Coordaintes with one nil title are considered equal.");
	
	coordinate1.title = nil;
	coordinate2.title = nil;
	
	STAssertTrue([coordinate1 isEqualToCoordinate:coordinate2], @"Coordinates with nil titles aren't equal.");
}

- (void)testCoordinateFactor {
	ARCoordinate *coordinate1 = [ARCoordinate coordinateWithRadialDistance:10.0
															   inclination:10.0
																   azimuth:10.0];
	
	STAssertNotNil(coordinate1, @"Coordinate factor method failed to create an instance.");
	
	ARCoordinate *coordinate2 = [ARCoordinate coordinateWithRadialDistance:10.0
															   inclination:10.0
																   azimuth:10.0];
	
	STAssertTrue([coordinate1 isEqualToCoordinate:coordinate2], @"Coordinate factor method doesn't create equal instances.");
}

@end

#pragma mark -
#pragma mark ARViewController Tests

@implementation LogicTests (ARViewControllerTests)

- (void)testViewportContainsCenter {
	
	ARViewController *viewController = [[ARViewController alloc] init];
	viewController.debugMode = NO;
	
	ARCoordinate *coordinate = [[ARCoordinate alloc] init];
	coordinate.azimuth = 0.0;
	coordinate.inclination = 0.0;
	coordinate.radialDistance = 10.0;
	
	viewController.centerCoordinate = coordinate;
		
	STAssertTrue([viewController viewportContainsCoordinate:coordinate], @"Viewport does not contain center.");
	
	[coordinate release];
	[viewController release];
}

@end
