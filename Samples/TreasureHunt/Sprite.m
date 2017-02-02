//
//  Sprite.m
//  TreasureHunt
//
//  Created by Kevin Leung on 2/2/2017.
//
//

#import "Sprite.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>


// https://www.raywenderlich.com/50398/opengl-es-transformations-gestures
static const float kVertices[NUM_VERTICES] = {
    -0.5f, 0.5f, 0,
    -0.5f, -0.5f, 0,
    0.5f, 0.5f, 0,
    -0.5f, -0.5f, 0,
    0.5f, -0.5f, 0,
    0.5f, 0.5f, 0,
};

@implementation Sprite {
    
    
    GLuint program;
    GLint vertex_attrib;
    GLint position_uniform;
    GLint mvp_matrix_uniform;
    GLuint vertex_buffer;
}

@synthesize transformation = _transformation;

- (instancetype) init {
    self = [super init];
    _x = _y = _z = 0;
    _rotationX = _rotationY = _rotationZ = 0;
    _width = _height = 10;
    
    _transformation = GLKMatrix4Identity;
    _transformation = GLKMatrix4Translate(_transformation, _x, _y, _z);
    
    [self updateVertices];
    
    
    
    
    return self;
}


- (void) prerender {
    
}

- (void) render:(const float *)model_view_matrix {
    
}

- (float) x {
    return _x;
}

- (void) setX:(float) v {
    if(_x != v) {
        _x = v;
        _transformation = GLKMatrix4Translate(GLKMatrix4Identity, _x, _y, _z);
    }
}

- (float) y {
    return _y;
}

- (void) setY:(float) v {
    if(_y != v) {
        _y = v;
        _transformation = GLKMatrix4Translate(GLKMatrix4Identity, _x, _y, _z);
    }

}

- (float) z {
    return _z;
}

- (void) setZ:(float) v {
    if(_z != v) {
        _z = v;
        _transformation = GLKMatrix4Translate(GLKMatrix4Identity, _x, _y, _z);
    }

}

- (float) rotationX {
    return _rotationX;
}

- (void) setRotationX:(float) v {
    if(_rotationX != v) {
        _transformation = GLKMatrix4RotateX(_transformation, v - _rotationX);
        _rotationX = v;
    }
}

- (float) rotationY {
    return _rotationY;
}

- (void) setRotationY:(float) v {
    if(_rotationY != v) {
        _transformation = GLKMatrix4RotateY(_transformation, v - _rotationY);
        _rotationY = v;
    }
}

- (float) rotationZ {
    return _rotationZ;
}

- (void) setRotationZ:(float) v {
    if(_rotationZ != v) {
        _transformation = GLKMatrix4RotateX(_transformation, v - _rotationZ);
        _rotationZ = v;
    }
}

- (float) width {
    return _width;
}

- (void) setWidth:(float) v {
    if(_width != v) {
        _width = v;
        [self updateVertices];
    }
    
}

- (float) height {
    return _height;
}

- (void) setHeight:(float) v {
    if(_height != v) {
        _height = v;
        [self updateVertices];
    }
}

- (void) updateVertices {
    NSLog(@"updateVVVV, %f, %f", _width, _height);
    for(int i = 0; i < NUM_VERTICES; i += 3) {
        _vertices[i] = kVertices[i] * _width;
        _vertices[i + 1] = kVertices[i + 1] * _height;
    }
}

@end
