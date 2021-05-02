Shader "Unlit/PotionShader"
{
    Properties
    {
        _NormalColor("Normal Color", Color) = (1,0,0,0.1)
        _EffectColor("Effect Color", Color) = (0,1,0,1)
        _FoamHeight("Foam Height", Float) = 1
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

            #include "UnityCG.cginc"

            float4 _NormalColor;
            float4 _EffectColor;
            float _FoamHeight;

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

            float4 GetType(float3 worldPos)
            {
                if (worldPos.y > _FoamHeight)
                {
                    return _EffectColor;
                }
                return _NormalColor;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                return GetType(i.worldPos);
            }
            ENDCG
        }
        // shadow caster rendering pass, implemented manually
        // using macros from UnityCG.cginc
        Pass
        {
            Tags {"LightMode"="ShadowCaster"}
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f { 
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
