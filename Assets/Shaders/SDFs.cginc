#ifndef SDFS
#define SDFS

float _LiquidRadius;
float _LiquidStart;
float _LiquidEnd;

float CylinderSDF(float3 worldPos, float radius, float start, float end)
{
  float2 compDist = float2(length(worldPos.xz) - radius, max(worldPos.y - end, start - worldPos.y));
  float outsideDist = length(max(compDist, 0));
  float innerDist = min(max(compDist.x, compDist.y), 0);
  return innerDist + outsideDist;
}

float LiquidSDF(float3 worldPos)
{
  return CylinderSDF(worldPos, _LiquidRadius, _LiquidStart, _LiquidEnd);
}

#endif