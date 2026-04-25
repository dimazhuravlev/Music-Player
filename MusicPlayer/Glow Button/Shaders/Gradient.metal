#include "Shared.h"
#include <metal_stdlib>
using namespace metal;

constant float TOP_CIRCLE_RADIUS = 0.7;
constant float TOP_CIRCLE_WIDTH = 0.2;
constant float TOP_CIRCLE_SPEED = 0.0;

constant float MIDDLE_CIRCLE_RADIUS = 0.7;
constant float MIDDLE_CIRCLE_WIDTH = 0.4;
constant float MIDDLE_CIRCLE_SPEED = 0.785;

constant float BOTTOM_CIRCLE_RADIUS = 0.7;
constant float BOTTOM_CIRCLE_WIDTH = 0.5;
constant float BOTTOM_CIRCLE_SPEED = 1.57;

constant float BOTTOM_SPARK_STRENGTH = 0.0;
constant float MIDDLE_SPARK_STRENGTH = 0.0;
constant float TOP_SPARK_STRENGTH = 0.0;

constant float MAX_AUDIO_WIDTH_STRENGTH = 0.15;

METAL_FUNC float3 hash33(float3 p3) {
  p3 = fract(p3 * float3(0.1031,0.11369,0.13787));
  p3 += dot(p3, p3.yxz+19.19);
  return -1.0 + 2.0 * fract(float3(p3.x+p3.y, p3.x+p3.z, p3.y+p3.z)*p3.zyx);
}

METAL_FUNC float snoise3(float3 p) {
  const float K1 = 0.333333333;
  const float K2 = 0.166666667;

  float3 i = floor(p + (p.x + p.y + p.z) * K1);
  float3 d0 = p - (i - (i.x + i.y + i.z) * K2);

  float3 e = step(float3(0.0), d0 - d0.yzx);
  float3 i1 = e * (1.0 - e.zxy);
  float3 i2 = 1.0 - e.zxy * (1.0 - e);

  float3 d1 = d0 - (i1 - K2);
  float3 d2 = d0 - (i2 - K1);
  float3 d3 = d0 - 0.5;

  float4 h = max(0.6 - float4(dot(d0, d0), dot(d1, d1), dot(d2, d2), dot(d3, d3)), 0.0);
  float4 n = h * h * h * h * float4(dot(d0, hash33(i)), dot(d1, hash33(i + i1)), dot(d2, hash33(i + i2)), dot(d3, hash33(i + 1.0)));

  return dot(float4(31.316), n);
}

METAL_FUNC float tri(float x){return abs(fract(x)-.5);}
METAL_FUNC float3 tri3(float3 p){return float3( tri(p.z+tri(p.y*20.)), tri(p.z+tri(p.x*1.)), tri(p.y+tri(p.x*1.)));}

METAL_FUNC float triNoise3D(float3 p, float spd, float vTime)
{
  float z=0.4;
  float rz = 0.1;
  float3 bp = p;
  for (float i=0.; i<=4.; i++ )
  {
    float3 dg = tri3(bp*0.01);
    p += (dg+vTime*0.05*spd);

    bp *= 4.;
    z *= 0.9;
    p *= 1.6;

    rz+= (tri(p.z+tri(0.6*p.x+0.1*tri(p.y))))/z;
  }
  return smoothstep(0.0, 8., rz + sin(rz + sin(z) * 2.8) * 2.2);
}

METAL_FUNC float2 rotate(float2 p, float a) {
  float s = sin(a);
  float c = cos(a);
  return float2(p.x * c - p.y * s, p.x * s + p.y * c);
}

METAL_FUNC float angled(float2 uv, float angle) {
  uv = rotate(uv, angle);
  float pa = atan2(uv.y, uv.x);

  float idx = (pa/M_PI_F + 1.0) / 2.0;
  float idx2 = idx * M_PI_F;

  return smoothstep(0.7, 1.0, sin(idx2));
}

METAL_FUNC float calcExtraWidth(float2 uv,
                                float strength1,
                                float strength2,
                                float speed,
                                float vTime) {
  float extraWidth = 0.0;

  extraWidth += smoothstep(0.0, 1.0, angled(uv, vTime * speed)) * (0.05 + MAX_AUDIO_WIDTH_STRENGTH) * strength1;
  extraWidth += smoothstep(0.0, 1.0, angled(uv, vTime * -speed)) * (0.05 + MAX_AUDIO_WIDTH_STRENGTH) * strength2;

  return extraWidth;
}

METAL_FUNC float light1(float intensity, float attenuation, float dist)
{
    return intensity / (1.0 + dist + dist * attenuation);
}

METAL_FUNC float light2(float intensity, float attenuation, float dist)
{
    return intensity / (1.0 + dist * attenuation);
}

METAL_FUNC float makeNoiseBlob1(float2 uv, float radius, float offset, float vTime) {
  float len = length(uv);
  float n0 = snoise3( float3(uv * 1.2, vTime * 0.25 + offset));
  float r0 = mix(radius, radius + 0.3, n0);
  return r0;
}

METAL_FUNC float4 makeNoiseBlob2(float2 uv, float3 color1, float3 color2, float strength, float offset, float vTime) {
  float ang = atan2(uv.y, uv.x);
  float len = length(uv);
  float v0, v1, cl;
  float r0, d0, n0;
  float r, d;

  n0 = snoise3( float3(uv * 1.2 + offset, vTime * 0.25 + offset) ) * 0.5 + 0.5;
  r0 = mix(0.0, 1.0, n0);
  d0 = distance(uv, r0 / len * uv);
  v0 = smoothstep(r0 * (1.0) + 0.6 + sin(vTime + offset) * 0.25, r0, len);

  float a = vTime * -0.5;
  float2 pos = float2(cos(a), sin(a)) * r0;
  d = distance(uv, pos);
  v1 = light2(1.5, 10.0, d);
  v1 = light1(0.15 * (1.0 + 1.5 * (-sin(vTime * 1. + offset * 0.5) * 0.5)) + 0.3 * strength, 10.0 , d0);

  float3 col = mix(color1, color2, uv.y * 2.);
  col = col + v1;
  col.rgb = clamp(col.rgb, 0.0, 1.0);
  return float4(col, v0);
}

METAL_FUNC float4 makeBlob(float2 uv,
                           float3 color1,
                           float3 color2,
                           float width,
                           float baseReaction,
                           float likeReaction,
                           float widthSpeed,
                           float audioWidthStrength1,
                           float audioWidthStrength2,
                           float radius,
                           float offset,
                           float2 noiseOffset,
                           float vTime,
                           float vInteraction,
                           float2 vInteractionPoint) {
  float len = length(uv);

  float extraWidth = width + calcExtraWidth(uv, audioWidthStrength1, audioWidthStrength2, widthSpeed, vTime);

  float blob = makeNoiseBlob1(uv * 1.2, radius, offset, vTime);

  float outerRadius = blob + extraWidth * 0.5 + baseReaction * (1.0 + max(likeReaction, audioWidthStrength1 * 0.6) * 50. * baseReaction);

  float interactionCircle = smoothstep(0.5, 0.0, abs(distance(vInteractionPoint, uv))) * vInteraction;
  float strength = max(likeReaction, audioWidthStrength1) + 10. * interactionCircle;

  float4 noise = makeNoiseBlob2(uv * (1.0 - likeReaction * 0.5) + noiseOffset, color1, color2, strength, offset, vTime);
  noise.a = mix(0.0, noise.a, smoothstep(outerRadius, outerRadius * 0.5, len));

  float glow = 0.0;
  noise.rgb += glow * 1.2;
  noise.rgb = clamp(noise.rgb, 0.0, 1.0);

  return noise;
}

kernel void shaderMain(texture2d<float, access::write> output [[texture(0)]],
                       constant Uniforms &uniforms [[buffer(0)]],
                       uint2 gid [[thread_position_in_grid]]) {

    if (gid.x >= output.get_width() || gid.y >= output.get_height()) return;

    float2 vScreenSize = float2(output.get_width(), output.get_height());
    float vTime = uniforms.time;
    float2 fragCoord = float2(gid);

    float2 uv = fragCoord / vScreenSize;
    uv = uv * 2.0 - 1.0;

    float aspect = vScreenSize.x / vScreenSize.y;
    if (aspect > 1.0) {
        uv.x *= aspect;
    } else {
        uv.y /= aspect;
    }

    // Apply scale before offset
    uv = uv / uniforms.scale;
    
    uv += uniforms.offset;

    float2 ruv = uv * 2.0;
    float pr = length(ruv);
    float pa = atan2(ruv.y, ruv.x);

    float idx = (pa/M_PI_F + 1.0) / 2.0;
    float idx2 = idx * M_PI_F;

    float2 ruv1 = rotate(uv * 2.0, M_PI_F);
    float pr1 = length(ruv1);
    float pa1 = atan2(ruv1.y, ruv1.x);
    float idx1 = (pa1/M_PI_F + 1.0) / 2.0;
    float idx21 = idx1 * M_PI_F;

    float spark = triNoise3D(float3(idx, 0.0, 0.0), 0.05, vTime);
    spark = mix(spark, triNoise3D(float3(idx1, 0.0, idx1), 0.05, vTime), smoothstep(0.9, 1.0, sin(idx21)));
    spark = spark * 0.2 + pow(spark, 10.);
    spark = smoothstep(0.0, spark, 0.3) * spark;

    float3 whiteColor = float3(1.0, 1.0, 1.0);
    
    float topSparkStrength = uniforms.sparkStrength * 0.3;
    
    float4 sparkCircleTop = makeBlob(
                                 uv,
                                 whiteColor,
                                 whiteColor,
                                 TOP_CIRCLE_WIDTH * 0.8,
                                 spark * topSparkStrength,
                                 uniforms.reactTop,
                                 0.25,
                                 uniforms.audio4,
                                 uniforms.audio5,
                                 TOP_CIRCLE_RADIUS,
                                 TOP_CIRCLE_SPEED,
                                 rotate(float2(-0.3, -0.3), vTime * 0.1),
                                 vTime,
                                 uniforms.interaction,
                                 uniforms.interactionPoint);

    float4 sparkCircleMiddle = makeBlob(
                                    uv,
                                    whiteColor,
                                    whiteColor,
                                    MIDDLE_CIRCLE_WIDTH * 0.9,
                                    spark * MIDDLE_SPARK_STRENGTH,
                                    uniforms.reactMiddle,
                                    0.25,
                                    uniforms.audio4,
                                    uniforms.audio5,
                                    MIDDLE_CIRCLE_RADIUS,
                                    MIDDLE_CIRCLE_SPEED,
                                    rotate(float2(-0.3, -0.3), vTime * (-0.1)),
                                    vTime,
                                    uniforms.interaction,
                                    uniforms.interactionPoint);

    float4 sparkCircleBottom = makeBlob(
                                    uv,
                                    whiteColor,
                                    whiteColor,
                                    BOTTOM_CIRCLE_WIDTH,
                                    spark * BOTTOM_SPARK_STRENGTH,
                                    uniforms.reactBottom,
                                    0.25,
                                    uniforms.audio4,
                                    uniforms.audio5,
                                    BOTTOM_CIRCLE_RADIUS,
                                    BOTTOM_CIRCLE_SPEED,
                                    rotate(float2(-0.3, 0.3), vTime * 0.1),
                                    vTime,
                                    uniforms.interaction,
                                    uniforms.interactionPoint);

    float3 color = float3(0.0);

    sparkCircleBottom.rgb *= uniforms.bottomOpacity;
    sparkCircleMiddle.rgb *= uniforms.middleOpacity;
    sparkCircleTop.rgb *= uniforms.topOpacity;
    
    float edgeFactor = 2.5;
    
    color = mix(color, sparkCircleBottom.rgb, sparkCircleBottom.a);
    
    float middleEdge = smoothstep(0.1, 0.9, sparkCircleMiddle.a) * smoothstep(0.1, 0.5, sparkCircleBottom.a) * edgeFactor;
    sparkCircleMiddle.rgb *= (1.0 + middleEdge);
    color = mix(color, sparkCircleMiddle.rgb, sparkCircleMiddle.a);
    
    float topEdge = smoothstep(0.1, 0.9, sparkCircleTop.a) * 
                  (smoothstep(0.1, 0.5, sparkCircleMiddle.a) + 
                   smoothstep(0.1, 0.5, sparkCircleBottom.a)) * edgeFactor;
    sparkCircleTop.rgb *= (1.0 + topEdge);
    color = mix(color, sparkCircleTop.rgb, sparkCircleTop.a);

    float alpha = length(color);

    alpha *= 0.1;
    
    float4 fragColor = float4(color, alpha);
    output.write(fragColor, gid);
}
