//
//  LogicTests.h
//  ARKitDemo
//
//  Created by Zac White on 9/26/09.
//  Copyright 2009 Zac White. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

//  Application unit tests contain unit test code that must be injected into an application to run correctly.
//  Define USE_APPLICATION_UNIT_TEST to 0 if the unit test code is designed to be linked into an independent test executable.

#import <SenTestingKit/SenTestingKit.h>
//#import <UIKit/UIKit.h>
//#import <CoreGraphics/CoreGraphics.h>

#import "ARGeoCoordinate.h"
#import "ARCoordinate.h"
#import "ARViewController.h"
#import "ARCoordinate.h"


@interface LogicTests : SenTestCase {

}

@end

@interface LogicTests (ARCoordinateTests)
- (void)testCoordinateEqual;
@end

@interface LogicTests (ARViewControllerTests)
- (void)testViewportContainsCenter;
@end
