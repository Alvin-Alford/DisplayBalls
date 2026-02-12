#ifndef VirtualDisplayBridge_h
#define VirtualDisplayBridge_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

// C function for creating virtual display
id _Nullable createVirtualDisplay(int width, int height, double ppix, double ppiy, BOOL hiDPI, NSString * _Nullable name);

@interface VirtualDisplayBridge : NSObject

+ (nullable id)createDescriptorWithWidth:(uint32_t)width
                                    height:(uint32_t)height
                                    ppiX:(double)ppiX
                                    ppiY:(double)ppiY
                                    hiDPI:(BOOL)hiDPI
                                    name:(NSString *)name ;

+ (nullable id)createDisplayWithDescriptor:(id)descriptor;

+ (CGDirectDisplayID)getDisplayIDFromVirtualDisplay:(id)display;

+ (BOOL)destroyDisplay:(id)display;

+ (void)applySettings:(id)settings toDisplay:(id)display;

@end

NS_ASSUME_NONNULL_END

#endif