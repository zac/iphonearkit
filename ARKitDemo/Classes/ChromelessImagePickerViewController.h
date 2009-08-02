//
//  SpookImagePickerViewController.h
//  Spook
//
//  Created by Arshad Tayyeb on 8/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//


//  ORIGINALLY:  http://www.codza.com/custom-uiimagepickercontroller-camera-view
//  CustomImagePicker.h
//  meanPhoto
//
//  Created by lajos kamocsay on 1/10/09.
//  Copyright 2009 soymint.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ChromelessImagePickerViewController : UIImagePickerController {
	NSTimer *pTimer;
}

-(void)inspectView: (UIView *)theView depth:(int)depth path:(NSString *)path;

@property (nonatomic, retain) NSTimer *pTimer;

@end
