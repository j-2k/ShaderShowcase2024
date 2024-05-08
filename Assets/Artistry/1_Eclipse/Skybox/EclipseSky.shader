Shader "Jumas_Shaders/EclipseSky"
{
    Properties
    {
        [Header(Colors Control)]
        _ColorTop ("Color Top", Color) = (1,1,1,1)
        _ColorMid("Color Mid", Color) = (.6,.6,.6,1)
        _ColorBot("Color Bot", Color) = (.2,.2,.2,1)

        /*
        [Header(Sky Control)]
        _PushTop("Push Top", Range(-2.0,2.0)) = 0.0
        _PushBot("Push Bot", Range(-2.0,2.0)) = 0.0
        _SkyOffset("Sky Offset", Range(-3.0,3.0)) = 0.0
        */

        [Header(Sky Control 2)]
        _Toffset("Top Offset", Range(-2.0,2.0)) = 0.0
        _SST("Sky Smooth Top", Range(0.0,2.0)) = 0.0
        _Moffset("Middle Offset", Range(-2.0,2.0)) = 0.0
        _SSM("Sky Smooth Middle", Range(0.0,2.0)) = 0.0
        

        [Header(Textures)]
        _MainTex ("Main Texture", 2D) = "white" {}


        [Header(Sun Control)]
        _SunSize("Sun Size", Range(0.0,1.0)) = 1.0
        _SunClipSize("Sun Clip Size", Range(0.0,1.0)) = 1.0
        [HDR] _SunColor("Sun Color", Color) = (1,1,1,1)
        //_SunPos("Sun Position", Vector) = (0,0,0,0)
        _SunClipPos("Sun Clip Position", Vector) = (0,0,0,0)
        
    }
    SubShader
    {
        Tags { "ForceNoShadowCasting" = "True" "RenderType"="Background" "Queue"="Background" "PreviewType"="Skybox" }
        LOD 100

        Pass
        {
            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members viewDirection)
            #pragma exclude_renderers d3d11///??? wtf is this, i didnt add this but im on mac and i know on my pc dx11 is what im usually on??? will remove it later if i see prblms
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
                float3 viewDirection : TEXCOORD2;
                //float3 viewDir : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _ColorTop;
            float4 _ColorMid;
            float4 _ColorBot;

            /*
            float _PushTop;
            float _PushBot;
            float _SkyOffset;
            */

            float _SunSize;
            float _SunClipSize;
            float4 _SunColor;
            //float4 _SunPos;
            float4 _SunClipPos;

            float _SSM;
            float _SST;

            float _Moffset;
            float _Toffset;



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                //o.viewDirection = _WorldSpaceCameraPos - o.worldPos;
                o.viewDirection = WorldSpaceViewDir(v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float3 inverseLerp(float3 a, float3 b, float3 v)
            {
                return (v - a) / (b - a);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = normalize(i.worldPos);
                float arcSineY = asin(worldPos.y)/(PI/2); //PI/2;
                float arcTan2X = atan2(worldPos.x,worldPos.z)/TAU;
                float2 skyUV = float2(arcTan2X,arcSineY);
                // sample the texture
                float2 scrollUV = skyUV;
                scrollUV.y += _Time.y * 0.1;
                fixed4 col = tex2D(_MainTex, scrollUV);
                
                //What I usually do for skybox cols
                //float iLerp = inverseLerp(_PushTop,_PushBot,skyUV.y) + _SkyOffset;
                //float3 color = lerp(_ColorBot.rgb, _ColorTop.rgb, saturate(iLerp));
                
                //New Skybox cols that im trying out
                float middleThreshold = smoothstep(0.0, 0.5 - (1.0 - _SSM) / 2.0, skyUV.y - _Moffset);
                float topThreshold = smoothstep(0.5, 1.0 - (1.0 - _SST) / 2.0 , skyUV.y - _Toffset);
                fixed4 skyCol = lerp(_ColorBot, _ColorMid, middleThreshold);
                skyCol = lerp(skyCol, _ColorTop, topThreshold);
 
                //Skybox Sun 
                float3 worldSun = acos(dot(-_WorldSpaceLightPos0,normalize(i.viewDirection)));
                //float3 clipSun = acos(dot(normalize(_SunClipPos - _WorldSpaceLightPos0),normalize(i.viewDirection)));
                float4 stepSun = float4(1 - step(_SunSize,worldSun),1);
                //float4 sSun = float4(1 - smoothstep(_SunSize - 0.01,_SunSize + 0.01,worldSun),1);
                float4 stepclipSun = float4(1 - step(_SunClipSize,worldSun),1); // since im just makign eclipse i dont need moving clip sun i will reuse world sun. float4 stepclipSun = float4(1 - step(_SunClipSize,clipSun),1);
                //float4 scSun = float4(1 - smoothstep(_SunClipSize - 0.01,_SunClipSize + 0.01,clipSun),1);
                float4 finalSuns = saturate(stepSun - stepclipSun) * (_SunColor * 3);// saturate(sSun - scSun) * _SunColor;
                
                float smoothSun = 1 - smoothstep(_SunClipSize - 0.01,_SunClipSize + 0.01,worldSun);

                //Eclipse Drop Down Beam
                float beam = saturate(stepSun - stepclipSun) * 0.5;

                //Final Colors
                //float4 fc = (skyCol + finalSuns) * (1 - stepclipSun + -0.5) ; //skyCol - stepSun + finalSuns;
                float4 fc = (skyCol - smoothSun) + finalSuns; //(skyCol * (1-stepclipSun)) gives eclipse a feather effect  | (skyCol - stepclipSun) this gives a real eclipse effect 
                //fc += col;

                fc = worldSun.xxxx;

                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);

                return fc;
                //return float4(col,1);
            }
            ENDCG
        }
    }
}
