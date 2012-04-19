//
//  CPNinja.m
//  SwipeNinja
//
//  Created by Ryan Lesko on 4/15/12.
//  Copyright (c) 2012 University of Miami. All rights reserved.
//

#import "CPNinja.h"

@implementation CPNinja

@synthesize groundShapes;

static cpBool begin(cpArbiter *arb, cpSpace *space, void *ignore) {
    CP_ARBITER_GET_SHAPES(arb, ninjaShape, groundShape);
    CPNinja *ninja = (CPNinja *)ninjaShape->data;
    cpVect n = cpArbiterGetNormal(arb, 0);
    if (n.y < 0.0f) {
        cpArray *groundShapes = ninja.groundShapes;
        cpArrayPush(groundShapes, groundShape);
    }
    return cpTrue;
}

static cpBool preSolve(cpArbiter *arb, cpSpace *space, void *ignore) {
    if(cpvdot(cpArbiterGetNormal(arb, 0), ccp(0, -1)) < 0) {
        return cpFalse;
    }
    return cpTrue;
}

static void separate(cpArbiter *arb, cpSpace *space, void *ignore) {
    CP_ARBITER_GET_SHAPES(arb, ninjaShape, groundShape);
    CPNinja *ninja = (CPNinja *)ninjaShape->data;
    cpArrayDeleteObj(ninja.groundShapes, groundShape);
}

-(id)initWithLocation:(CGPoint)location space:(cpSpace *)theSpace groundBody:(cpBody *)groundBody {
    if ((self = [super initWithSpriteFrameName:@"Ninja.png"])) {
        CGSize size = CGSizeMake(30, 30);
        self.anchorPoint = ccp(0.5, 15/self.contentSize.height);
        [self addBoxBodyAndShapeWithLocation:location size:size space:theSpace mass:1.0 e:0.0 u:0.5 collisionType:kCollisionTypeNinja canRotate:TRUE];
        groundShapes = cpArrayNew(0);
        cpSpaceAddCollisionHandler(space, kCollisionTypeNinja, kCollisionTypeGround, begin, preSolve, NULL, separate, NULL);
    }
    return self;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    if (groundShapes->num > 0) {
        jumpStartTime = CACurrentMediaTime();
    }
    return TRUE;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    jumpStartTime = 0;
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    accelerationFraction = acceleration.y*2;
    if (accelerationFraction < -1) {
        accelerationFraction = -1;
    } else if (accelerationFraction > 1) {
        accelerationFraction = 1;
    }
    
    if ([[CCDirector sharedDirector] deviceOrientation] == UIDeviceOrientationLandscapeLeft) {
        accelerationFraction *= -1;
    }
}


-(void)updateStateWithDeltaTime:(ccTime)deltaTime andListOfGameObjects:(CCArray *)listOfGameObjects {
    
    CGPoint oldPosition = self.position;
    [super updateStateWithDeltaTime:deltaTime andListOfGameObjects:listOfGameObjects];
    float jumpFactor = 150.0;
    CGPoint newVel = body->v;
    
    if (groundShapes->num == 0) {
        newVel = ccp(jumpFactor*accelerationFraction, body->v.y);
    }
    
    double timeJumping = CACurrentMediaTime() - jumpStartTime;
    if (jumpStartTime != 0 && timeJumping < 0.25) {
        newVel.y = jumpFactor*2;
    }
    cpBodySetVel(body, newVel);
    
    if (groundShapes->num > 0) {
        if (ABS(accelerationFraction) < 0.05) {
            accelerationFraction = 0;
            shape->surface_v = ccp(0, 0);
        } else {
            float maxSpeed = 200.0f;
            shape->surface_v = ccp(-maxSpeed*accelerationFraction, 0);
            cpBodyActivate(body);
        }
    } else {
        shape->surface_v = cpvzero;
    }
    
    float margin = 70;
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    if (body->p.x < margin) {
        cpBodySetPos(body, ccp(margin, body->p.y));
    }
    
    if (body->p.x > winSize.width - margin) {
        cpBodySetPos(body, ccp(winSize.width - margin, body->p.y));
    }
    
    if(ABS(accelerationFraction) > 0.05) { 
        double diff = CACurrentMediaTime() - lastFlip;        
        if (diff > 0.1) {
            lastFlip = CACurrentMediaTime();
            if (oldPosition.x > self.position.x) {
                self.flipX = YES;
            } else {
                self.flipX = NO;
            }
        }
    }
}

@end