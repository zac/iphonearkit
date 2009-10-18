//
//  ARVector.m
//  ARKitDemo
//
//  Created by Zac White on 10/11/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import "ARVector.h"

@implementation ARVector

@synthesize x, y, z;

- (double)dotProductWithVector:(ARVector *)vector {
	return vector.x * self.x + vector.y * self.y + vector.z * self.z;
}

- (ARVector *)crossProductWithVector:(ARVector *)vector {
	return nil;
}

@end
