//
//  SOSPicker.m
//  SyncOnSet
//
//  Created by Christopher Sullivan on 10/25/13.
//
//

#import "SOSPicker.h"
#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"
#import <ImageIO/ImageIO.h>

#define CDV_PHOTO_PREFIX @"cdv_photo_"

@implementation SOSPicker

@synthesize callbackId;

- (void) getPictures:(CDVInvokedUrlCommand *)command {
    NSDictionary *options = [command.arguments objectAtIndex: 0];
    
    NSInteger maximumImagesCount = [[options objectForKey:@"maximumImagesCount"] integerValue];
    self.width = [[options objectForKey:@"width"] integerValue];
    self.height = [[options objectForKey:@"height"] integerValue];
    self.quality = [[options objectForKey:@"quality"] integerValue];
    
    // Create the an album controller and image picker
    //  ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] init];
    ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] initWithNibName: nil bundle: nil];
    
    //  if (maximumImagesCount == 1) {
    //      albumController.immediateReturn = true;
    //      albumController.singleSelection = true;
    //   } else {
    //      albumController.immediateReturn = false;
    //      albumController.singleSelection = false;
    //   }
    
    ELCImagePickerController *imagePicker = [[ELCImagePickerController alloc] initWithRootViewController:picker];
    imagePicker.maximumImagesCount = maximumImagesCount;
    imagePicker.returnsOriginalImage = 1;
    imagePicker.imagePickerDelegate = self;
    
    picker.parent = imagePicker;
    self.callbackId = command.callbackId;
    // Present modally
    [self.viewController presentViewController:imagePicker
                                      animated:YES
                                    completion:nil];
}


- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
    CDVPluginResult* result = nil;
    NSMutableArray *resultStrings = [[NSMutableArray alloc] init];
    NSData* data = nil;
    NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
    NSError* err = nil;
    NSFileManager* fileMgr = [[NSFileManager alloc] init];
    NSString* filePath;
    ALAsset* asset = nil;
    UIImageOrientation orientation = UIImageOrientationUp;;
    CGSize targetSize = CGSizeMake(self.width, self.height);
    NSLog(@"RESULT? %@", info);
    for (NSDictionary *dict in info) {
        asset = [dict objectForKey:@"ALAsset"];
        // From ELCImagePickerController.m
        NSLog(@"ASSET? %@", asset);
        
        int i = 1;
        do {
            filePath = [NSString stringWithFormat:@"%@/%@%03d.%@", docsPath, CDV_PHOTO_PREFIX, i++, @"jpg"];
        } while ([fileMgr fileExistsAtPath:filePath]);
        
        NSLog(@"FILEPATH? %@", filePath);
        
        @autoreleasepool {
            ALAssetRepresentation *assetRep = [asset defaultRepresentation];
            CGImageRef imgRef = NULL;
            //            UIImage *realImage = [UIImage imageWithCGImage:[assetRep fullResolutionImage]];
            
            //defaultRepresentation returns image as it appears in photo picker, rotated and sized,
            //so use UIImageOrientationUp when creating our image below.
            if (picker.returnsOriginalImage) {
                imgRef = [assetRep fullResolutionImage];
                orientation = [assetRep orientation];
            } else {
                imgRef = [assetRep fullScreenImage];
            }
            
            UIImage* image = [UIImage imageWithCGImage:imgRef scale:1.0f orientation:orientation];
            
            image = [self imageCorrectedForCaptureOrientation:image];
            
            if (self.width == 0 && self.height == 0) {
                data = UIImageJPEGRepresentation(image, self.quality/100.0f);
            } else {
                UIImage* scaledImage = [self imageByScalingNotCroppingForSize:image toSize:targetSize];
                data = UIImageJPEGRepresentation(scaledImage, self.quality/100.0f);
            }
            
            
            //            ===============
            //            ROUND 1
            //            ===============
            //            NSDictionary* imageInfo = [NSDictionary dictionaryWithObject:realImage forKey:UIImagePickerControllerOriginalImage];
            //            NSLog(@"=======================>>>>>>> GONNA EXTRACT EXIF from %@", imageInfo);
            //            NSDictionary *controllerMetadata = [imageInfo objectForKey:@"UIImagePickerControllerMediaMetadata"];
            //            NSLog(@"%@", controllerMetadata);
            //            if (controllerMetadata) {
            //                NSMutableDictionary *EXIFDictionary = [[controllerMetadata objectForKey:(NSString *)kCGImagePropertyExifDictionary]mutableCopy];
            //                NSLog(@"=======================>>>>>>> has data  \n %@", EXIFDictionary);
            //            }
            
            
            //            ===============
            //            ROUND 2
            //            ===============
            //            uint8_t *buffer = (Byte*)malloc(assetRep.size);
            //
            //            NSLog(@"SIZE: %lld", assetRep.size);
            //
            //            // buffer -> NSData object; free buffer afterwards
            //            NSData *adata = [[NSData alloc] initWithBytesNoCopy:buffer length:assetRep.size freeWhenDone:YES];
            //
            //            // identify image type (jpeg, png, RAW file, ...) using UTI hint
            //            NSDictionary* sourceOptionsDict = [NSDictionary dictionaryWithObjectsAndKeys:(id)[assetRep UTI] ,kCGImageSourceTypeIdentifierHint,nil];
            //
            //            NSLog(@"SOURCE OPTS: %@", sourceOptionsDict);
            //
            //            // create CGImageSource with NSData
            //            CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef) adata,  (__bridge CFDictionaryRef) sourceOptionsDict);
            //
            //            NSLog(@"SOURCE REF: %@", sourceRef);
            //
            //            // get imagePropertiesDictionary
            //            CFDictionaryRef imagePropertiesDictionary;
            //            imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(sourceRef,0, NULL);
            //
            //            NSLog(@"IMAGE PROPERTIES: %@", imagePropertiesDictionary);
            //
            //            if(imagePropertiesDictionary){
            //                // get exif data
            //                CFDictionaryRef exif = (CFDictionaryRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifDictionary);
            //                NSDictionary *exif_dict = (__bridge NSDictionary*)exif;
            //                NSLog(@"exif_dict: %@",exif_dict);
            //            }
            
            
            //            ===============
            //            ROUND 3 WORKED!! but no GPS :'(
            //            ===============
            //            CFDictionaryRef imagePropertiesRef          = (__bridge CFDictionaryRef)asset.defaultRepresentation.metadata;
            //            NSLog(@"==================");
            //            NSLog(@"DATA: %@", imagePropertiesRef);
            //            NSLog(@"==================");
            
            
            
            //            ===============
            //            ROUND 4 LESS DATA and no GPS :-/
            //            ===============
            //            NSData* pngData =  UIImagePNGRepresentation(image);
            //
            //            CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)pngData, NULL);
            //            NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
            //
            //            NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
            //
            //            //For GPS Dictionary
            //            NSMutableDictionary *GPSDictionary = [[metadataAsMutable objectForKey:(NSString *)kCGImagePropertyGPSDictionary]mutableCopy];
            //            if(!GPSDictionary)
            //                GPSDictionary = [NSMutableDictionary dictionary];
            //
            //            NSLog(@"==================");
            //            NSLog(@"METADATA: %@", metadata);
            //            NSLog(@"GPSDict: %@", GPSDictionary);
            //            NSLog(@"==================");
            
            
            
            //            ===============
            //            ROUND 5 NO GPS
            //            ===============
            //            CGImageSourceRef mySourceRef = CGImageSourceCreateWithData((CFDataRef)data, NULL);
            //
            //            //CGImageSourceRef mySourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)myURL, NULL);
            //            if (mySourceRef){
            //                NSDictionary *myMetadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(mySourceRef,0,NULL);
            //                NSLog(@"DATA: %@", myMetadata);
            //                NSDictionary *exifDic = [myMetadata objectForKey:(NSString *)kCGImagePropertyExifDictionary];
            //                NSDictionary *tiffDic = [myMetadata objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
            //                NSLog(@"exifDic properties: %@", myMetadata); //all data
            //                float rawShutterSpeed = [[exifDic objectForKey:(NSString *)kCGImagePropertyExifExposureTime] floatValue];
            //                int decShutterSpeed = (1 / rawShutterSpeed);
            //                NSLog(@"Camera %@",[tiffDic objectForKey:(NSString *)kCGImagePropertyTIFFModel]);
            //                NSLog(@"Focal Length %@mm",[exifDic objectForKey:(NSString *)kCGImagePropertyExifFocalLength]);
            //                NSLog(@"Shutter Speed %@", [NSString stringWithFormat:@"1/%d", decShutterSpeed]);
            //                NSLog(@"Aperture f/%@",[exifDic objectForKey:(NSString *)kCGImagePropertyExifFNumber]);
            //
            //
            //                NSNumber *ExifISOSpeed  = [[exifDic objectForKey:(NSString*)kCGImagePropertyExifISOSpeedRatings] objectAtIndex:0];
            //                NSLog(@"ISO %ld",(long)[ExifISOSpeed integerValue]);
            //                NSLog(@"Taken %@",[exifDic objectForKey:(NSString*)kCGImagePropertyExifDateTimeDigitized]);
            //
            //
            //            }
            
            
            //            ===============
            //            ROUND 6
            //            ===============
            NSDictionary* pickedImageMetadata = [assetRep metadata];
            NSDictionary* gpsInfo = [pickedImageMetadata objectForKey:(__bridge NSString *)kCGImagePropertyGPSDictionary];
            NSDate *imageDate = [asset valueForProperty:ALAssetPropertyDate];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            [dateFormatter setLocale:enUSPOSIXLocale];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
            
            NSString *iso8601String = [dateFormatter stringFromDate:imageDate];
            
            //            NSLog(@"==================");
            //            NSLog(@"GPS: %@", gpsInfo);
            //            NSLog(@"==================");
            
            if(!gpsInfo){
                gpsInfo = @{};
            }
            
            if (![data writeToFile:filePath options:NSAtomicWrite error:&err]) {
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[err localizedDescription]];
                break;
            } else {
                //                [resultStrings addObject:[[NSURL fileURLWithPath:filePath] absoluteString]];
                NSDictionary *dict = @{
                                       @"src" : [[NSURL fileURLWithPath:filePath] absoluteString],
                                       @"gps" : gpsInfo,
                                       @"date": iso8601String
                                       };
                [resultStrings addObject:dict];
            }
        }
        
    }
    
    if (nil == result) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:resultStrings];
    }
    
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

- (UIImage*)imageCorrectedForCaptureOrientation:(UIImage*)anImage
{
    float rotation_radians = 0;
    bool perpendicular = false;
    
    switch ([anImage imageOrientation]) {
        case UIImageOrientationUp :
            rotation_radians = 0.0;
            break;
            
        case UIImageOrientationDown:
            rotation_radians = M_PI; // don't be scared of radians, if you're reading this, you're good at math
            break;
            
        case UIImageOrientationRight:
            rotation_radians = M_PI_2;
            perpendicular = true;
            break;
            
        case UIImageOrientationLeft:
            rotation_radians = -M_PI_2;
            perpendicular = true;
            break;
            
        default:
            break;
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(anImage.size.width, anImage.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Rotate around the center point
    CGContextTranslateCTM(context, anImage.size.width / 2, anImage.size.height / 2);
    CGContextRotateCTM(context, rotation_radians);
    
    CGContextScaleCTM(context, 1.0, -1.0);
    float width = perpendicular ? anImage.size.height : anImage.size.width;
    float height = perpendicular ? anImage.size.width : anImage.size.height;
    CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [anImage CGImage]);
    
    // Move the origin back since the rotation might've change it (if its 90 degrees)
    if (perpendicular) {
        CGContextTranslateCTM(context, -anImage.size.height / 2, -anImage.size.width / 2);
    }
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    return newImage;
}


- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
    CDVPluginResult* pluginResult = nil;
    NSArray* emptyArray = [NSArray array];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:emptyArray];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

- (UIImage*)imageByScalingNotCroppingForSize:(UIImage*)anImage toSize:(CGSize)frameSize
{
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = frameSize.width;
    CGFloat targetHeight = frameSize.height;
    CGFloat scaleFactor = 0.0;
    CGSize scaledSize = frameSize;
    
    if (CGSizeEqualToSize(imageSize, frameSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        // opposite comparison to imageByScalingAndCroppingForSize in order to contain the image within the given bounds
        if (widthFactor == 0.0) {
            scaleFactor = heightFactor;
        } else if (heightFactor == 0.0) {
            scaleFactor = widthFactor;
        } else if (widthFactor > heightFactor) {
            scaleFactor = heightFactor; // scale to fit height
        } else {
            scaleFactor = widthFactor; // scale to fit width
        }
        scaledSize = CGSizeMake(width * scaleFactor, height * scaleFactor);
    }
    
    UIGraphicsBeginImageContext(scaledSize); // this will resize
    
    [sourceImage drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }
    
    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

@end
