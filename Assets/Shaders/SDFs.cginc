#ifndef SDFS
#define SDFS

#include "Noise2D.cginc"
#include "Noise3D.cginc"

float _LiquidRadius;
float _LiquidStart;
float _LiquidEnd;
float _LiquidBottomRounding;
float _LiquidTopRoundingStart;

float _FoamUpperStart;
float _FoamRadius;

float _RipplesSpeed;
float _RipplesFrequency;
float _RipplesAmplitude;

float _WaveSpeed;
float _WaveFrequency;
float _WaveAmplitude;

float CylinderSDF(float3 worldPos, float2 center, float radius, float start, float end)
{
  float2 compDist = float2(length(worldPos.xz - center) - radius, max(worldPos.y - end, start - worldPos.y));
  float outsideDist = length(max(compDist, 0));
  float innerDist = min(max(compDist.x, compDist.y), 0);
  return innerDist + outsideDist;
}

float SphereSDF(float3 worldPos, float3 center, float radius)
{
  return length(worldPos - center) - radius;
}

float GetNoise(float3 worldPos, float speed, float frequency, float amplitude)
{
  worldPos.y -= _Time.y * speed;
  float noise = snoise(worldPos * frequency);
  noise *= amplitude;
  return noise;
}

float LiquidSDF(float3 worldPos)
{
  float distance = CylinderSDF(worldPos, float2(0,0), _LiquidRadius - _LiquidBottomRounding, _LiquidStart + _LiquidBottomRounding, _LiquidTopRoundingStart);
  distance -= _LiquidBottomRounding;
  distance = min(distance, SphereSDF(worldPos, float3(0, _LiquidTopRoundingStart, 0), _LiquidRadius));
  distance = max(distance, worldPos.y - _LiquidEnd - GetNoise(worldPos, _RipplesSpeed, _RipplesFrequency, _RipplesAmplitude));
  return distance;
}

float2 GetWiggleOffset(float height)
{
  float sampleX = height * _WaveFrequency - _Time.y * _WaveSpeed;
  float2 offset = float2(snoise(float2(sampleX, 1)), snoise(float2(sampleX, 2)));
  offset -= float2(0.5,0.5);
  return offset * _WaveAmplitude;
}

float FoamSDF(float3 worldPos, float3 ballPos)
{
  float distance = _FoamUpperStart - worldPos.y - GetNoise(worldPos, _RipplesSpeed, _RipplesFrequency, _RipplesAmplitude);

  float heightNoise = smoothstep(ballPos.y, _FoamUpperStart, worldPos.y);
  float2 cylinderCenter = GetWiggleOffset(worldPos.y);
  cylinderCenter *= heightNoise;
  distance = min(distance, SphereSDF(worldPos, ballPos, _FoamRadius));
  distance = min(distance, CylinderSDF(worldPos, cylinderCenter, _FoamRadius, ballPos.y, _FoamUpperStart));
  return distance;
}

#endif