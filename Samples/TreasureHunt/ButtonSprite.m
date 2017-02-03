//
//  ButtonSprite.m
//  TreasureHunt
//
//  Created by Kevin Leung on 2/2/2017.
//
//


#define NUM_VERTICES 18
#define NUM_COLORS 24

#import "ButtonSprite.h"
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
    "uniform float uAlpha; \n"
    "attribute vec3 aVertex; \n"
    "attribute vec4 aColor; \n"
    "varying vec3 vGrid;  \n"
    "varying vec4 vColor;  \n"
    "//varying vec2 vTexCoord;  \n"
    "void main(void) { \n"
    "  //vTexCoord = vec2(aVertex.x - 0.5, aVertex.y * -1.0 - 0.5); \n"
    "  vColor = vec4(aColor.rgb, aColor.a * uAlpha); \n"
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
    "//varying vec2 vTexCoord;\n"
    "//uniform sampler2D uTexture;\n"
    "varying vec4 vColor;  \n"
    "\n"
    "void main() {\n"
    "    gl_FragColor = vColor;\n"
    "}\n";

static const float kVertices[NUM_VERTICES] = {
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
};

// Color of the plane
static const float kColors[NUM_COLORS] = {
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
};

@implementation ButtonSprite {
    
    GLfloat colors[NUM_COLORS];
    GLfloat vertices[NUM_VERTICES];
    GLfloat position[3];
    
    GLuint texture;
    GLuint program;
    GLint vertex_attrib;
    GLint color_attrib;
    GLint position_uniform;
    GLint alpha_uniform;
    GLint texture_uniform;
    GLint mvp_matrix;
    GLuint vertex_buffer;
    GLuint color_buffer;
    
    CMTimeValue lastTime;
    long lastPixelAddress;
    
    AVPlayer *player;
    AVPlayerItem *playerItem;
    AVPlayerItemVideoOutput *playerOutput;
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
        color_attrib = glGetAttribLocation(program, "aColor");
        NSAssert(color_attrib != -1, @"glGetAttribLocation failed for aColor");
        
        // After linking, fetch references to the uniforms in our shader.
        mvp_matrix = glGetUniformLocation(program, "uMVP");
        position_uniform = glGetUniformLocation(program, "uPosition");
        alpha_uniform = glGetUniformLocation(program, "uAlpha");
//        texture_uniform = glGetUniformLocation(program, "uTexture");
        NSAssert(mvp_matrix != -1 && position_uniform != -1 /*&& texture_uniform != -1*/,
                 @"Error fetching uniform values for shader.");
        // Initialize the vertex data for the video plane mesh.
        for (int i = 0; i < NUM_VERTICES; ++i) {
            vertices[i] = (GLfloat)(kVertices[i] * 1);
        }
        glGenBuffers(1, &vertex_buffer);
        NSAssert(vertex_buffer != 0, @"glGenBuffers failed for vertex buffer");
        
        // Initialize the found color data for the cube mesh.
        for (int i = 0; i < NUM_COLORS; ++i) {
            colors[i] = (GLfloat)(kColors[i]);
        }
        glGenBuffers(1, &color_buffer);
        NSAssert(color_buffer != 0, @"glGenBuffers failed for color buffer");
        glBindBuffer(GL_ARRAY_BUFFER, color_buffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW);
        
        position[0] = 0;
        position[1] = 0;
        position[2] = 3.9f;
        
        
    }
    return self;
}

- (void) prerender:(GVRHeadTransform *)headTransform {
    
}

- (void) render:(const float *)model_view_matrix {
    // Select our shader.
    glUseProgram(program);
    
    // Set the uniform values that will be used by our shader.
//    glUniform3fv(position_uniform, 1, position);
    glUniform1i(texture_uniform, 0); // our texture slot
    glUniform1f(alpha_uniform, _alpha);
    
    // Set the uniform matrix values that will be used by our shader.
    glUniformMatrix4fv(position_uniform, 1, false, _transformation.m);
    glUniformMatrix4fv(mvp_matrix, 1, false, model_view_matrix);
    
    // Set the grid colors.
    glBindBuffer(GL_ARRAY_BUFFER, color_buffer);
    glVertexAttribPointer(color_attrib, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
    glEnableVertexAttribArray(color_attrib);
    
    // Draw our polygons.
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(vertex_attrib, 3, GL_FLOAT, GL_FALSE, sizeof(float) * 3, 0);
    glEnableVertexAttribArray(vertex_attrib);
    glDrawArrays(GL_TRIANGLES, 0, NUM_VERTICES / 3);
    glDisableVertexAttribArray(vertex_attrib);
}

@end
