#import "DayNightSwitch.h"

#define onKnobColor    [UIColor colorWithRed:0.882 green:0.765 blue:0.325 alpha:1]
#define onSubviewColor [UIColor colorWithRed:0.992 green:0.875 blue:0.459 alpha:1]
#define offKnobColor   [UIColor colorWithRed:0.894 green:0.902 blue:0.788 alpha:1]
#define offSubviewColor [UIColor whiteColor]
#define offColor       [UIColor colorWithRed:0.235 green:0.255 blue:0.271 alpha:1]
#define offBorderColor [UIColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:1]
#define onColor        [UIColor colorWithRed:0.627 green:0.894 blue:0.98 alpha:1]
#define onBorderColor  [UIColor colorWithRed:0.533 green:0.769 blue:0.843 alpha:1]

@interface Knob : UIView
@property (nonatomic) BOOL on;
@property (nonatomic) BOOL expanded;
@property (nonatomic) UIView *subview;
@property (nonatomic) NSArray<UIView *> *craters;
@end

@implementation Knob

- (CGFloat)subviewMargin { return self.frame.size.height / 12; }

- (UIView *)setupSubview {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake([self subviewMargin], [self subviewMargin], self.frame.size.width - [self subviewMargin]*2, self.frame.size.height - [self subviewMargin]*2)];
    v.layer.masksToBounds = true;
    v.layer.cornerRadius = v.frame.size.height/2;
    v.backgroundColor = offSubviewColor;
    for (UIView *c in [self setupCraters]) { [v addSubview:c]; }
    self.subview = v;
    return v;
}

- (NSArray *)setupCraters {
    CGFloat w = self.frame.size.width, h = self.frame.size.height;
    UIView *a = [[UIView alloc] initWithFrame:CGRectMake(0, h*0.1, w*0.2, w*0.2)];
    UIView *b = [[UIView alloc] initWithFrame:CGRectMake(w*0.5, 0, w*0.3, w*0.3)];
    UIView *c = [[UIView alloc] initWithFrame:CGRectMake(w*0.4, h*0.5, w*0.25, w*0.25)];
    for (UIView *v in @[a,b,c]) {
        v.backgroundColor = offSubviewColor; v.layer.masksToBounds = YES;
        v.layer.cornerRadius = v.frame.size.height/2;
        v.layer.borderColor = offKnobColor.CGColor; v.layer.borderWidth = [self subviewMargin];
    }
    self.craters = @[a,b,c]; return self.craters;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame]; self.on = NO; self.expanded = NO;
    self.layer.masksToBounds = YES; self.layer.cornerRadius = self.frame.size.height/2;
    self.backgroundColor = offKnobColor;
    [self addSubview:[self setupSubview]];
    [self addObserver:self forKeyPath:@"on" options:0 context:nil];
    [self addObserver:self forKeyPath:@"expanded" options:0 context:nil];
    return self;
}

- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)o change:(NSDictionary *)c context:(void *)ctx {
    if ([kp isEqualToString:@"on"]) {
        [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.backgroundColor = self.on ? onKnobColor : offKnobColor;
            self.subview.backgroundColor = self.on ? onSubviewColor : offSubviewColor;
        } completion:nil];
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.subview.transform = CGAffineTransformMakeRotation(M_PI * (self.on ? 0.2 : -0.2));
        } completion:nil];
    } else if ([kp isEqualToString:@"expanded"]) {
        CGFloat nw = self.frame.size.height * (self.expanded ? 1.25 : 1);
        CGFloat nx = self.on ? self.superview.frame.size.width - nw - [(DayNightSwitch *)self.superview knobMargin] : self.frame.origin.x;
        [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.frame = CGRectMake(nx, self.frame.origin.y, nw, self.frame.size.height);
            self.subview.center = CGPointMake(self.on ? self.frame.size.width - self.frame.size.height/2 : self.frame.size.height/2, self.subview.center.y);
            for (UIView *v in self.craters) { v.alpha = self.on ? 0 : 1; }
        } completion:nil];
    }
}
@end

@interface DayNightSwitch ()
@property (nonatomic) Knob *knob;
@property (nonatomic) BOOL moved, dragging;
@end

@implementation DayNightSwitch

- (CGFloat)borderWidth { return self.frame.size.height/7; }
- (CGFloat)knobMargin { return self.frame.size.height/10; }

- (Knob *)setupKnob {
    CGFloat w = self.frame.size.height - [self knobMargin]*2;
    Knob *v = [[Knob alloc] initWithFrame:CGRectMake([self knobMargin], [self knobMargin], w, w)];
    self.knob = v; return v;
}

- (NSArray *)setupBorders {
    CAShapeLayer *b1 = [CAShapeLayer layer], *b2 = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0,self.frame.size.width,self.frame.size.height) cornerRadius:self.frame.size.height/2];
    b1.path = b2.path = path.CGPath;
    b1.fillColor = b2.fillColor = [UIColor clearColor].CGColor;
    b1.strokeColor = onBorderColor.CGColor; b1.lineWidth = [self borderWidth]; self.onBorder = b1;
    b2.strokeColor = offBorderColor.CGColor; b2.lineWidth = [self borderWidth]; self.offBorder = b2;
    return @[b1,b2];
}

- (NSArray *)setupStars {
    CGFloat w = self.frame.size.width, h = self.frame.size.height, x = h*0.05;
    NSArray *frames = @[
        [NSValue valueWithCGRect:CGRectMake(w*0.5, h*0.16, x, x)],
        [NSValue valueWithCGRect:CGRectMake(w*0.62, h*0.33, x*0.6, x*0.6)],
        [NSValue valueWithCGRect:CGRectMake(w*0.7, h*0.15, x, x)],
        [NSValue valueWithCGRect:CGRectMake(w*0.83, h*0.39, x*1.4, x*1.4)],
        [NSValue valueWithCGRect:CGRectMake(w*0.7, h*0.54, x*0.8, x*0.8)],
        [NSValue valueWithCGRect:CGRectMake(w*0.52, h*0.73, x*1.3, x*1.3)],
        [NSValue valueWithCGRect:CGRectMake(w*0.82, h*0.66, x*1.1, x*1.1)],
    ];
    NSMutableArray *stars = [NSMutableArray array];
    for (NSValue *v in frames) {
        UIView *s = [[UIView alloc] initWithFrame:v.CGRectValue];
        s.layer.masksToBounds = YES; s.layer.cornerRadius = s.frame.size.height/2;
        s.backgroundColor = [UIColor whiteColor];
        [stars addObject:s];
    }
    self.stars = stars; return stars;
}

- (UIImageView *)setupCloud {
    UIImageView *v = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width/3, self.frame.size.height*0.4, self.frame.size.width/3, self.frame.size.width*0.23)];
    v.transform = CGAffineTransformMakeScale(0,0); self.cloud = v; return v;
}

- (void)proccessTouches:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.moved) { self.on = !self.on; return; }
    CGFloat x = [touches.allObjects.lastObject locationInView:self].x;
    if (x > self.frame.size.width/2 && !self.on) self.on = YES;
    else if (x < self.frame.size.width/2 && self.on) self.on = NO;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { self.dragging = YES; self.knob.expanded = YES; }
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { self.moved = YES; [self proccessTouches:touches withEvent:event]; }
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self proccessTouches:touches withEvent:event]; self.knob.expanded = NO; self.dragging = NO; self.moved = NO; }
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self touchesEnded:touches withEvent:event]; }

- (instancetype)initWithCenter:(CGPoint)center {
    CGFloat h = 30, w = h*1.75;
    self = [super initWithFrame:CGRectMake(center.x-w/2, center.y-h/2, w, h)];
    [self commonInit]; return self;
}

- (void)commonInit {
    self.moved = NO; self.dragging = NO;
    self.layer.masksToBounds = YES; self.layer.cornerRadius = self.frame.size.height/2;
    self.backgroundColor = offColor;
    for (id l in [self setupBorders]) { [self.layer addSublayer:l]; }
    for (UIView *v in [self setupStars]) { [self addSubview:v]; }
    [self addSubview:[self setupKnob]];
    [self addSubview:[self setupCloud]];
    [self addObserver:self forKeyPath:@"on" options:0 context:nil];
}
- (instancetype)initWithCoder:(NSCoder *)d { self = [super initWithCoder:d]; [self commonInit]; return self; }
- (instancetype)initWithFrame:(CGRect)f { self = [super initWithFrame:f]; [self commonInit]; return self; }

- (void)observeValueForKeyPath:(NSString *)kp ofObject:(id)o change:(NSDictionary *)c context:(void *)ctx {
    if ([kp isEqualToString:@"on"]) {
        if (self.changeAction) self.changeAction(self.on);
        self.knob.on = self.on;
        [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            CGFloat kr = self.knob.frame.size.width/2;
            if (self.on) {
                self.knob.center = CGPointMake(self.frame.size.width - kr - [self knobMargin], self.knob.center.y);
                self.backgroundColor = onColor; self.offBorder.strokeStart = 1.0;
                self.cloud.transform = CGAffineTransformIdentity;
            } else {
                self.knob.center = CGPointMake(kr + [self knobMargin], self.knob.center.y);
                self.backgroundColor = offColor; self.offBorder.strokeEnd = 1.0;
                self.cloud.transform = CGAffineTransformMakeScale(0,0);
            }
            for (int i = 0; i < self.stars.count; i++) {
                UIView *star = self.stars[i]; star.alpha = self.on ? 0 : 1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1*i*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    star.transform = CGAffineTransformMakeScale(1.5,1.5);
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        star.transform = CGAffineTransformIdentity;
                    });
                });
            }
        } completion:^(BOOL f) {
            if (self.on) { self.offBorder.strokeStart = 0.0; self.offBorder.strokeEnd = 0.0; }
            else { self.offBorder.strokeStart = 0.0; self.offBorder.strokeEnd = 1.0; }
        }];
    }
}
@end
