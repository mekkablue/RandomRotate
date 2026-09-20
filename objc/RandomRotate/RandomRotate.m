// RandomRotate.m
// Randomly rotates each glyph layer around its bounding-box center.
//
// Filter > Random Rotate
// Custom parameter syntax:  RandomRotate; maxAngle: 15;

#import "RandomRotate.h"
#import <GlyphsCore/GlyphsCore.h>
#import <GlyphsApp/GSCallbackHandler.h>

#define kPrefDomain @"com.mekkablue.RandomRotate"
#define kMaxAngleKey kPrefDomain @".maxAngle"
#define kDefaultMaxAngle 15.0

@interface RandomRotate ()
+ (void)registerUserDefaults;
- (CGFloat)storedMaxAngle;
- (CGFloat)maxAngleFromArguments:(NSArray *)arguments;
- (void)rotateLayer:(GSLayer *)layer maxAngle:(CGFloat)maxAngle;
@end

@implementation RandomRotate {
	// Glyphs 4 no longer provides a _view ivar in GSFilterPlugin, so the
	// plugin brings its own. Without it the bundle fails to load in Glyphs 4
	// with a missing _OBJC_IVAR_$_GSFilterPlugin._view symbol. The Glyphs 4
	// Xcode template declares the same ivar in the subclass.
	NSView *_view;
}

// ---------------------------------------------------------------------------
#pragma mark - Initialisation
// ---------------------------------------------------------------------------

- (instancetype)init {
	self = [super init];
	if (self) {
		// Also needed for the export path: a custom parameter can run before
		// the dialog has ever been opened, and must not read a zero angle.
		[[self class] registerUserDefaults];
	}
	return self;
}

+ (void)registerUserDefaults {
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{kMaxAngleKey: @(kDefaultMaxAngle)}];
}

// ---------------------------------------------------------------------------
#pragma mark - GSFilterPlugin protocol
// ---------------------------------------------------------------------------

- (NSUInteger)interfaceVersion {
	return 1;
}

- (NSString *)title {
	return NSLocalizedString(@"Random Rotate", @"Filter menu name");
}

- (NSString *)actionName {
	return NSLocalizedString(@"Rotate", @"Apply button label");
}

- (nullable NSString *)keyEquivalent {
	return nil;
}

// Load the dialog lazily. Doing it in -init would pull AppKit into the export
// path, where the filter is instantiated without ever showing a dialog.
- (NSView *)view {
	if (!_view) {
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"IBdialog" owner:self topLevelObjects:nil];
	}
	return _view;
}

// Called just before the dialog appears; restore stored values into the UI.
- (nullable NSError *)setup {
	[super setup];
	[[self class] registerUserDefaults];
	[self view]; // make sure the nib, and with it the outlet, is loaded
	self.maxAngleField.doubleValue = [self storedMaxAngle];
	[self process:nil];
	return nil;
}

// Live-preview loop — called on every UI change.
- (void)process:(nullable id)sender {
	CGFloat maxAngle = [self storedMaxAngle];

	for (NSUInteger k = 0; k < _shadowLayers.count; k++) {
		GSLayer *shadowLayer = _shadowLayers[k];
		GSLayer *layer       = _layers[k];
		// Restore layer to its pre-filter state from the shadow copy.
		[layer getCopyOfContentFromLayer:shadowLayer doSelection:_checkSelection];
		[self rotateLayer:layer maxAngle:maxAngle];
	}
	[super process:nil];
}

// Export / batch entry point. This is what Glyphs calls for a
// `Filter` custom parameter in Font Info > Exports — *not*
// -processLayer:withArguments:, which only feeds the preview.
- (void)processFont:(GSFont *)font withArguments:(NSArray *)arguments {
	CGFloat maxAngle = [self maxAngleFromArguments:arguments];

	// Process the first master of the (already interpolated) instance font,
	// honouring any include:/exclude: glyph list, as in the SDK template.
	_checkSelection = NO;
	NSString *fontMasterId = [font fontMasterAtIndex:0].id;
	if (!fontMasterId) {
		return;
	}
	BOOL include = NO;
	NSError *error = nil;
	NSSet *glyphNames = getIncludeExcludeGlyphListFilter(arguments, &include, font, &error);
	for (GSGlyph *glyph in font.glyphs) {
		if (glyphNames && [glyphNames containsObject:glyph.name] != include) {
			continue;
		}
		GSLayer *layer = [glyph layerForId:fontMasterId];
		if (!layer) {
			continue;
		}
		[self rotateLayer:layer maxAngle:maxAngle];
	}
}

// Called per layer to preview an instance’s custom parameters.
- (void)processLayer:(GSLayer *)layer withArguments:(NSArray *)arguments {
	[self rotateLayer:layer maxAngle:[self maxAngleFromArguments:arguments]];
}

// Produces the Custom Parameter string shown in Font Info > Exports.
- (NSString *)customParameterString {
	return [NSString stringWithFormat:@"%@; maxAngle: %g;",
		NSStringFromClass([self class]), [self storedMaxAngle]];
}

// ---------------------------------------------------------------------------
#pragma mark - IBAction
// ---------------------------------------------------------------------------

- (IBAction)setMaxAngle:(id)sender {
	CGFloat value = [sender doubleValue];
	if (value <= 0.0) {
		value = kDefaultMaxAngle;
	}
	[[NSUserDefaults standardUserDefaults] setDouble:value forKey:kMaxAngleKey];
	[self process:nil];
}

// ---------------------------------------------------------------------------
#pragma mark - Settings
// ---------------------------------------------------------------------------

/// The angle stored in the user defaults, falling back to the default value.
- (CGFloat)storedMaxAngle {
	CGFloat maxAngle = [[NSUserDefaults standardUserDefaults] doubleForKey:kMaxAngleKey];
	if (maxAngle <= 0.0) {
		maxAngle = kDefaultMaxAngle;
	}
	return maxAngle;
}

// Reads the angle out of a custom parameter's arguments.
//
// Item 0 is the filter name, the rest are the semicolon-separated parts of the
// parameter value. So "RandomRotate; maxAngle: 7;" arrives as
// ("RandomRotate", "maxAngle: 7") — a *named* argument, which is why reading
// arguments[1].doubleValue (as the SDK template does for its positional
// example) yielded zero and the filter appeared to do nothing.
// A bare "RandomRotate; 7;" is still understood, and include:/exclude: are
// left to getIncludeExcludeGlyphListFilter().
- (CGFloat)maxAngleFromArguments:(NSArray *)arguments {
	[[self class] registerUserDefaults];
	CGFloat maxAngle = [self storedMaxAngle];
	BOOL sawUnnamedValue = NO;

	NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
	for (NSUInteger i = 1; i < arguments.count; i++) {
		if (![arguments[i] isKindOfClass:[NSString class]]) {
			continue;
		}
		NSString *argument = [arguments[i] stringByTrimmingCharactersInSet:whitespace];
		if (argument.length == 0 ||
			[argument hasPrefix:@"include:"] || [argument hasPrefix:@"exclude:"]) {
			continue;
		}

		NSRange colon = [argument rangeOfString:@":"];
		if (colon.location == NSNotFound) {
			// Positional syntax: `RandomRotate; 7;`
			if (!sawUnnamedValue) {
				maxAngle = fabs(argument.doubleValue);
				sawUnnamedValue = YES;
			}
			continue;
		}

		NSString *key = [[argument substringToIndex:colon.location] stringByTrimmingCharactersInSet:whitespace];
		if ([key caseInsensitiveCompare:@"maxAngle"] == NSOrderedSame) {
			NSString *value = [[argument substringFromIndex:NSMaxRange(colon)] stringByTrimmingCharactersInSet:whitespace];
			maxAngle = fabs(value.doubleValue);
		}
	}
	return maxAngle;
}

// ---------------------------------------------------------------------------
#pragma mark - Private helper
// ---------------------------------------------------------------------------

/// Applies a random rotation in the range [-maxAngle, +maxAngle] degrees to
/// @p layer, rotating around the center of its bounding box.
- (void)rotateLayer:(GSLayer *)layer maxAngle:(CGFloat)maxAngle {
	if (maxAngle <= 0.0) {
		return;
	}

	// Uniform random value in [0, 1).
	CGFloat r = (CGFloat)arc4random() / ((CGFloat)UINT32_MAX + 1.0);
	CGFloat angle = -maxAngle + 2.0 * maxAngle * r;

	NSRect  bounds = layer.bounds;
	CGFloat cx     = NSMidX(bounds);
	CGFloat cy     = NSMidY(bounds);

	// Build rotation around (cx, cy).
	// NSAffineTransform right-multiplies each append, so the last call executes
	// first when the transform is applied to a point.  Correct sequence:
	//   translate back → rotate → translate to origin
	NSAffineTransform *t = [NSAffineTransform transform];
	[t translateXBy:cx yBy:cy];
	[t rotateByDegrees:angle];
	[t translateXBy:-cx yBy:-cy];

	[layer transform:t checkForSelection:NO doComponents:YES];
}

@end
