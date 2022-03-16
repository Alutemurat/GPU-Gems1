// Caustics 
// Copyright (c) NVIDIA Corporation. All rights reserved. 
// 
// NOTE: 
// This shader is based on the original work by Daniel Sanchez-Crespo 
// of the Universitat Pompeu Fabra, Barcelona, Spain. 
#define VTXSIZE 0.01f   // Amplitude 
#define WAVESIZE 10.0f  // Frequency 
#define FACTOR 1.0f    
#define SPEED 2.0f    
#define OCTAVES 5 

// Example of the same wave function used in the vertex engine 
float wave(float x,float y, float timer)
{   
    float z = 0.0f;   
    float octaves = OCTAVES;   
    float factor = FACTOR;   
    float d = sqrt(x * x + y * y); 
    do{     
        z -= factor * cos(timer * SPEED + (1/factor) * x * y * WAVESIZE);     
        factor = factor/2;     
        octaves--;   
    } while (octaves > 0); 
  return 2 * VTXSIZE * d * z; 
} 

// This is a derivative of the above wave function. 
// It returns the d(wave)/dx and d(wave)/dy partial derivatives. 
float2 gradwave(float x,float y,float timer)
{   
    float dZx = 0.0f;   
    float dZy = 0.0f;   
    float octaves = OCTAVES;   
    float factor = FACTOR;   
    float d = sqrt(x * x + y * y); 
    do {     
        dZx += d * sin(timer * SPEED + (1/factor) * x * y * WAVESIZE) *
            y * WAVESIZE - factor *cos(timer * SPEED + (1/factor) * x * y * WAVESIZE) * x/d;     
        dZy += d * sin(timer * SPEED + (1/factor) * x * y * WAVESIZE) *x * WAVESIZE - factor * 
            cos(timer * SPEED + (1/factor) * x * y * WAVESIZE) * y/d;     
        factor = factor/2;     
        octaves--;   
    } while (octaves > 0); 
    return float2(2 * VTXSIZE * dZx, 2 * VTXSIZE * dZy); 
} 

float3 line_plane_intercept(float3 lineP,float3 lineN,float3 planeN,float  planeD) 
{   
    // Unoptimized    
    // float distance = (planeD - dot(planeN, lineP)) /     
    //                    dot(lineN, planeN);     
    // Optimized (assumes planeN always points up)     
    float distance = (planeD - lineP.z) / lineN.z;   
    return lineP + lineN * distance; 
} 

float4 main(VS_OUTPUT vert,uniform sampler2D LightMap  : register(s0), uniform sampler2D GroundMap : register(s1),
            uniform float Timer) : COLOR {   
    // Generate a normal (line direction) from the gradient     
    // of the wave function and intercept with the water plane.     
    // We use screen-space z to attenuate the effect to avoid aliasing.     
    float2 dxdy = gradwave(vert.Position.x, vert.Position.y, Timer); 
    float3 intercept = line_plane_intercept( vert.Position.xyz,float3(dxdy, saturate(vert.Position.w)),
                        float3(0, 0, 1), -0.8); 
    // OUTPUT     
    float4 colour;   
    colour.rgb = (float3)tex2D(LightMap, intercept.xy * 0.8);   
    colour.rgb += (float3)tex2D(GroundMap, vert.uv);   
    colour.a = 1;   
    return colour; 
} 