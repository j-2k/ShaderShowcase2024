Shader "Unlit/EclipseSky"
{
    Properties
    {
        [Header(Colors Control)]
        _ColorTop ("Color Top", Color) = (1,1,1,1)
        _ColorMid("Color Mid", Color) = (.6,.6,.6,1)
        _ColorBot("Color Bot", Color) = (.2,.2,.2,1)

        [Header(Sky Control)]
        _SkyOffset("Sky Offset", Range(-3.0,3.0)) = 0.0

        [Header(Textures)]
        _MainTex ("Main Texture", 2D) = "white" {}


        [Header(Sun Control)]
        _SunSize("Sun Size", Range(0.0,10.0)) = 1.0
        [HDR] _SunColor("Sun Color", Color) = (1,1,1,1)
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #define TAU 6.28318530718
            #define PI 3.14159265359

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _ColorTop;
            float4 _ColorMid;
            float4 _ColorBot;

            float _SkyOffset;

            float _SunSize;
            float4 _SunColor;



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = normalize(i.worldPos);
                float arcSineY = asin(worldPos.y)/(PI/2); //PI/2;
                float arcTan2X = atan2(worldPos.x,worldPos.z)/TAU;
                float2 skyUV = float2(arcTan2X,arcSineY);
                // sample the texture
                fixed4 col = tex2D(_MainTex, skyUV);

                // apply colors
                float3 color = lerp(_ColorBot.rgb, _ColorTop.rgb, skyUV.y - _SkyOffset);
                


                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(color,1);
            }
            ENDCG
        }
    }
}
