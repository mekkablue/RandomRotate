// RandomRotate.m
// Randomly rotates each glyph layer around its bounding-box center.
//
// Filter > Random Rotate
// Custom parameter syntax:  RandomRotate; maxAngle: 15;

#import "RandomRotate.h"

#define kPrefDomain @"com.mekkablue.RandomRotate"
#define kMaxAngleKey kPrefDomain @".maxAngle"
#define kDefaultMaxAngle 15.0

@implementation RandomRotate

// ---------------------------------------------------------------------------
#pragma mark - Initialisation
// ---------------------------------------------------------------------------

- (instancetype)init {
    self = [super init];
    if (self) {
        // Load the NIB in init so _view is set before Glyphs inspects it.
        [[NSBundle bundleForClass:[self class]] loadNibNamed:@"IBdialog" owner:self topLevelObjects:nil];
    }
    return self;
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

// Called just before the dialog appears; restore stored values into the UI.
- (nullable NSError *)setup {
    [super setup];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{kMaxAngleKey: @(kDefaultMaxAngle)}];

    CGFloat maxAngle = [defaults doubleForKey:kMaxAngleKey];
    if (maxAngle <= 0.0) {
        maxAngle = kDefaultMaxAngle;
    }
    [self.maxAngleField setDoubleValue:maxAngle];
    [self process:nil];
    return nil;
}

// Live-preview loop — called on every UI change.
- (void)process:(nullable id)sender {
    CGFloat maxAngle = [[NSUserDefaults standardUserDefaults] doubleForKey:kMaxAngleKey];
    if (maxAngle <= 0.0) {
        maxAngle = kDefaultMaxAngle;
    }

    for (NSUInteger k = 0; k < _shadowLayers.count; k++) {
        GSLayer *shadowLayer = _shadowLayers[k];
        GSLayer *layer       = _layers[k];
        // Restore layer to its pre-filter state from the shadow copy.
        [layer getCopyOfContentFromLayer:shadowLayer doSelection:_checkSelection];
        [self rotateLayer:layer maxAngle:maxAngle];
    }
    [super process:nil];
}

// Export / batch entry point (called per layer from Custom Parameters).
// arguments[0] is the filter name; arguments[1] is the maxAngle value.
- (void)processLayer:(GSLayer *)layer withArguments:(NSArray *)arguments {
    CGFloat maxAngle = kDefaultMaxAngle;
    if (arguments.count > 1) {
        maxAngle = [arguments[1] doubleValue];
    } else {
        CGFloat stored = [[NSUserDefaults standardUserDefaults] doubleForKey:kMaxAngleKey];
        if (stored > 0.0) {
            maxAngle = stored;
        }
    }
    [self rotateLayer:layer maxAngle:maxAngle];
}

// Produces the Custom Parameter string shown in Font Info > Instances.
- (NSString *)customParameterString {
    CGFloat maxAngle = [[NSUserDefaults standardUserDefaults] doubleForKey:kMaxAngleKey];
    if (maxAngle <= 0.0) {
        maxAngle = kDefaultMaxAngle;
    }
    return [NSString stringWithFormat:@"RandomRotate; maxAngle: %g;", maxAngle];
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
#pragma mark - Private helper
// ---------------------------------------------------------------------------

/// Applies a random rotation in the range [-maxAngle, +maxAngle] degrees to
/// @p layer, rotating around the center of its bounding box.
- (void)rotateLayer:(GSLayer *)layer maxAngle:(CGFloat)maxAngle {
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
