//
//  AXAnimationChain.m
//  AXAnimationChain
//
//  Created by devedbox on 2016/12/10.
//  Copyright © 2016年 devedbox. All rights reserved.
//

#import "AXChainAnimator.h"
#import "AXChainAnimator+Block.h"
NS_ASSUME_NONNULL_BEGIN
@interface AXChainAnimator ()
{
    @protected
    /// Is animations in traansaction.
    BOOL _inTransaction;
}
/// Next to animation.
@property(strong, nonatomic) CAAnimation *nextToAnimation;
/// Set animation object to the animator.
- (void)_setAnimation:(CAAnimation *)animation;
@end

@implementation AXChainAnimator
@synthesize animation = _animation;
+ (instancetype)animatorWithAnimation:(CAAnimation *)animation {
    id obj = [[self.class alloc] init];
    NSAssert([obj respondsToSelector:@selector(_setAnimation:)], @"Object cannot be created.");
    [obj performSelector:@selector(_setAnimation:) withObject:animation];
    return obj;
}

#pragma mark - ChainHandler.
- (nullable instancetype)beginWith:(nonnull AXChainAnimator *)animator {
    [self _setAnimation:animator.animation];
    return self;
}

- (nullable instancetype)nextTo:(nonnull AXChainAnimator *)animator {
    AXChainAnimator *superAnimator = animator.superAnimator?:animator;
    AXChainAnimator *superSuperAnimator = superAnimator;
    while (superAnimator) {
        superAnimator = superAnimator.superAnimator;
        if (superAnimator) {
            superSuperAnimator = superAnimator;
            if (superAnimator == self) {
                return animator;
            }
        }
    }
    _childAnimator = superSuperAnimator;
    _childAnimator.superAnimator = self;
    return _childAnimator;
}

- (nullable instancetype)combineWith:(nonnull AXChainAnimator *)animator {
    NSMutableArray *animators = [_combinedAnimators mutableCopy];
    if (!animators) animators = [NSMutableArray array];
    AXChainAnimator *superAnimator = animator.superAnimator?:animator;
    AXChainAnimator *superSuperAnimator = superAnimator;
    while (superAnimator) {
        superAnimator = superAnimator.superAnimator;
        if (superAnimator) {
            superSuperAnimator = superAnimator;
        }
    }
    [animators addObject:superSuperAnimator];
    animator.superAnimator = self;
    _combinedAnimators = [NSSet setWithArray:animators].allObjects;
    return animator;
}

#pragma mark - Getters.
- (AXBasicChainAnimator *)basic {
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    AXBasicChainAnimator *basic = [AXBasicChainAnimator animatorWithAnimation:animation];
    basic.animatedView = _animatedView;
    return basic;
}

- (AXKeyframeChainAnimator *)keyframe {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    AXKeyframeChainAnimator *keyframe = [AXKeyframeChainAnimator animatorWithAnimation:animation];
    keyframe.animatedView = _animatedView;
    return keyframe;
}

- (AXSpringChainAnimator *)spring {
    CASpringAnimation *animation = [CASpringAnimation animation];
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    AXSpringChainAnimator *spring = [AXSpringChainAnimator animatorWithAnimation:animation];
    spring.animatedView = _animatedView;
    return spring;
}

- (AXTransitionChainAnimator *)transition {
    CATransition *animation = [CATransition animation];
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    AXTransitionChainAnimator *transition = [AXTransitionChainAnimator animatorWithAnimation:animation];
    transition.animatedView = _animatedView;
    return transition;
}
#pragma mark - AXAnimationChainDelegate.
- (void)start {
    NSAssert(_animatedView, @"Animation chain cannot be created because animated view is null.");
    AXChainAnimator *superAnimator = _superAnimator;
    AXChainAnimator *superSuperAnimator = _superAnimator;
    while (superAnimator) {
        superAnimator = superAnimator.superAnimator;
        if (superAnimator) {
            superSuperAnimator = superAnimator;
        }
    }
    if (superSuperAnimator) {
        [superSuperAnimator start];
    } else {
        [self _beginAnimating];
    }
}

- (void)_beginAnimating {
    if (_inTransaction) return;
    [CATransaction begin];
    _inTransaction = YES;
    [CATransaction setDisableActions:YES];
    [CATransaction setCompletionBlock:^{
        _inTransaction = NO;
    }];
    CAAnimation *animation = [self _animationGroups];
    [_animatedView.layer addAnimation:animation forKey:[NSString stringWithFormat:@"%p", self]];
    
    [CATransaction commit];
}

- (nullable instancetype)beginTime:(NSTimeInterval)beginTime {
    _animation.beginTime = beginTime;
    return self;
}

- (nullable instancetype)duration:(NSTimeInterval)duration {
    _animation.duration = duration;
    return self;
}

- (nullable instancetype)speed:(CGFloat)speed {
    _animation.speed = speed;
    return self;
}

- (nullable instancetype)timeOffset:(NSTimeInterval)timeOffset {
    _animation.timeOffset = timeOffset;
    return self;
}

- (nullable instancetype)repeatCount:(CGFloat)repeatCount {
    _animation.repeatCount = repeatCount;
    return self;
}

- (nullable instancetype)repeatDuration:(NSTimeInterval)repeatDuration {
    _animation.repeatDuration = repeatDuration;
    return self;
}

- (nullable instancetype)autoreverses {
    _animation.autoreverses = YES;
    return self;
}

- (nullable instancetype)fillMode:(NSString *)fillMode {
    _animation.fillMode = [fillMode copy];
    return self;
}

- (nullable instancetype)linear {
    _animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    return self;
}

- (nullable instancetype)easeIn {
    _animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    return self;
}

- (nullable instancetype)easeOut {
    _animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    return self;
}

- (nullable instancetype)easeInOut {
    _animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return self;
}

#pragma mark - BlockReachable.
- (AXChainAnimator *(^)(AXChainAnimator *))beginWith {
    return ^AXChainAnimator* (AXChainAnimator *animator) {
        return [self beginWith:animator];
    };
}

- (AXChainAnimator *(^)(AXChainAnimator *))nextTo {
    return ^AXChainAnimator* (AXChainAnimator *animator) {
        return [self nextTo:animator];
    };
}

- (AXChainAnimator *(^)(AXChainAnimator *))combineWith {
    return ^AXChainAnimator* (AXChainAnimator *animator) {
        return [self combineWith:animator];
    };
}

- (AXChainAnimator *(^)(NSTimeInterval))beginTime {
    return ^AXChainAnimator* (NSTimeInterval beginTime) {
        return [self beginTime:beginTime];
    };
}

- (AXChainAnimator *(^)(NSTimeInterval))duration {
    return ^AXChainAnimator* (NSTimeInterval duration) {
        return [self duration:duration];
    };
}

- (AXChainAnimator *(^)(CGFloat))speed {
    return ^AXChainAnimator* (CGFloat speed) {
        return [self speed:speed];
    };
}

- (AXChainAnimator *(^)(NSTimeInterval))timeOffset {
    return ^AXChainAnimator* (NSTimeInterval timeOffset) {
        return [self timeOffset:timeOffset];
    };
}

- (AXChainAnimator *(^)(CGFloat))repeatCount {
    return ^AXChainAnimator* (CGFloat repeatCount) {
        return [self repeatCount:repeatCount];
    };
}

- (AXChainAnimator *(^)(NSTimeInterval))repeatDuration {
    return ^AXChainAnimator* (NSTimeInterval repeatDuration) {
        return [self repeatDuration:repeatDuration];
    };
}

- (AXChainAnimator *(^)(NSString *))fillMode {
    return ^AXChainAnimator* (NSString *fillMode) {
        return [self fillMode:fillMode];
    };
}

- (dispatch_block_t)animate {
    return ^() {
        [self start];
    };
}
#pragma mark - Private.
- (void)_setAnimation:(CAAnimation *)animation {
    if (_animation == animation) return;
    _animation = [animation copy];
}

- (nonnull CAAnimation *)_animationGroups {
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.removedOnCompletion = _animation.removedOnCompletion;
    group.fillMode = _animation.fillMode;
    group.timingFunction = _animation.timingFunction;
    group.animations = @[_animation];
    group.duration = _animation.duration;
    
    [self _animationGroupsForCombinedWithGroup:&group];
    [self _animationGroupsForNextToWithGroup:&group];
    
    return group;
}

- (void)_animationGroupsForCombinedWithGroup:(CAAnimationGroup **)group {
    NSMutableArray *animations = [(*group).animations mutableCopy];
    NSTimeInterval duration = (*group).duration;
    
    for (AXChainAnimator *animator in _combinedAnimators) {
        CAAnimation *animation = [animator animation];
        [animations addObject:animation];
        duration = MAX(duration, animation.duration);
        if (animator.combinedAnimators) {
            [(*group) setAnimations:animations];
            (*group).duration = duration;
            [animator _animationGroupsForCombinedWithGroup:group];
            animations = [(*group).animations mutableCopy];
            duration = (*group).duration;
        } else if (animator.childAnimator) {
            [(*group) setAnimations:animations];
            (*group).duration = duration;
            [animator _animationGroupsForNextToWithGroup:group];
            animations = [(*group).animations mutableCopy];
            duration = (*group).duration;
        }
    }
    
    [(*group) setAnimations:animations];
    (*group).duration = duration;
}

- (void)_animationGroupsForNextToWithGroup:(CAAnimationGroup **)group {
    AXChainAnimator *animator = self.childAnimator;
    while (animator) {
        CAAnimation *nextAnimation = [animator animation];
        nextAnimation.beginTime += (*group).duration;
        (*group).duration += nextAnimation.duration + nextAnimation.beginTime;
        NSMutableArray *animations = [[(*group) animations] mutableCopy];
        [animations addObject:nextAnimation];
        (*group).animations = animations;
        animator = animator.childAnimator;
    }
}
@end

@implementation AXBasicChainAnimator
@dynamic animation;
#pragma mark - Override.

#pragma mark - Getters.
- (CABasicAnimation *)animation {
    return (CABasicAnimation *)[super animation];
}

#pragma mark - PropertyHandler.
- (nullable instancetype)property:(NSString *)property {
    NSAssert([self.animation isKindOfClass:[CAPropertyAnimation class]], @"Cannot set property: %@ to animation because animation object is not subclass of CAPropertyAnimation", property);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s+$" options:0 error:NULL];
    NSAssert(property.length != 0 && [regex matchesInString:property options:0 range:NSMakeRange(0, property.length)].count == 0, @"Property to be animated can not be null");
    [self.animation setValue:property forKeyPath:@"keyPath"];
    return self;
}

- (nullable id<AXBasicChainAnimatorDelegate>)fromValue:(id)fromValue {
    if (self.animation.byValue && self.animation.toValue) return nil;
    self.animation.fromValue = fromValue;
    return self;
}

- (nullable id<AXBasicChainAnimatorDelegate>)byValue:(id)byValue {
    if (self.animation.fromValue && self.animation.toValue) return nil;
    self.animation.byValue = byValue;
    return self;
}

- (nullable id<AXBasicChainAnimatorDelegate>)toValue:(id)toValue {
    if (self.animation.fromValue && self.animation.byValue) return nil;
    self.animation.toValue = toValue;
    return self;
}

#pragma mark - BlockReachable.
- (AXBasicChainAnimator *(^)(AXBasicChainAnimator *))beginWith {
    return ^AXBasicChainAnimator* (AXBasicChainAnimator *animator) {
        return [self beginWith:animator];
    };
}

- (AXBasicChainAnimator *(^)(AXBasicChainAnimator *))nextTo {
    return ^AXBasicChainAnimator* (AXBasicChainAnimator *animator) {
        return [self nextTo:animator];
    };
}

- (AXBasicChainAnimator *(^)(AXBasicChainAnimator *))combineWith {
    return ^AXBasicChainAnimator* (AXBasicChainAnimator *animator) {
        return [self combineWith:animator];
    };
}

- (AXBasicChainAnimator *(^)(NSTimeInterval))beginTime {
    return ^AXBasicChainAnimator* (NSTimeInterval beginTime) {
        return [self beginTime:beginTime];
    };
}

- (AXBasicChainAnimator *(^)(NSTimeInterval))duration {
    return ^AXBasicChainAnimator* (NSTimeInterval duration) {
        return [self duration:duration];
    };
}

- (AXBasicChainAnimator *(^)(CGFloat))speed {
    return ^AXBasicChainAnimator* (CGFloat speed) {
        return [self speed:speed];
    };
}

- (AXBasicChainAnimator *(^)(NSTimeInterval))timeOffset {
    return ^AXBasicChainAnimator* (NSTimeInterval timeOffset) {
        return [self timeOffset:timeOffset];
    };
}

- (AXBasicChainAnimator *(^)(CGFloat))repeatCount {
    return ^AXBasicChainAnimator* (CGFloat repeatCount) {
        return [self repeatCount:repeatCount];
    };
}

- (AXBasicChainAnimator *(^)(NSTimeInterval))repeatDuration {
    return ^AXBasicChainAnimator* (NSTimeInterval repeatDuration) {
        return [self repeatDuration:repeatDuration];
    };
}

- (AXBasicChainAnimator *(^)(NSString *))fillMode {
    return ^AXBasicChainAnimator* (NSString *fillMode) {
        return [self fillMode:fillMode];
    };
}

- (AXBasicChainAnimator *(^)(NSString *))property {
    return ^AXBasicChainAnimator* (NSString *property) {
        return [self property:property];
    };
}

- (AXBasicChainAnimator *(^)(id))fromValue {
    return ^AXBasicChainAnimator* (id fromValue) {
        return [self fromValue:fromValue];
    };
}

- (AXBasicChainAnimator *(^)(id))toValue {
    return ^AXBasicChainAnimator* (id toValue) {
        return [self toValue:toValue];
    };
}

- (AXBasicChainAnimator *(^)(id))byValue {
    return ^AXBasicChainAnimator* (id byValue) {
        return [self byValue:byValue];
    };
}
@end

@implementation AXKeyframeChainAnimator
@dynamic animation;
#pragma mark - Getters.
- (CAKeyframeAnimation *)animation {
    return (CAKeyframeAnimation *)[super animation];
}

#pragma mark - PropertiesHandler.
- (nullable instancetype)property:(NSString *)property {
    NSAssert([self.animation isKindOfClass:[CAPropertyAnimation class]], @"Cannot set property: %@ to animation because animation object is not subclass of CAPropertyAnimation", property);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s+$" options:0 error:NULL];
    NSAssert(property.length != 0 && [regex matchesInString:property options:0 range:NSMakeRange(0, property.length)].count == 0, @"Property to be animated can not be null");
    [self.animation setValue:property forKeyPath:@"keyPath"];
    return self;
}

- (nullable instancetype)values:(nullable NSArray<id> *)values {
    self.animation.values = values;
    return self;
}

- (nullable instancetype)path:(nullable UIBezierPath *)path {
    self.animation.path = path.CGPath;
    return self;
}

- (nullable instancetype)keyTimes:(nullable NSArray<NSNumber *> *)keyTimes {
    self.animation.keyTimes = keyTimes;
    return self;
}

- (nullable instancetype)timingFunctions:(nullable NSArray<CAMediaTimingFunction *> *)timingFunctions {
    self.animation.timingFunctions = timingFunctions;
    return self;
}

- (nullable instancetype)calculationMode:(NSString *)calculationMode {
    self.animation.calculationMode = calculationMode;
    return self;
}

- (nullable instancetype)tensionValues:(nullable NSArray<NSNumber *> *)tensionValues {
    self.animation.tensionValues = tensionValues;
    return self;
}

- (nullable instancetype)continuityValues:(nullable NSArray<NSNumber *> *)continuityValues {
    self.animation.continuityValues = continuityValues;
    return self;
}

- (nullable instancetype)biasValues:(nullable NSArray<NSNumber *> *)biasValues {
    self.animation.biasValues = biasValues;
    return self;
}

- (nullable instancetype)rotationMode:(nullable NSString *)rotationMode {
    self.animation.rotationMode = rotationMode;
    return self;
}

#pragma mark - BlockReachable.
- (AXKeyframeChainAnimator *(^)(AXKeyframeChainAnimator *))beginWith {
    return ^AXKeyframeChainAnimator* (AXKeyframeChainAnimator *animator) {
        return [self beginWith:animator];
    };
}

- (AXKeyframeChainAnimator *(^)(AXKeyframeChainAnimator *))nextTo {
    return ^AXKeyframeChainAnimator* (AXKeyframeChainAnimator *animator) {
        return [self nextTo:animator];
    };
}

- (AXKeyframeChainAnimator *(^)(AXKeyframeChainAnimator *))combineWith {
    return ^AXKeyframeChainAnimator* (AXKeyframeChainAnimator *animator) {
        return [self combineWith:animator];
    };
}

- (AXKeyframeChainAnimator *(^)(NSTimeInterval))beginTime {
    return ^AXKeyframeChainAnimator* (NSTimeInterval beginTime) {
        return [self beginTime:beginTime];
    };
}

- (AXKeyframeChainAnimator *(^)(NSTimeInterval))duration {
    return ^AXKeyframeChainAnimator* (NSTimeInterval duration) {
        return [self duration:duration];
    };
}

- (AXKeyframeChainAnimator *(^)(CGFloat))speed {
    return ^AXKeyframeChainAnimator* (CGFloat speed) {
        return [self speed:speed];
    };
}

- (AXKeyframeChainAnimator *(^)(NSTimeInterval))timeOffset {
    return ^AXKeyframeChainAnimator* (NSTimeInterval timeOffset) {
        return [self timeOffset:timeOffset];
    };
}

- (AXKeyframeChainAnimator *(^)(CGFloat))repeatCount {
    return ^AXKeyframeChainAnimator* (CGFloat repeatCount) {
        return [self repeatCount:repeatCount];
    };
}

- (AXKeyframeChainAnimator *(^)(NSTimeInterval))repeatDuration {
    return ^AXKeyframeChainAnimator* (NSTimeInterval repeatDuration) {
        return [self repeatDuration:repeatDuration];
    };
}

- (AXKeyframeChainAnimator *(^)(NSString *))fillMode {
    return ^AXKeyframeChainAnimator* (NSString *fillMode) {
        return [self fillMode:fillMode];
    };
}

- (AXKeyframeChainAnimator *(^)(NSString *))property {
    return ^AXKeyframeChainAnimator* (NSString *property) {
        return [self property:property];
    };
}

- (AXKeyframeChainAnimator *(^)(NSArray<id> *))values {
    return ^AXKeyframeChainAnimator* (NSArray<id> *values) {
        return [self values:values];
    };
}

- (AXKeyframeChainAnimator *(^)(UIBezierPath *))path {
    return ^AXKeyframeChainAnimator* (UIBezierPath *path) {
        return [self path:path];
    };
}

- (AXKeyframeChainAnimator *(^)(NSArray<NSNumber *> *))keyTimes {
    return ^AXKeyframeChainAnimator* (NSArray<NSNumber *> *keyTimes) {
        return [self keyTimes:keyTimes];
    };
}

- (AXKeyframeChainAnimator *(^)(NSArray<CAMediaTimingFunction *> *))timingFunctions {
    return ^AXKeyframeChainAnimator* (NSArray<CAMediaTimingFunction *> *timingFunctions) {
        return [self timingFunctions:timingFunctions];
    };
}

- (AXKeyframeChainAnimator *(^)(NSString *))calculationMode {
    return ^AXKeyframeChainAnimator* (NSString *calculationMode) {
        return [self calculationMode:calculationMode];
    };
}

- (AXKeyframeChainAnimator *(^)(NSArray<NSNumber *> *))tensionValues {
    return ^AXKeyframeChainAnimator* (NSArray<NSNumber *> *tensionValues) {
        return [self tensionValues:tensionValues];
    };
}

- (AXKeyframeChainAnimator *(^)(NSArray<NSNumber *> *))continuityValues {
    return ^AXKeyframeChainAnimator* (NSArray<NSNumber *> *continuityValues) {
        return [self continuityValues:continuityValues];
    };
}

- (AXKeyframeChainAnimator *(^)(NSArray<NSNumber *> *))biasValues {
    return ^AXKeyframeChainAnimator* (NSArray<NSNumber *> *biasValues) {
        return [self biasValues:biasValues];
    };
}

- (AXKeyframeChainAnimator *(^)(NSString *))rotationMode {
    return ^AXKeyframeChainAnimator* (NSString *rotationMode) {
        return [self rotationMode:rotationMode];
    };
}
@end

@implementation AXSpringChainAnimator
@dynamic animation;
#pragma mark - Override.
- (nullable instancetype)duration:(NSTimeInterval)duration {
    return self;
}
#pragma mark - Getters.
- (CASpringAnimation *)animation {
    return (CASpringAnimation *)[super animation];
}

#pragma mark - PropertiesHandler.
- (nullable instancetype)mass:(CGFloat)mass {
    self.animation.mass = mass;
    return self;
}

- (nullable instancetype)stiffness:(CGFloat)stiffness {
    self.animation.stiffness = stiffness;
    return self;
}

- (nullable instancetype)damping:(CGFloat)damping {
    self.animation.damping = damping;
    return self;
}

- (nullable instancetype)initialVelocity:(CGFloat)initialVelocity {
    self.animation.initialVelocity = initialVelocity;
    return self;
}

#pragma mark - BlockReachable.
- (AXSpringChainAnimator *(^)(AXSpringChainAnimator *))beginWith {
    return ^AXSpringChainAnimator* (AXSpringChainAnimator *animator) {
        return [self beginWith:animator];
    };
}

- (AXSpringChainAnimator *(^)(AXSpringChainAnimator *))nextTo {
    return ^AXSpringChainAnimator* (AXSpringChainAnimator *animator) {
        return [self nextTo:animator];
    };
}

- (AXSpringChainAnimator *(^)(AXSpringChainAnimator *))combineWith {
    return ^AXSpringChainAnimator* (AXSpringChainAnimator *animator) {
        return [self combineWith:animator];
    };
}

- (AXSpringChainAnimator *(^)(NSTimeInterval))beginTime {
    return ^AXSpringChainAnimator* (NSTimeInterval beginTime) {
        return [self beginTime:beginTime];
    };
}

- (AXSpringChainAnimator *(^)(NSTimeInterval))duration {
    return ^AXSpringChainAnimator* (NSTimeInterval duration) {
        return [self duration:duration];
    };
}

- (AXSpringChainAnimator *(^)(CGFloat))speed {
    return ^AXSpringChainAnimator* (CGFloat speed) {
        return [self speed:speed];
    };
}

- (AXSpringChainAnimator *(^)(NSTimeInterval))timeOffset {
    return ^AXSpringChainAnimator* (NSTimeInterval timeOffset) {
        return [self timeOffset:timeOffset];
    };
}

- (AXSpringChainAnimator *(^)(CGFloat))repeatCount {
    return ^AXSpringChainAnimator* (CGFloat repeatCount) {
        return [self repeatCount:repeatCount];
    };
}

- (AXSpringChainAnimator *(^)(NSTimeInterval))repeatDuration {
    return ^AXSpringChainAnimator* (NSTimeInterval repeatDuration) {
        return [self repeatDuration:repeatDuration];
    };
}

- (AXSpringChainAnimator *(^)(NSString *))fillMode {
    return ^AXSpringChainAnimator* (NSString *fillMode) {
        return [self fillMode:fillMode];
    };
}

- (AXSpringChainAnimator *(^)(NSString *))property {
    return ^AXSpringChainAnimator* (NSString *property) {
        return [self property:property];
    };
}

- (AXSpringChainAnimator *(^)(id))fromValue {
    return ^AXSpringChainAnimator* (id fromValue) {
        return [self fromValue:fromValue];
    };
}

- (AXSpringChainAnimator *(^)(id))toValue {
    return ^AXSpringChainAnimator* (id toValue) {
        return [self toValue:toValue];
    };
}

- (AXSpringChainAnimator *(^)(id))byValue {
    return ^AXSpringChainAnimator* (id byValue) {
        return [self byValue:byValue];
    };
}

- (AXSpringChainAnimator *(^)(CGFloat))mass {
    return ^AXSpringChainAnimator* (CGFloat mass) {
        return [self mass:mass];
    };
}

- (AXSpringChainAnimator *(^)(CGFloat))stiffness {
    return ^AXSpringChainAnimator* (CGFloat stiffness) {
        return [self stiffness:stiffness];
    };
}

- (AXSpringChainAnimator *(^)(CGFloat))damping {
    return ^AXSpringChainAnimator* (CGFloat damping) {
        return [self damping:damping];
    };
}

- (AXSpringChainAnimator *(^)(CGFloat))initialVelocity {
    return ^AXSpringChainAnimator* (CGFloat initialVelocity) {
        return [self initialVelocity:initialVelocity];
    };
}
@end

@implementation AXTransitionChainAnimator
@dynamic animation;
#pragma mark - Override.
#pragma mark - Getters.
- (CATransition *)animation {
    return (CATransition *)[super animation];
}

#pragma mark - PropertiesHandler.
- (nullable instancetype)type:(NSString *)type {
    self.animation.type = type;
    return self;
}

- (nullable instancetype)subtype:(NSString *)subtype {
    self.animation.subtype = subtype;
    return self;
}

- (nullable instancetype)startProgress:(CGFloat)startProgress {
    self.animation.startProgress = startProgress;
    return self;
}

- (nullable instancetype)endProgress:(CGFloat)endProgress {
    self.animation.endProgress = endProgress;
    return self;
}

- (nullable instancetype)filter:(id)filter {
    self.animation.filter = filter;
    return self;
}

#pragma mark - BlockReachable.
- (AXTransitionChainAnimator *(^)(AXTransitionChainAnimator *))beginWith {
    return ^AXTransitionChainAnimator* (AXTransitionChainAnimator *animator) {
        return [self beginWith:animator];
    };
}

- (AXTransitionChainAnimator *(^)(AXTransitionChainAnimator *))nextTo {
    return ^AXTransitionChainAnimator* (AXTransitionChainAnimator *animator) {
        return [self nextTo:animator];
    };
}

- (AXTransitionChainAnimator *(^)(AXTransitionChainAnimator *))combineWith {
    return ^AXTransitionChainAnimator* (AXTransitionChainAnimator *animator) {
        return [self combineWith:animator];
    };
}

- (AXTransitionChainAnimator *(^)(NSTimeInterval))beginTime {
    return ^AXTransitionChainAnimator* (NSTimeInterval beginTime) {
        return [self beginTime:beginTime];
    };
}

- (AXTransitionChainAnimator *(^)(NSTimeInterval))duration {
    return ^AXTransitionChainAnimator* (NSTimeInterval duration) {
        return [self duration:duration];
    };
}

- (AXTransitionChainAnimator *(^)(CGFloat))speed {
    return ^AXTransitionChainAnimator* (CGFloat speed) {
        return [self speed:speed];
    };
}

- (AXTransitionChainAnimator *(^)(NSTimeInterval))timeOffset {
    return ^AXTransitionChainAnimator* (NSTimeInterval timeOffset) {
        return [self timeOffset:timeOffset];
    };
}

- (AXTransitionChainAnimator *(^)(CGFloat))repeatCount {
    return ^AXTransitionChainAnimator* (CGFloat repeatCount) {
        return [self repeatCount:repeatCount];
    };
}

- (AXTransitionChainAnimator *(^)(NSTimeInterval))repeatDuration {
    return ^AXTransitionChainAnimator* (NSTimeInterval repeatDuration) {
        return [self repeatDuration:repeatDuration];
    };
}

- (AXTransitionChainAnimator *(^)(NSString *))fillMode {
    return ^AXTransitionChainAnimator* (NSString *fillMode) {
        return [self fillMode:fillMode];
    };
}

- (AXTransitionChainAnimator *(^)(NSString *))type {
    return ^AXTransitionChainAnimator* (NSString *type) {
        return [self type:type];
    };
}

- (AXTransitionChainAnimator *(^)(NSString *))subtype {
    return ^AXTransitionChainAnimator* (NSString *subtype) {
        return [self subtype:subtype];
    };
}

- (AXTransitionChainAnimator *(^)(CGFloat))startProgress {
    return ^AXTransitionChainAnimator* (CGFloat startProgress) {
        return [self startProgress:startProgress];
    };
}

- (AXTransitionChainAnimator *(^)(CGFloat))endProgress {
    return ^AXTransitionChainAnimator* (CGFloat endProgress) {
        return [self endProgress:endProgress];
    };
}

- (AXTransitionChainAnimator *(^)(id))filter {
    return ^AXTransitionChainAnimator* (id filter) {
        return [self filter:filter];
    };
}
@end
NS_ASSUME_NONNULL_END