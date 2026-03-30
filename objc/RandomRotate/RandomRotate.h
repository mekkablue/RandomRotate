// RandomRotate.h
// Randomly rotates each glyph layer around its bounding-box center.

#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GSFilterPlugin.h>
#import <GlyphsCore/GSLayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface RandomRotate : GSFilterPlugin

@property (weak, nullable) IBOutlet NSTextField *maxAngleField;

- (IBAction)setMaxAngle:(id)sender;

@end

NS_ASSUME_NONNULL_END
