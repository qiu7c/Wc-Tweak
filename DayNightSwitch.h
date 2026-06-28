#import <UIKit/UIKit.h>

@interface DayNightSwitch : UIView
@property (nonatomic, copy, nullable) void (^changeAction)(BOOL);
@property (nonatomic) BOOL on;
@property (nonatomic, nonnull) CAShapeLayer *offBorder;
@property (nonatomic, nonnull) CAShapeLayer *onBorder;
@property (nonatomic, nullable) NSArray<UIView *> *stars;
@property (nonatomic, nonnull) UIImageView *cloud;
- (CGFloat)knobMargin;
- (nonnull instancetype)initWithCenter:(CGPoint)center;
@end
