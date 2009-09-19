//
//  ARKitDemoAppDelegate.h
//  ARKitDemo
//
//  Created by Zac White on 8/1/09.
//  Copyright Zac White 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ARGeoViewController.h"

@interface ARKitDemoAppDelegate : NSObject <UIApplicationDelegate, ARViewDelegate> {
    UIWindow *window;
}

- (UIView *)viewForCoordinate:(ARCoordinate *)coordinate;

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

