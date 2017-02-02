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



@interface Sprite : NSObject

- (void) prerender;
- (void) render:(const float *)model_view_matrix;

@end
