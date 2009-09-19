//
//  ARGeoViewController.h
//  ARKitDemo
//
//  Created by Zac White on 8/2/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ARViewController.h"

@interface ARGeoViewController : ARViewController {
	CLLocation *centerLocation;
}

@property (nonatomic, retain) CLLocation *centerLocation;

@end
