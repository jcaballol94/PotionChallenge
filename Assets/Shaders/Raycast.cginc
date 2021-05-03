#ifndef RAYCAST
#define RAYCAST

#include "SDFs.cginc"

#define STEPS 64
#define FULL_ALPHA 0.1

float _TotalSize;
float4 _LiquidColor;
float4 _FloatingBall;

float4 RayCast (float3 worldPos, float3 viewDir, float3 lightDir, float3 lightColor)
{
    float4 finalColor = float4(0,0,0,0);
    float prevDistToLiquid = 1000;
    float prevDistToBall = 1000;
    float seeThrough = 1;

    float stepLength = _TotalSize / (float)STEPS;
    float scale = stepLength / FULL_ALPHA;

    for (int i = 0; i < STEPS; ++i) {
        float3 pos = worldPos + viewDir * stepLength * i;

        // Calculate the bottle outside
        float distToLiquid = LiquidSDF(pos);
        float prevOutside = step(0, prevDistToLiquid);
        float newOutside = step(0, distToLiquid);
        float outside = lerp(prevOutside, newOutside, 1 - smoothstep(prevDistToLiquid, distToLiquid, 0));
        prevDistToLiquid = distToLiquid;
        float4 color = lerp(_LiquidColor, float4(0,0,0,0), outside);
        
        // Calculate the ball
        float distToBall = SphereSDF(pos, _FloatingBall.xyz, _FloatingBall.w);
        float prevBall = step(prevDistToBall, 0);
        float newBall = step(distToBall, 0);
        float ball = lerp(prevBall, newBall, 1 - smoothstep(prevDistToBall, distToBall, 0));
        prevDistToBall = prevBall;
        seeThrough = min(seeThrough, 1 - ball);

        color.a *= scale;
        color.rgb *= color.a;
        finalColor += seeThrough * (1 - finalColor.a) * color;
    }

    return finalColor;
}
#endif