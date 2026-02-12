#import "include/VirtualDisplayBridge.h"
#include <Foundation/Foundation.h>
#import <objc/runtime.h>

// Forward declare private classes
@interface CGVirtualDisplayDescriptor : NSObject
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) CGPoint whitePoint;
@property (nonatomic) CGPoint bluePrimary;
@property (nonatomic) CGPoint greenPrimary;
@property (nonatomic) CGPoint redPrimary;
@property (nonatomic) uint32_t maxPixelsHigh;
@property (nonatomic) uint32_t maxPixelsWide;
@property (nonatomic) CGSize sizeInMillimeters;
@property (nonatomic) uint32_t serialNum;
@property (nonatomic) uint32_t productID;
@property (nonatomic) uint32_t vendorID;
@end

@interface CGVirtualDisplayMode : NSObject
- (instancetype)initWithWidth:(uint32_t)width height:(uint32_t)height refreshRate:(double)refreshRate;
@end

@interface CGVirtualDisplaySettings : NSObject
@property (nonatomic) BOOL hiDPI;
@property (nonatomic, copy) NSArray *modes;
@end

@interface CGVirtualDisplay : NSObject
@property (nonatomic, readonly) uint32_t displayID;
- (instancetype)initWithDescriptor:(CGVirtualDisplayDescriptor *)descriptor;
- (BOOL)applySettings:(CGVirtualDisplaySettings *)settings;
@end

id createVirtualDisplay(int width, int height, double ppix, double ppiy, BOOL hiDPI, NSString *name) {
    CGVirtualDisplaySettings *settings = [[CGVirtualDisplaySettings alloc] init];
    settings.hiDPI = hiDPI;

    CGVirtualDisplayDescriptor *descriptor = [[CGVirtualDisplayDescriptor alloc] init];
    descriptor.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    descriptor.name = name;

    // See System Preferences > Displays > Color > Open Profile > Apple display native information
    descriptor.whitePoint = CGPointMake(0.3125, 0.3291);
    descriptor.bluePrimary = CGPointMake(0.1494, 0.0557);
    descriptor.greenPrimary = CGPointMake(0.2559, 0.6983);
    descriptor.redPrimary = CGPointMake(0.6797, 0.3203);
    descriptor.maxPixelsHigh = height;
    descriptor.maxPixelsWide = width;
    descriptor.sizeInMillimeters = CGSizeMake(25.4 * width / ppix, 25.4 * height / ppiy);
    descriptor.serialNum = 1;
    descriptor.productID = 1;
    descriptor.vendorID = 1;

    CGVirtualDisplay *display = [[CGVirtualDisplay alloc] initWithDescriptor:descriptor];

    if (settings.hiDPI) {
        width /= 2;
        height /= 2;
    }
    CGVirtualDisplayMode *mode = [[CGVirtualDisplayMode alloc] initWithWidth:width
        height:height
        refreshRate:60];
    settings.modes = @[mode];

    if (![display applySettings:settings])
        return nil;

    return display;
}

@implementation VirtualDisplayBridge

+ (nullable id)createDescriptorWithWidth:(uint32_t)width
        height:(uint32_t)height
        ppiX:(double)ppiX
        ppiY:(double)ppiY
        hiDPI:(BOOL)hiDPI
        name:(NSString *)name {
    return createVirtualDisplay(width, height, ppiX, ppiY, hiDPI, name);
}

+ (nullable id)createDisplayWithDescriptor:(id)descriptor {
    // Not used anymore since createVirtualDisplay handles everything
    return descriptor;
}

+ (CGDirectDisplayID)getDisplayIDFromVirtualDisplay:(id)display {
    @try {
        if (![display isKindOfClass:NSClassFromString(@"CGVirtualDisplay")]) {
            return 0;
        }

        CGVirtualDisplay *virtualDisplay = (CGVirtualDisplay *)display;
        return virtualDisplay.displayID;
    } @catch (NSException *exception) {
        NSLog(@"Error getting display ID: %@", exception);
        return 0;
    }
}

+ (BOOL)destroyDisplay:(id)display {
    @try {
        // Display will be deallocated when released
        return display != nil;
    } @catch (NSException *exception) {
        NSLog(@"Error destroying display: %@", exception);
        return NO;
    }
}

+ (void)applySettings:(id)settings toDisplay:(id)display {
    @try {
        if (![display isKindOfClass:NSClassFromString(@"CGVirtualDisplay")]) {
            NSLog(@"Invalid display object");
            return;
        }

        CGVirtualDisplay *virtualDisplay = (CGVirtualDisplay *)display;
        CGVirtualDisplaySettings *displaySettings = (CGVirtualDisplaySettings *)settings;

        [virtualDisplay applySettings:displaySettings];
    } @catch (NSException *exception) {
        NSLog(@"Error applying settings: %@", exception);
    }
}

@end