                                                                                                                                                   
#import "MSKitGeometryFunctions.h"
#import "MSKitLoggingFunctions.h"
#import "MSReflectingView.h"
#import "UIView+MSKitAdditions.h"
#import <GLKit/GLKit.h>
#import "NSString+MSKitAdditions.h"

@interface MSReflectingContentView : UIView

@end

@implementation MSReflectingContentView

+ (Class)layerClass {
    return [CAReplicatorLayer class];
}

@end

@interface MSReflectingView ()

- (void)initializeIVARs;

@property (nonatomic, strong) MSReflectingContentView * content;
@property (nonatomic, strong) CAReplicatorLayer * replicator;
@property (nonatomic, strong) CAGradientLayer * gradient;
@property (nonatomic, strong) UIImageView * imageView;

- (void)setupReflection;

@end


@implementation MSReflectingView {

    struct {
        BOOL usesGradientSetInNib;
        BOOL gapSetInNib;
        BOOL angleSetInNib;
        BOOL hasReflectionSetInNib;
        BOOL eyeDistanceSetInNib;
        BOOL imageYScaleSetInNib;
        BOOL hasAwoken;
    } flags;
    
}

@synthesize 
content = _content,
gradient = _gradient,
imageYScale = _imageYScale,
usesGradient = _usesGradient,
hasReflection = _hasReflection,
angle = _angle,
eyeDistance = _eyeDistance,
replicator = _replicator,
gap = _gap,
imageName = _imageName,
image = _image,
imageView = _imageView;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        flags.hasAwoken = YES;
        [self initializeIVARs];
    }
    
    return self;
    
}

- (void)layoutSubviews {
    
    CGRect bounds = self.bounds;
    self.content.frame = bounds;
    bounds.size.height *= _imageYScale;
    self.imageView.frame = bounds;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    if (!flags.hasAwoken) {
        
        if ([key isEqualToString:@"gap"])
            flags.gapSetInNib = YES;
        
        else if ([key isEqualToString:@"usesGradient"])
            flags.usesGradientSetInNib = YES;
        
        else if ([key isEqualToString:@"hasReflection"])
            flags.hasReflectionSetInNib = YES;
        
        else if ([key isEqualToString:@"angle"])
            flags.angleSetInNib = YES;
        
        else if ([key isEqualToString:@"eyeDistance"])
            flags.eyeDistanceSetInNib = YES;
        
        else if ([key isEqualToString:@"imageYScale"])
            flags.imageYScaleSetInNib = YES;
        
    }
    
    [super setValue:value forKey:key];
    
}

- (void)awakeFromNib {
    
    flags.hasAwoken = YES;
    [self initializeIVARs];
    
}

- (void)initializeIVARs {
    
    if (!flags.gapSetInNib)
        self.gap = 0.0;
    
    if (!flags.angleSetInNib)
        _angle = DegreesToRadians(-100);
    
    if (!flags.usesGradientSetInNib)
        self.usesGradient = NO;
    
    if (!flags.imageYScaleSetInNib)
        self.imageYScale = 0.8;
    
    if (!flags.eyeDistanceSetInNib)
        self.eyeDistance = 850.0;

    self.clipsToBounds = YES;
    
    CGRect bounds = self.bounds;
    bounds.size.height *= _imageYScale;
    
    self.content = [[MSReflectingContentView alloc] initWithFrame:bounds];
    [self addSubview:_content];
    
    self.replicator = (CAReplicatorLayer *)_content.layer;
    _replicator.preservesDepth = YES;
    
    
    self.imageView = [[UIImageView alloc] initWithFrame:bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.nametag = @"imageView";
    _imageView.image = (_image ? _image : [UIImage imageNamed:_imageName]);
    [_content addSubview:_imageView];
        
    if (!flags.hasReflectionSetInNib)
        self.hasReflection = YES;
    else if (_hasReflection)
        [self setupReflection];
                        
}

- (void)setHasReflection:(BOOL)hasReflection {
    
    _hasReflection = hasReflection;
    
    if (_hasReflection)
        [self setupReflection];

    else 
        self.replicator.instanceCount = 1;
}

- (void)setImageName:(NSString *)imageName {
    
    _imageName = imageName;
    
    if (_imageName)
        self.imageView.image = [UIImage imageNamed:_imageName];

}

- (void)setImage:(UIImage *)image {
    
    _image = image;
    if (_image)
        self.imageView.image = _image;

}

- (void)setImageYScale:(CGFloat)imageYScale {
    _imageYScale = imageYScale;                              
}

- (void)setupGradient {
    
    if (!(_usesGradient && _hasReflection))
        return;
    
    if (!_gradient) {
        
        _gradient = [CAGradientLayer layer];
        CGColorRef c1 = [[UIColor blackColor] colorWithAlphaComponent:0.5f].CGColor;
        CGColorRef c2 = [[UIColor blackColor] colorWithAlphaComponent:0.9f].CGColor;
        [_gradient setColors: @[(__bridge id)c1, (__bridge id)c2]];
        [self.layer addSublayer:_gradient];
        
    }
    
    CGRect bounds = self.bounds;
    bounds.size.height = bounds.size.height * _imageYScale;
    _gradient.bounds = bounds;
    _gradient.position = self.imageView.center;
    _gradient.transform = _replicator.instanceTransform;
   
 }

- (void)setAngle:(CGFloat)angle {
    _angle = angle;                              
}

- (void)setUsesGradient:(BOOL)usesGradient {
    
    _usesGradient = usesGradient;
    
    if (_usesGradient)
        [self setupGradient];
    else
        _gradient.hidden = YES;
    
}

- (void)setupReflection {
    
    _replicator.instanceCount = 2;

    CGFloat theta = fmod(_angle, M_PI_2);
    CGFloat tz = (_replicator.bounds.size.height - self.center.y)*cos(DegreesToRadians(theta));
    CGFloat p = 1.0/-_eyeDistance;
    CGFloat c = cos(_angle);
    CGFloat s = sin(_angle);
    
    CATransform3D perspective = {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, p,
        0, 0, 0, 1
    };
    
    CATransform3D rotate = {
        1,  0,  0,  0,
        0,  c,  s,  0,
        0, -s,  c,  0,
        0,  0,  0,  1
    };
    
    CATransform3D translate = {
        1,  0,  0,  0,
        0,  1,  0,  0,
        0,  0,  1,  0,
        0,  0, tz,  1
    };
    
    CATransform3D t = CATransform3DConcat(translate, CATransform3DConcat(rotate, perspective));

    _replicator.instanceTransform = t;
    
    printfobj(stderr, @"t:\n%@\n", CATransform3DString(t));
    if (_usesGradient)
        [self setupGradient];
    
    else {                                                                                                                                                                                                              
        _replicator.instanceAlphaOffset = -0.25;
    }                                              
    
}

@end
