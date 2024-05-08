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

        [Header(Scroll Control Testing)]
        Scroll1("Scroll 1", Range(-1.0,1.0)) = 0.0
        Scroll2("Scroll 2", Range(-1.0,1.0)) = 0.0
        Scroll3("Scroll 3", Range(-1.0,1.0)) = 0.0
        
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

            float Scroll1;
            float Scroll2;
            float Scroll3;



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
 
                //Skybox Sun - I learned what this line below does finally lmao go to notes below to see. 
                float3 worldSun = acos(dot(-_WorldSpaceLightPos0,normalize(i.viewDirection)));
                //float3 clipSun = acos(dot(normalize(_SunClipPos - _WorldSpaceLightPos0),normalize(i.viewDirection)));
                float4 stepSun = float4(1 - step(_SunSize,worldSun),1);
                //float4 sSun = float4(1 - smoothstep(_SunSize - 0.01,_SunSize + 0.01,worldSun),1);
                float4 stepclipSun = float4(1 - step(_SunClipSize,worldSun),1); // since im just makign eclipse i dont need moving clip sun i will reuse world sun. float4 stepclipSun = float4(1 - step(_SunClipSize,clipSun),1);
                //float4 scSun = float4(1 - smoothstep(_SunClipSize - 0.01,_SunClipSize + 0.01,clipSun),1);
                float4 finalSuns = saturate(stepSun - stepclipSun) * (_SunColor * 3);// saturate(sSun - scSun) * _SunColor;
                
                float smoothSun = 1 - smoothstep(_SunClipSize - 0.01,_SunClipSize + 0.01,worldSun);

                //Eclipse Drop Down Beam
                float2 beamLine = float2(Scroll1,clamp(skyUV.y,Scroll2,worldSun.y));
                float beamDistStep = 1 - smoothstep(0.009,0.011,distance(skyUV,beamLine));

                //Final Colors
                //float4 fc = (skyCol + finalSuns) * (1 - stepclipSun + -0.5) ; //skyCol - stepSun + finalSuns;
                float4 fc = (skyCol - smoothSun) + finalSuns; //(skyCol * (1-stepclipSun)) gives eclipse a feather effect  | (skyCol - stepclipSun) this gives a real eclipse effect 
                //fc += col;

                //fc = worldSun.xxxx;
                fc += beamDistStep;// + stepclipSun.xxxx;

                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);

                return fc;
                //return float4(col,1);
            }
            ENDCG
        }
    }
}


//Notes:

//Explaining worldSun & specifically the arccosine function being used since that didnt make sense to me at first.
//Basically, we do a dot product between 2 vectors, simple, but then we get the inverse cosine of that dot product.
//The reason is because we want to solve for theta & the inverse cosine must be used to solve for theta check the formula below.
//The dot product of 2 normalized vectors is the cosine of the angle between them
//MUTLIPLE EXAMPLES BELOW, FORMULA FOR FINDING ANGLE BETWEEN 2 VECTORS => Cos(THETA) = A.B / |A||B|
//SOLVING FOR THETA AKA THE ANGLE BETWEEN THE 2 VECTORS (LIGHT & VIEW DIRECTION)
//=> Assume (A.B / |A||B|) = 1 =>       Cos(THETA) = 1 =>       THETA = arccos(1) =>        THETA = 0 deg or 0 rad (or their full revolution counterparts 360 deg or 2pi rad)
//Flipped Example:
//=> Assume (A.B / |A||B|) = 0 =>       Cos(THETA) = 0 =>       THETA = arccos(0) =>        THETA = 90 deg or pi/2 rad
//Peculiar Example:
//=> Assume (A.B / |A||B|) = 0.2345 =>  Cos(THETA) = 0.2345 =>  THETA = arccos(0.2345) =>   THETA = ~76.81 deg or ~1.341 rad

//Even though the above is fairly simple, I think its kinda important to know whats going on, but the thing that really needs explanation is spherical coordinates.
//Spherical coordinates are a way to represent 3D space using 2 angles & a radius, the angles are theta & phi, the radius is r.
//theta is the angle in the xz plane from the positive z axis, phi is the angle from the positive y axis.
/*
    float phi = atan(FragPos.z, FragPos.x); // Longitude
    float theta = acos(FragPos.y); // Latitude
    float u = (phi + pi) / (2.0 * pi); // Normalize longitude to [0, 1]
    float v = (theta + pi / 2.0) / pi; // Normalize latitude to [0, 1]
*/

