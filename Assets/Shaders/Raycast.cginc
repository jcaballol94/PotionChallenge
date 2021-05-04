#ifndef RAYCAST
#define RAYCAST

#include "SDFs.cginc"

#define STEPS 32
#define LIGHT_STEPS 32
#define FULL_ALPHA 0.1

float _TotalSize;
float4 _LiquidColor;
float4 _FoamColor;
float4 _FloatingBall;

float LightRayCast (float3 worldPos, float3 lightDir)
{
    float finalOpacity = 0;
    float prevDistToLiquid = 1000;
    float prevDistToBall = 1000;
    float prevDistToFoam = 1000;

    float stepLength = _TotalSize / (float)LIGHT_STEPS;
    float scale = stepLength / FULL_ALPHA;

    for (int i = 0; i < LIGHT_STEPS; ++i) {
        float3 pos = worldPos + lightDir * stepLength * i;
        
        // Calculate the foam area
        float distToFoam = FoamSDF(pos, _FloatingBall);
        float prevFoam = step(prevDistToFoam, 0);
        float newFoam = step(distToFoam, 0);
        float foam = lerp(prevFoam, newFoam, 1 - smoothstep(prevDistToFoam, distToFoam, 0));
        prevDistToFoam = distToFoam;
        float4 color = lerp(_LiquidColor, _FoamColor, foam);

        // Calculate the bottle outside
        float distToLiquid = LiquidSDF(pos);
        float prevOutside = step(0, prevDistToLiquid);
        float newOutside = step(0, distToLiquid);
        float outside = lerp(prevOutside, newOutside, 1 - smoothstep(prevDistToLiquid, distToLiquid, 0));
        prevDistToLiquid = distToLiquid;
        color = lerp(color, float4(0,0,0,0), outside);
        
        // Calculate the ball
        float distToBall = SphereSDF(pos, _FloatingBall.xyz, _FloatingBall.w);
        float prevBall = step(prevDistToBall, 0);
        float newBall = step(distToBall, 0);
        float ball = lerp(prevBall, newBall, 1 - smoothstep(prevDistToBall, distToBall, 0));
        prevDistToBall = prevBall;
        finalOpacity = max(finalOpacity, ball);

        color.a *= scale;
        finalOpacity += (1 - finalOpacity) * color.a;
    }

    return 1 - finalOpacity;
}

float CellShading(float intensity, int numBands)
{
  return ceil(intensity * numBands) / numBands;
}

float4 RayCast (float3 worldPos, float3 viewDir, float3 lightDir, float3 lightColor)
{
    float4 finalColor = float4(0,0,1,0);
    float prevDistToLiquid = 1000;
    float prevDistToBall = 1000;
    float prevDistToFoam = 1000;
    float seeThrough = 1;

    float stepLength = _TotalSize / (float)STEPS;
    float scale = stepLength / FULL_ALPHA;

    for (int i = 0; i < STEPS; ++i) {
        float3 pos = worldPos + viewDir * stepLength * i;
        
        // Calculate the foam area
        float distToFoam = FoamSDF(pos, _FloatingBall);
        float prevFoam = step(prevDistToFoam, 0);
        float newFoam = step(distToFoam, 0);
        float foam = lerp(prevFoam, newFoam, 1 - smoothstep(prevDistToFoam, distToFoam, 0));
        prevDistToFoam = distToFoam;
        float4 color = lerp(float4(1,0,1,_LiquidColor.a), float4(0,1,1,_FoamColor.a), foam);

        // Calculate the bottle outside
        float distToLiquid = LiquidSDF(pos);
        float prevOutside = step(0, prevDistToLiquid);
        float newOutside = step(0, distToLiquid);
        float outside = lerp(prevOutside, newOutside, 1 - smoothstep(prevDistToLiquid, distToLiquid, 0));
        prevDistToLiquid = distToLiquid;
        color = lerp(color, float4(0,0,0,0), outside);
        
        // Calculate the ball
        float distToBall = SphereSDF(pos, _FloatingBall.xyz, _FloatingBall.w);
        float prevBall = step(prevDistToBall, 0);
        float newBall = step(distToBall, 0);
        float ball = lerp(prevBall, newBall, 1 - smoothstep(prevDistToBall, distToBall, 0));
        prevDistToBall = prevBall;
        seeThrough = min(seeThrough, 1 - ball);

        color.b *= LightRayCast(pos, lightDir);
        color.a *= scale;
        color.rgb *= color.a;
        finalColor += seeThrough * (1 - finalColor.a) * color;
    }

    float lightIntensity = CellShading(finalColor.z, 3);
    float4 postProcessedColor = lerp(_LiquidColor, _FoamColor, step(finalColor.x, finalColor.y));
    postProcessedColor *= lightIntensity;
    postProcessedColor.a = finalColor.a;
    postProcessedColor.rgb *= postProcessedColor.a;
    return postProcessedColor;
}
#endif