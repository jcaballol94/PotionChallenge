#ifndef SDFS
#define SDFS

float _LiquidRadius;
float _LiquidStart;
float _LiquidEnd;
float _LiquidBottomRounding;
float _LiquidTopRoundingStart;

float CylinderSDF(float3 worldPos, float radius, float start, float end)
{
  float2 compDist = float2(length(worldPos.xz) - radius, max(worldPos.y - end, start - worldPos.y));
  float outsideDist = length(max(compDist, 0));
  float innerDist = min(max(compDist.x, compDist.y), 0);
  return innerDist + outsideDist;
}

float SphereSDF(float3 worldPos, float3 center, float radius)
{
  return length(worldPos - center) - radius;
}

float LiquidSDF(float3 worldPos)
{
  float distance = CylinderSDF(worldPos, _LiquidRadius - _LiquidBottomRounding, _LiquidStart + _LiquidBottomRounding, _LiquidTopRoundingStart);
  distance -= _LiquidBottomRounding;
  distance = min(distance, SphereSDF(worldPos, float3(0, _LiquidTopRoundingStart, 0), _LiquidRadius));
  return distance;
}

#endif