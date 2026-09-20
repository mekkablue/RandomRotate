// RandomRotate.h
// Randomly rotates each glyph layer around its bounding-box center.

#import <Cocoa/Cocoa.h>
// In Glyphs 4, GSFilterPlugin lives in the GlyphsApp framework.
// (In Glyphs 3 it used to be <GlyphsCore/GSFilterPlugin.h>.)
#import <GlyphsApp/GSFilterPlugin.h>

NS_ASSUME_NONNULL_BEGIN

@interface RandomRotate : GSFilterPlugin

@property (weak, nullable) IBOutlet NSTextField *maxAngleField;

- (IBAction)setMaxAngle:(id)sender;

@end

NS_ASSUME_NONNULL_END
