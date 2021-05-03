Shader "Unlit/GlassShader"
{
    Properties
    {
        [Header(Bottle)]
        _Color("Color", Color) = (1,1,1,1)
        _FresnelHardness("Fresnel Hardness", Float) = 1
        _SpecularHardness("Specular Hardness", Float) = 1
        _SpecularPower("Specular Power", Float) = 1
        _TotalSize("Total Size", Float) = 2

        [Header(Liquid Area)]
        _LiquidRadius("Radius", Float) = 1
        _LiquidStart("Start", Float) = 0
        _LiquidEnd("End", Float) = 1
        _LiquidBottomRounding("Bottom Rounding", Float) = 1
        _LiquidTopRoundingStart("Top Rounding Start", Float) = 1

        [Header(Foam Area)]
        _FoamUpperStart("Upper Start", Float) = 1
        _FoamRadius("Radius", Float) = 1

        [Header(Colors)]
        _LiquidColor("Liquid", Color) = (1,1,1,1)
        _FoamColor("Foam", Color) = (1,1,1,1)

        [Header(Floating ball)]
        _FloatingBall("Floating Ball (POS, R)", Vector) = (0,1,0,0.1)

        [Header(Ripples)]
        _RipplesSpeed("Speed", Float) = 1
        _RipplesFrequency("Frequency", Float) = 1
        _RipplesAmplitude("Amplitude", Float) = 1

        [Header(Wave)]
        _WaveSpeed("Speed", Float) = 1
        _WaveFrequency("Frequency", Float) = 1
        _WaveAmplitude("Amplitude", Float) = 1

        [Header(Noise)]
        _NoiseSpeed("Speed", Float) = 2
        _NoiseFrequency("Frequency", Float) = 1
        _NoiseAmplitude("Amplitude", Float) = 1

    }
    SubShader
    {
        
        LOD 100

        Pass
        {
            Tags { "RenderType"="Transparent" "RenderQueue"="Transparent" }
            Blend One OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "Raycast.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float3 normal : NORMAL;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float4 _Color;
            float _FresnelHardness;
            float _SpecularHardness;
            float _SpecularPower;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.worldPos - _WorldSpaceCameraPos);

                float4 col = _Color;
                col.a *= pow(saturate(1 - dot(i.normal, -viewDir)), _FresnelHardness);
                col.rgb *= col.a;

                float3 H = normalize(_WorldSpaceLightPos0.xyz - viewDir);

                //Intensity of the specular light
                float NdotH = dot(i.normal, H);
                float intensity = pow(saturate(NdotH), _SpecularHardness);
                intensity = step(0.5, intensity) * _SpecularPower;

                //Sum up the specular light factoring
                col.rgb += intensity * _LightColor0.rgb;

                col += (1 - col.a) * RayCast(i.worldPos, viewDir, _WorldSpaceLightPos0.xyz, _LightColor0.rgb);

                return col;
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
