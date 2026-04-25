#ifndef Shared_h
#define Shared_h

#include <simd/simd.h>

#ifdef __METAL_VERSION__
typedef float2 vec2;
typedef float3 vec3;
typedef float4 vec4;

typedef metal::float3x3 mat3;
typedef metal::float4x4 mat4;
#else
#include <simd/simd.h>
typedef simd_float2 vec2;
typedef simd_float3 vec3;
typedef simd_float4 vec4;
typedef matrix_float3x3 mat3;
typedef matrix_float4x4 mat4;
#endif

typedef struct {
  float time;
  float audio4;
  float audio5;

  vec2 offset;
  vec2 interactionPoint;
  float interaction;

  float reactTop;
  float reactMiddle;
  float reactBottom;

  float topOpacity;
  float middleOpacity;
  float bottomOpacity;

  float sparkStrength;
  float scale;
} Uniforms;

#endif
