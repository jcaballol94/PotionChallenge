#ifndef RAYCAST
#define RAYCAST

#include "SDFs.cginc"

#define STEPS 64
#define FULL_ALPHA 0.1

float _TotalSize;
float4 _LiquidColor;

float4 RayCast (float3 worldPos, float3 viewDir, float3 lightDir, float3 lightColor)
{
    float4 finalColor = float4(0,0,0,0);
    float prevDistToLiquid = 1000;

    float stepLength = _TotalSize / (float)STEPS;
    float scale = stepLength / FULL_ALPHA;

    for (int i = 0; i < STEPS; ++i) {
        float3 pos = worldPos + viewDir * stepLength * i;

        float distToLiquid = LiquidSDF(pos);
        float prevOutside = step(0, prevDistToLiquid);
        float newOutside = step(0, distToLiquid);
        float outside = lerp(prevOutside, newOutside, 1 - smoothstep(prevDistToLiquid, distToLiquid, 0));
        prevDistToLiquid = distToLiquid;

        float4 color = lerp(_LiquidColor, float4(0,0,0,0), outside);
        color.a *= scale;
        color.rgb *= color.a;
        finalColor += (1 - finalColor.a) * color;
    }

    return finalColor;
}
#endif