/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGMessageImageViewOverlayView.h"

#import <pop/POP.h>

typedef enum {
    TGMessageImageViewOverlayViewTypeNone = 0,
    TGMessageImageViewOverlayViewTypeDownload = 1,
    TGMessageImageViewOverlayViewTypeProgress = 2,
    TGMessageImageViewOverlayViewTypeProgressCancel = 3,
    TGMessageImageViewOverlayViewTypeProgressNoCancel = 4,
    TGMessageImageViewOverlayViewTypePlay = 5
} TGMessageImageViewOverlayViewType;

@interface TGMessageImageViewOverlayLayer : CALayer
{
}

@property (nonatomic) int overlayStyle;
@property (nonatomic) CGFloat progress;
@property (nonatomic) int type;

@end

@implementation TGMessageImageViewOverlayLayer

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
    }
    return self;
}

- (void)setOverlayStyle:(int)overlayStyle
{
    if (_overlayStyle != overlayStyle)
    {
        _overlayStyle = overlayStyle;
        [self setNeedsDisplay];
    }
}

- (void)setNone
{
    _type = TGMessageImageViewOverlayViewTypeNone;
    
    [self pop_removeAnimationForKey:@"progress"];
    [self pop_removeAnimationForKey:@"progressAmbient"];
}

- (void)setDownload
{
    if (_type != TGMessageImageViewOverlayViewTypeDownload)
    {
        [self pop_removeAnimationForKey:@"progress"];
        [self pop_removeAnimationForKey:@"progressAmbient"];
        
        _type = TGMessageImageViewOverlayViewTypeDownload;
        [self setNeedsDisplay];
    }
}

- (void)setPlay
{
    if (_type != TGMessageImageViewOverlayViewTypePlay)
    {
        [self pop_removeAnimationForKey:@"progress"];
        [self pop_removeAnimationForKey:@"progressAmbient"];
        
        _type = TGMessageImageViewOverlayViewTypePlay;
        [self setNeedsDisplay];
    }
}

- (void)setProgressCancel
{
    if (_type != TGMessageImageViewOverlayViewTypeProgressCancel)
    {
        [self pop_removeAnimationForKey:@"progress"];
        [self pop_removeAnimationForKey:@"progressAmbient"];
        
        _type = TGMessageImageViewOverlayViewTypeProgressCancel;
        [self setNeedsDisplay];
    }
}

- (void)setProgressNoCancel
{
    if (_type != TGMessageImageViewOverlayViewTypeProgressNoCancel)
    {
        [self pop_removeAnimationForKey:@"progress"];
        [self pop_removeAnimationForKey:@"progressAmbient"];
        
        _type = TGMessageImageViewOverlayViewTypeProgressNoCancel;
        [self setNeedsDisplay];
    }
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

+ (void)_addAmbientProgressAnimation:(TGMessageImageViewOverlayLayer *)layer
{
    POPBasicAnimation *ambientProgress = [self pop_animationForKey:@"progressAmbient"];
    
    ambientProgress = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerRotation];
    __weak TGMessageImageViewOverlayLayer *weakLayer = layer;
    ambientProgress.fromValue = @((CGFloat)0.0f);
    ambientProgress.toValue = @((CGFloat)M_PI * 2.0f);
    ambientProgress.duration = 3.0;
    ambientProgress.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    [ambientProgress setCompletionBlock:^(__unused POPAnimation *animation, BOOL completed)
    {
        __strong TGMessageImageViewOverlayLayer *strongLayer = weakLayer;
        if (completed && strongLayer != nil && strongLayer->_type == TGMessageImageViewOverlayViewTypeProgress)
        {
            [TGMessageImageViewOverlayLayer _addAmbientProgressAnimation:strongLayer];
        }
    }];
    
    [layer pop_addAnimation:ambientProgress forKey:@"progressAmbient"];
}

- (void)setProgress:(float)progress animated:(bool)animated
{
    if (_type != TGMessageImageViewOverlayViewTypeProgress || ABS(_progress - progress) > FLT_EPSILON)
    {
        if (_type != TGMessageImageViewOverlayViewTypeProgress)
            _progress = 0.0f;
        
        if ([self pop_animationForKey:@"progressAmbient"] == nil)
            [TGMessageImageViewOverlayLayer _addAmbientProgressAnimation:self];
        
        _type = TGMessageImageViewOverlayViewTypeProgress;
        
        if (animated)
        {
            POPBasicAnimation *animation = [self pop_animationForKey:@"progress"];
            if (animation != nil)
            {
                animation.toValue = @((CGFloat)progress);
            }
            else
            {
                animation = [POPBasicAnimation animation];
                animation.property = [POPAnimatableProperty propertyWithName:@"progress" initializer:^(POPMutableAnimatableProperty *prop)
                {
                    prop.readBlock = ^(TGMessageImageViewOverlayLayer *layer, CGFloat values[])
                    {
                        values[0] = layer.progress;
                    };
                    
                    prop.writeBlock = ^(TGMessageImageViewOverlayLayer *layer, const CGFloat values[])
                    {
                        layer.progress = values[0];
                    };
                    
                    prop.threshold = 0.01f;
                }];
                animation.fromValue = @(_progress);
                animation.toValue = @(progress);
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                animation.duration = 0.5;
                [self pop_addAnimation:animation forKey:@"progress"];
            }
        }
        else
        {
            _progress = progress;
            
            [self setNeedsDisplay];
        }
    }
}

- (void)drawInContext:(CGContextRef)context
{
    UIGraphicsPushContext(context);

    switch (_type)
    {
        case TGMessageImageViewOverlayViewTypeDownload:
        {
            const CGFloat diameter = 50.0f;
            const CGFloat lineWidth = 2.0f;
            const CGFloat height = 24.0f;
            const CGFloat width = 20.0f;
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
            {
                CGContextSetFillColorWithColor(context, UIColorRGBA(0xffffffff, 0.8f).CGColor);
                CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, diameter, diameter));
            }
            else
            {
                CGContextSetStrokeColorWithColor(context, UIColorRGB(0xeaeaea).CGColor);
                CGContextSetLineWidth(context, 1.5f);
                CGContextStrokeEllipseInRect(context, CGRectMake(1.5f / 2.0f, 1.5f / 2.0f, diameter - 1.5f, diameter - 1.5f));
            }
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
                CGContextSetStrokeColorWithColor(context, UIColorRGBA(0xff000000, 0.55f).CGColor);
            else
                CGContextSetStrokeColorWithColor(context, TGAccentColor().CGColor);
            
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineWidth(context, lineWidth);
            
            CGPoint mainLine[] = {
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f, (diameter - height) / 2.0f + lineWidth / 2.0f),
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f, (diameter + height) / 2.0f - lineWidth / 2.0f)
            };
            
            CGPoint arrowLine[] = {
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f - width / 2.0f, (diameter + height) / 2.0f + lineWidth / 2.0f - width / 2.0f),
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f, (diameter + height) / 2.0f + lineWidth / 2.0f),
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f, (diameter + height) / 2.0f + lineWidth / 2.0f),
                CGPointMake((diameter - lineWidth) / 2.0f + lineWidth / 2.0f + width / 2.0f, (diameter + height) / 2.0f + lineWidth / 2.0f - width / 2.0f),
            };
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
                CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
            CGContextStrokeLineSegments(context, mainLine, sizeof(mainLine) / sizeof(mainLine[0]));
            CGContextStrokeLineSegments(context, arrowLine, sizeof(arrowLine) / sizeof(arrowLine[0]));
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
            {
                CGContextSetBlendMode(context, kCGBlendModeNormal);
                CGContextSetStrokeColorWithColor(context, UIColorRGBA(0x000000, 0.55f).CGColor);
                CGContextStrokeLineSegments(context, arrowLine, sizeof(arrowLine) / sizeof(arrowLine[0]));
                
                CGContextSetBlendMode(context, kCGBlendModeCopy);
                CGContextStrokeLineSegments(context, mainLine, sizeof(mainLine) / sizeof(mainLine[0]));
            }
            
            break;
        }
        case TGMessageImageViewOverlayViewTypeProgressCancel:
        case TGMessageImageViewOverlayViewTypeProgressNoCancel:
        {
            const CGFloat diameter = 50.0f;
            const CGFloat lineWidth = 2.0f;
            const CGFloat crossSize = 16.0f;
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
            {
                CGContextSetFillColorWithColor(context, UIColorRGBA(0x000000, 0.7f).CGColor);
                CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, diameter, diameter));
            }
            else
            {
                CGContextSetStrokeColorWithColor(context, UIColorRGB(0xeaeaea).CGColor);
                CGContextSetLineWidth(context, 1.5f);
                CGContextStrokeEllipseInRect(context, CGRectMake(1.5f / 2.0f, 1.5f / 2.0f, diameter - 1.5f, diameter - 1.5f));
            }
            
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineWidth(context, lineWidth);
            
            CGPoint crossLine[] = {
                CGPointMake((diameter - crossSize) / 2.0f, (diameter - crossSize) / 2.0f),
                CGPointMake((diameter + crossSize) / 2.0f, (diameter + crossSize) / 2.0f),
                CGPointMake((diameter + crossSize) / 2.0f, (diameter - crossSize) / 2.0f),
                CGPointMake((diameter - crossSize) / 2.0f, (diameter + crossSize) / 2.0f),
            };
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
                CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
            else
                CGContextSetStrokeColorWithColor(context, TGAccentColor().CGColor);
            
            if (_type == TGMessageImageViewOverlayViewTypeProgressCancel)
                CGContextStrokeLineSegments(context, crossLine, sizeof(crossLine) / sizeof(crossLine[0]));
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
            {
                CGContextSetBlendMode(context, kCGBlendModeNormal);
                CGContextSetStrokeColorWithColor(context, UIColorRGBA(0xffffff, 1.0f).CGColor);
                if (_type == TGMessageImageViewOverlayViewTypeProgressCancel)
                    CGContextStrokeLineSegments(context, crossLine, sizeof(crossLine) / sizeof(crossLine[0]));
            }
            
            break;
        }
        case TGMessageImageViewOverlayViewTypeProgress:
        {
            const CGFloat diameter = 50.0f;
            const CGFloat lineWidth = 2.0f;
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            CGContextSetLineCap(context, kCGLineCapRound);
            CGContextSetLineWidth(context, lineWidth);
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
                CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
            else
                CGContextSetStrokeColorWithColor(context, TGAccentColor().CGColor);
            
            if (_overlayStyle == TGMessageImageViewOverlayStyleDefault)
            {
                CGContextSetBlendMode(context, kCGBlendModeNormal);
                CGContextSetStrokeColorWithColor(context, UIColorRGBA(0xffffff, 1.0f).CGColor);
            }
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            CGFloat start_angle = 2.0f * ((CGFloat)M_PI) * 0.0f - ((CGFloat)M_PI_2);
            CGFloat end_angle = 2.0f * ((CGFloat)M_PI) * _progress - ((CGFloat)M_PI_2);
            
            CGFloat pathLineWidth = _overlayStyle == TGMessageImageViewOverlayStyleDefault ? 2.0f : 2.0f;
            CGFloat pathDiameter = diameter - pathLineWidth;
            UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(diameter / 2.0f, diameter / 2.0f) radius:pathDiameter / 2.0f startAngle:start_angle endAngle:end_angle clockwise:true];
            path.lineWidth = pathLineWidth;
            path.lineCapStyle = kCGLineCapRound;
            [path stroke];
            
            break;
        }
        case TGMessageImageViewOverlayViewTypePlay:
        {
            const CGFloat diameter = 50.0f;
            const CGFloat width = 20.0f;
            const CGFloat height = width + 4.0f;
            const CGFloat offset = 3.0f;
            
            CGContextSetBlendMode(context, kCGBlendModeCopy);
            
            CGContextSetFillColorWithColor(context, UIColorRGBA(0xffffffff, 0.8f).CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, diameter, diameter));
            
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, offset + CGFloor((diameter - width) / 2.0f), CGFloor((diameter - height) / 2.0f));
            CGContextAddLineToPoint(context, offset + CGFloor((diameter - width) / 2.0f) + width, CGFloor(diameter / 2.0f));
            CGContextAddLineToPoint(context, offset + CGFloor((diameter - width) / 2.0f), CGFloor((diameter + height) / 2.0f));
            CGContextClosePath(context);
            CGContextSetFillColorWithColor(context, UIColorRGBA(0xff000000, 0.45f).CGColor);
            CGContextFillPath(context);
            
            break;
        }
        default:
            break;
    }
    
    UIGraphicsPopContext();
}

@end

@interface TGMessageImageViewOverlayView ()
{
    CALayer *_blurredBackgroundLayer;
    TGMessageImageViewOverlayLayer *_contentLayer;
    TGMessageImageViewOverlayLayer *_progressLayer;
}

@end

@implementation TGMessageImageViewOverlayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.opaque = false;
        self.backgroundColor = [UIColor clearColor];
        
        _blurredBackgroundLayer = [[CALayer alloc] init];
        _blurredBackgroundLayer.frame = CGRectMake(0.0f, 0.0f, 50.0f, 50.0f);
        [self.layer addSublayer:_blurredBackgroundLayer];
        
        _contentLayer = [[TGMessageImageViewOverlayLayer alloc] init];
        _contentLayer.frame = CGRectMake(0.0f, 0.0f, 50.0f, 50.0f);
        _contentLayer.contentsScale = [UIScreen mainScreen].scale;
        [self.layer addSublayer:_contentLayer];
        
        _progressLayer = [[TGMessageImageViewOverlayLayer alloc] init];
        _progressLayer.frame = CGRectMake(0.0f, 0.0f, 50.0f, 50.0f);
        _progressLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
        _progressLayer.contentsScale = [UIScreen mainScreen].scale;
        _progressLayer.hidden = true;
        [self.layer addSublayer:_progressLayer];
    }
    return self;
}

- (void)setOverlayStyle:(TGMessageImageViewOverlayStyle)overlayStyle
{
    [_contentLayer setOverlayStyle:overlayStyle];
    [_progressLayer setOverlayStyle:overlayStyle];
}

- (void)setBlurredBackgroundImage:(UIImage *)blurredBackgroundImage
{
    _blurredBackgroundLayer.contents = (__bridge id)blurredBackgroundImage.CGImage;
}

- (void)setDownload
{
    [_contentLayer setDownload];
    [_progressLayer setNone];
    _progressLayer.hidden = true;
}

- (void)setPlay
{
    [_contentLayer setPlay];
    [_progressLayer setNone];
    _progressLayer.hidden = true;
}

- (void)setProgress:(float)progress animated:(bool)animated
{
    [self setProgress:progress cancelEnabled:true animated:animated];
}

- (void)setProgress:(float)progress cancelEnabled:(bool)cancelEnabled animated:(bool)animated
{
    _progressLayer.hidden = false;
    [_progressLayer setProgress:progress animated:animated];
    
    if (cancelEnabled)
        [_contentLayer setProgressCancel];
    else
        [_contentLayer setProgressNoCancel];
}

@end
