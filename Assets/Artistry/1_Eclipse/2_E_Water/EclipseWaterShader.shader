Shader "Unlit/EclipseWaterShader"
{
    //Effects that need to be considered this is just a basis, indented with priority
    //Reflection                Medium
    //Refraction & Light Dir    High
    //Fresnel Effect            High
    //Wave Pattern              High
    //Water Depth               Low
    //Specular Highlights       X
    //Foam                      Low
    //Distance Fog              High
    //===Extras?===
    //Shadow Receiving / NOT Casting!
    //Simple Shallow Underwater effects (NOT underwater camera!)
    //Underwater Caustics!!! (THIS IS A VERY NICE IDEA, I read about caustics & forgot about them, AI reminded me here lol)

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ColorTop("Shallow Color", Color) = (0.501, 0.827, 0.968,1)//Surface light blue water(0.501, 0.827, 0.968,1)
        _ColorBot("Deep Color", Color) = (0.031, 0.101, 0.349,1)//Deep dark blue water(0.031, 0.101, 0.349,1)
        _ColorHorizon("Fresnel Horizon Color", Color) = (1, 0.1, 0.2,1)
        _DepthFadeDist("Depth Fade Distance", Range(0.001, 10)) = 0.5
        _FresenlPow("Fresnel Power", Range(0.001, 10)) = 0.5
    }
    SubShader
    {
        // Tags 
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        // Grab the screen behind the object into _GrabTexture
        //GrabPass{"_GrabTexture"}
        LOD 100
        ZTest LEqual
        ZWrite On
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                float3 normal : TEXCOORD5;
                //float4 grabPos : TEXCOORD6;
            };

            sampler2D _CameraDepthTexture;
            sampler2D _GrabTexture;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _ColorTop;
            float4 _ColorBot;
            float4 _ColorHorizon;
            float _DepthFadeDist;
            float _FresenlPow;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.screenPos = ComputeScreenPos(o.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //o.normal = UnityObjectToWorldNormal(v.normal);
                o.normal = v.normal;
                UNITY_TRANSFER_FOG(o,o.vertex);
                //o.grabPos = ComputeGrabScreenPos((o.vertex)); //grabpass test
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //return col;

                //Get Linear Depth Value
                float depth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;
                //Same > float depth01 = tex2D(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition.xy / i.screenPosition.w)).r;
                float depthFromEyeLinear = LinearEyeDepth(depth01);
                

                float depthDifference = depthFromEyeLinear - i.screenPos.w;
                float depthFade = 1 - saturate(depthDifference/_DepthFadeDist);

                //return float4(lerp(_ColorTop,_ColorBot,depthFade).xyz,depthFade);
                float3 viewVectorWorldSpace = -1 * (_WorldSpaceCameraPos.xyz - i.worldPos);//CARE WE DIDNT NORMALIZE!!!
                //float3 viewVectorViewSpace = normalize(UnityWorldSpaceViewDir(vertexWorldPos));
                
                float3 vvws = (viewVectorWorldSpace/i.screenPos.w) * depthFromEyeLinear;
                float3 worldSpaceScenePos = vvws + _WorldSpaceCameraPos.xyz;
                
                float3 worldWaterPos = i.worldPos - worldSpaceScenePos;
                float worldWaterSurfaceToBottomDepth = worldWaterPos.y * -1;
                worldWaterSurfaceToBottomDepth = saturate(exp(worldWaterSurfaceToBottomDepth/_DepthFadeDist));
                
                float fresenlNode = pow((1.0 - saturate(dot(normalize(i.normal), normalize(i.viewDir)))), _FresenlPow);
                float4 waterDepthColors = lerp(_ColorBot,_ColorTop,worldWaterSurfaceToBottomDepth);
                
                float4 finalColor = lerp(waterDepthColors,_ColorHorizon,fresenlNode);
                return finalColor;
                /* Not sure if im using grab pass correctly but ill keep it here
                float4 sceneColorsTex = tex2Dproj(_GrabTexture, i.grabPos); // to test if scene color is working do (get inverted scene colors) (1-tex2Dproj(_GrabTexture, i.grabPos);)
                float3 underWaterCols = sceneColorsTex.rgb * (1 - finalColor.a);
                return float4(underWaterCols + finalColor.rgb, finalColor.a);
                */


                
            }
            ENDCG
        }
    }
}
