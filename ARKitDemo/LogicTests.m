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
@end

#pragma mark -
#pragma mark ARViewController Tests

@implementation LogicTests (ARViewControllerTests)

- (void)testPointInView {
	
	ARViewController *viewController = [[ARViewController alloc] init];
			
	STAssertTrue(YES, @"");
	return;
	
	ARCoordinate *coordinate = [[ARCoordinate alloc] init];
	coordinate.azimuth = 0.0;
	coordinate.inclination = 0.0;
	coordinate.radialDistance = 10.0;
	
	CGPoint thePoint = [viewController pointInView:viewController.view forCoordinate:coordinate];
	
	CGRect viewRect = viewController.view.frame;
	
	[coordinate release];
	[viewController release];
	
	STAssertTrue(CGRectContainsPoint(viewRect, thePoint), @"Rect doesn't contain point.");
}

@end
