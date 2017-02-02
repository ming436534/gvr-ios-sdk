//
//  Sprite.h
//  TreasureHunt
//
//  Created by Kevin Leung on 2/2/2017.
//
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import "GVRHeadTransform.h"


#define NUM_VERTICES 18

@interface Sprite : NSObject{
    float _x;
    float _y;
    float _z;
    float _rotationX;
    float _rotationY;
    float _rotationZ;
    float _width;
    float _height;
    
    GLfloat _vertices[NUM_VERTICES];
    GLKMatrix4 _transformation;
}

- (void) prerender:(GVRHeadTransform *)headTransform;
- (void) render:(const float *)model_view_matrix;
- (void) destroy;

@property float x;
@property float y;
@property float z;
@property float rotationX;
@property float rotationY;
@property float rotationZ;
@property float width;
@property float height;
@property GLKMatrix4 transformation;

@end
