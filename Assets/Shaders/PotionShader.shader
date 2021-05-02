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

            #include "UnityCG.cginc"

            float4 _NormalColor;
            float4 _EffectColor;
            float _BottleRadius;
            float _BottleHeight;
            float _FoamHeight;
            float _FoamRadius;
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

            float4 GetType(float3 worldPos)
            {
                if (worldPos.y > _FoamHeight || length(worldPos.xz) < _FoamRadius)
                    return _EffectColor;
                return _NormalColor;
            }

            float4 RayCast (float3 worldPos, float3 viewDir)
            {
                float4 finalColor = float4(0,0,0,0);
                float stepLength = _BottleRadius * 2 / (float)STEPS;
                for (int i = 0; i < STEPS; ++i) {
                    float3 pos = worldPos + viewDir * stepLength * i;
                    if (InObstacle(pos) || Outside(pos))
                        break;

                    float4 type = GetType(pos);
                    type.rgb *= type.a;
                    finalColor += (1 - finalColor.a) * type;
                }

                return finalColor;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return RayCast(i.worldPos, normalize(i.worldPos - _WorldSpaceCameraPos));
            }
            ENDCG
        }
    }
}
