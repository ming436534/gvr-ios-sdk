//
//  VideoSprite.m
//  TreasureHunt
//
//  Created by Kevin Leung on 2/2/2017.
//
//

#define NUM_VERTICES 18

#import "VideoSprite.h"
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

static GLuint LoadShader(GLenum type, const char *shader_src) {
    GLint compiled = 0;
    
    // Create the shader object
    const GLuint shader = glCreateShader(type);
    if (shader == 0) {
        return 0;
    }
    // Load the shader source
    glShaderSource(shader, 1, &shader_src, NULL);
    
    // Compile the shader
    glCompileShader(shader);
    // Check the compile status
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    
    if (!compiled) {
        GLint info_len = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &info_len);
        
        if (info_len > 1) {
            char *info_log = ((char *)malloc(sizeof(char) * info_len));
            glGetShaderInfoLog(shader, info_len, NULL, info_log);
            NSLog(@"Error compiling shader:%s", info_log);
            free(info_log);
        }
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

static bool checkProgramLinkStatus(GLuint shader_program) {
    GLint linked = 0;
    glGetProgramiv(shader_program, GL_LINK_STATUS, &linked);
    
    if (!linked) {
        GLint info_len = 0;
        glGetProgramiv(shader_program, GL_INFO_LOG_LENGTH, &info_len);
        
        if (info_len > 1) {
            char *info_log = ((char *)malloc(sizeof(char) * info_len));
            glGetProgramInfoLog(shader_program, info_len, NULL, info_log);
            NSLog(@"Error linking program: %s", info_log);
            free(info_log);
        }
        glDeleteProgram(shader_program);
        return false;
    }
    return true;
}

static const char *kVertexShaderString =
"#version 100\n"
"\n"
"uniform mat4 uMVP; \n"
"uniform mat4 uPosition; \n"
"attribute vec3 aVertex; \n"
"attribute vec3 aTexCoords; \n"
"varying vec3 vGrid;  \n"
"varying vec2 vTexCoord;  \n"
"void main(void) { \n"
"  vTexCoord = vec2(aTexCoords.x, aTexCoords.y * -1.0); \n"
"  vec4 pos = uPosition * vec4(aVertex, 1.0); \n"
"  gl_Position = uMVP * pos; \n"
"    \n"
"}\n";

// Fragment shader for the floorplan grid.
// Line patters are generated based on the fragment's position in 3d.
static const char* kFragmentShaderString =
"#version 100\n"
"\n"
"#ifdef GL_ES\n"
"precision mediump float;\n"
"#endif\n"
"varying vec2 vTexCoord;\n"
"uniform sampler2D uTexture;\n"
"\n"
"void main() {\n"
"    gl_FragColor = texture2D(uTexture, vTexCoord).bgra;\n"
"}\n";

static const float kVertices[NUM_VERTICES] = {
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
};
static const float kTexCoords[NUM_VERTICES] = {
    0, 1.0f, 1.0f,
    0, 0, 1.0f,
    1.0f, 1.0f, 1.0f,
    0, 0, 1.0f,
    1.0f, 0, 1.0f,
    1.0f, 1.0f, 1.0f,
};

@implementation VideoSprite {
    
    GLfloat vertices[NUM_VERTICES];
    GLfloat tex_coords[NUM_VERTICES];
    
    GLuint texture;
    GLuint program;
    GLint vertex_attrib;
    GLint tex_coords_attrib;
    GLint position_uniform;
    GLint texture_uniform;
    GLint mvp_matrix;
    GLuint vertex_buffer;
    GLuint tex_coords_buffer;
    
    CMTimeValue lastTime;
    long lastPixelAddress;
    
    //    AVPlayer *player;
    //    AVPlayerItem *playerItem;
    //    AVPlayerItemVideoOutput *playerOutput;
    UIImage *uiImage;
    NSURL *url;
    CGSize imageSize;
    NSData *imageData;
}

- (instancetype) init {
    if(self = [super init]) {
        
        const GLuint vertex_shader = LoadShader(GL_VERTEX_SHADER, kVertexShaderString);
        NSAssert(vertex_shader != 0, @"Failed to load vertex shader");
        const GLuint fragment_shader = LoadShader(GL_FRAGMENT_SHADER, kFragmentShaderString);
        NSAssert(fragment_shader != 0, @"Failed to load fragment shader");
        
        program = glCreateProgram();
        NSAssert(program != 0, @"Failed to create program");
        glAttachShader(program, vertex_shader);
        glAttachShader(program, fragment_shader);
        
        // Link the shader program.
        glLinkProgram(program);
        NSAssert(checkProgramLinkStatus(program), @"Failed to link program");
        
        // Get the location of our attributes so we can bind data to them later.
        vertex_attrib = glGetAttribLocation(program, "aVertex");
        NSAssert(vertex_attrib != -1, @"glGetAttribLocation failed for aVertex");
        tex_coords_attrib = glGetAttribLocation(program, "aTexCoords");
        NSAssert(tex_coords_attrib != -1, @"glGetAttribLocation failed for aTexCoords");
        
        // After linking, fetch references to the uniforms in our shader.
        mvp_matrix = glGetUniformLocation(program, "uMVP");
        position_uniform = glGetUniformLocation(program, "uPosition");
        texture_uniform = glGetUniformLocation(program, "uTexture");
        NSAssert(mvp_matrix != -1 && position_uniform != -1 && texture_uniform != -1,
                 @"Error fetching uniform values for shader.");
        
        // Initialize the vertex data for the video plane mesh.
        for (int i = 0; i < NUM_VERTICES; ++i) {
            vertices[i] = (GLfloat)(kVertices[i] * 5);
        }
        glGenBuffers(1, &vertex_buffer);
        NSAssert(vertex_buffer != 0, @"glGenBuffers failed for vertex buffer");
        glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
        
        // Initialize the text coord data for the video plane mesh.
        for (int i = 0; i < NUM_VERTICES; ++i) {
            tex_coords[i] = (GLfloat)(kTexCoords[i]);
        }
        glGenBuffers(1, &tex_coords_buffer);
        NSAssert(tex_coords_buffer != 0, @"glGenBuffers failed for tex_coords buffer");
        glBindBuffer(GL_ARRAY_BUFFER, tex_coords_buffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(tex_coords), tex_coords, GL_STATIC_DRAW);
        
        // Initialize texture for video plane
        glGenTextures(1, &texture);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        url = [NSURL URLWithString:@"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQlvp6TSqcNWzh0k3w-BlKJQGMQESIt6Sd3v14Gq0nJcz9M420wAg"];
        imageData = [NSData dataWithContentsOfURL:url];
        uiImage = [[UIImage alloc] initWithData:imageData];
        imageSize = uiImage.size;
        
    }
    return self;
}

- (void) prerender:(GVRHeadTransform *)headTransform {
    
    CGImageRef imageRef = [uiImage CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    //
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    //
    
    NSLog(@"Real Update");
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, rawData);
    
    glUseProgram(program);
    glUniformMatrix4fv(position_uniform, 1, false, _transformation.m);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_vertices), _vertices, GL_STATIC_DRAW);
}

- (void) render:(const float *)model_view_matrix {
    // Select our shader.
    glUseProgram(program);
    glUniformMatrix4fv(mvp_matrix, 1, false, model_view_matrix);
    
    // Draw our polygons.
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    glVertexAttribPointer(vertex_attrib, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 3, 0);
    glEnableVertexAttribArray(vertex_attrib);
    glBindBuffer(GL_ARRAY_BUFFER, tex_coords_buffer);
    glVertexAttribPointer(tex_coords_attrib, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 3, 0);
    glEnableVertexAttribArray(tex_coords_attrib);
    glDrawArrays(GL_TRIANGLES, 0, NUM_VERTICES / 3);
    glDisableVertexAttribArray(vertex_attrib);
}


@end
