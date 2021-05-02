Shader "Unlit/PotionShader"
{
    Properties
    {
        _NormalColor("Normal Color", Color) = (1,0,0,0.1)
        _EffectColor("Effect Color", Color) = (0,1,0,1)
        _BottleRadius("Bottle Radius", Float) = 1
        _BottleHeight("Bottle Height", Float) = 2
        _FoamHeight("Foam Height", Float) = 1
        _FoamRadius("Foam Radius", Float) = 0.5
        _WaveSpeed("Wave Speed", Float) = 1
        _WaveFrequency("Wave Freq", Float) = 1
        _WaveAmplitude("Wave Ampl", Float) = 1
        _NoiseSpeed("Noise Speed", Float) = 2
        _NoiseFrequency("Noise Freq", Float) = 1
        _NoiseAmplitude("Noise Ampl", Float) = 1
        _RipplesSpeed("Ripples Speed", Float) = 2
        _RipplesFrequency("Ripples Freq", Float) = 1
        _RipplesAmplitude("Ripples Ampl", Float) = 1
        _Obstacle("Obstacle", Vector) = (0,0,0,1)
    }
    SubShader
    {
        Pass
        {
            Tags { "RenderType"="Transparent" "RenderQueue"="Transparent" }
            Blend One OneMinusSrcAlpha
            LOD 100

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #define STEPS 32
            #define LIGHT_STEPS 16

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Noise2D.cginc"
            #include "Noise3D.cginc"

            float4 _NormalColor;
            float4 _EffectColor;
            float _BottleRadius;
            float _BottleHeight;
            float _FoamHeight;
            float _FoamRadius;
            float _WaveSpeed;
            float _WaveFrequency;
            float _WaveAmplitude;
            float _NoiseSpeed;
            float _NoiseFrequency;
            float _NoiseAmplitude;
            float _RipplesSpeed;
            float _RipplesFrequency;
            float _RipplesAmplitude;
            float4 _Obstacle;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            bool InObstacle(float3 worldPos)
            {
                if (length(worldPos - _Obstacle.xyz) < _Obstacle.w) 
                    return true;
                return false;
            }

            bool Outside (float3 worldPos)
            {
                if (worldPos.y < 0 || worldPos.y > _BottleHeight ||
                    length(worldPos.xz) > _BottleRadius)
                    return true;
                return false;
            }

            float2 GetWiggleOffset(float height)
            {
                float sampleX = height * _WaveFrequency - _Time.y * _WaveSpeed;
                float2 offset = float2(snoise(float2(sampleX, 1)), snoise(float2(sampleX, 2)));
                offset -= float2(0.5,0.5);
                offset *= height / _BottleHeight;
                return offset * _WaveAmplitude;
            }

            float GetNoise(float3 worldPos, float speed, float frequency, float amplitude)
            {
                float size = worldPos.y / _BottleHeight;
                worldPos.y -= _Time.y * speed;
                float noise = snoise(worldPos * frequency);
                noise *= amplitude;
                return noise * size;
            }

            float GetDist(float3 worldPos)
            {
                float dist = _FoamHeight - worldPos.y - GetNoise(worldPos, _RipplesSpeed, _RipplesFrequency, _RipplesAmplitude);
                dist = min(dist, length(worldPos.xz - GetWiggleOffset(worldPos.y)) - _FoamRadius - GetNoise(worldPos, _NoiseSpeed, _NoiseFrequency, _NoiseAmplitude));
                return dist;
            }
            
            float LightRaycast (float3 worldPos, float3 lightDir)
            {
                float lightIntensity = 1;
                float stepLength = _BottleRadius * 2 / (float)LIGHT_STEPS;
                float4 prevType = _NormalColor;
                float prevDist = 0;
                for (int i = 0; i < LIGHT_STEPS; ++i) {
                    float3 pos = worldPos + lightDir * stepLength * i;
                    if (InObstacle(pos)) {
                        lightIntensity = 0;
                        break;
                    }
                    
                    if (Outside(pos))
                        break;

                    float newDist = GetDist(pos);
                    float4 newColor = lerp(_EffectColor, _NormalColor, step(0, newDist));
                    float4 type = lerp(prevType, newColor, 1 - smoothstep(prevDist, newDist, 0));
                    prevDist = newDist;
                    prevType = newColor;
                    lightIntensity *= (1 - type.a);
                }

                return lightIntensity;
            }

            float4 RayCast (float3 worldPos, float3 viewDir, float3 lightDir, float3 lightColor)
            {
                float4 finalColor = float4(0,0,0,0);
                float4 prevType = _NormalColor;
                float prevDist = 0;
                float stepLength = _BottleRadius * 2 / (float)STEPS;
                for (int i = 0; i < STEPS; ++i) {
                    float3 pos = worldPos + viewDir * stepLength * i;
                    if (InObstacle(pos) || Outside(pos))
                        break;

                    float lightIntensity = LightRaycast(pos, lightDir);

                    float newDist = GetDist(pos);
                    float4 newColor = lerp(_EffectColor, _NormalColor, step(0, newDist));
                    float4 type = lerp(prevType, newColor, 1 - smoothstep(prevDist, newDist, 0));
                    prevDist = newDist;
                    prevType = newColor;

                    type.rgb *= lightColor * lightIntensity;
                    type.rgb *= type.a;
                    finalColor += (1 - finalColor.a) * type;
                }

                return finalColor;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return RayCast(i.worldPos, normalize(i.worldPos - _WorldSpaceCameraPos), _WorldSpaceLightPos0.xyz, _LightColor0.rgb);
            }
            ENDCG
        }
    }
}
