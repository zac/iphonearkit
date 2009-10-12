//
//  ARVector.h
//  ARKitDemo
//
//  Created by Zac White on 10/11/09.
//  Copyright 2009 Zac White. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ARVector : NSObject {
	double x;
	double y;
	double z;
}

@property double x;
@property double y;
@property double z;

- (ARVector *)dotProductWithVector:(ARVector *)vector;

@end
