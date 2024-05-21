/*
This shader is basically a over-engineered/garbage solution to making fake mountains on a plane that is affected by fog
I only chose to do this to test my math skills, so yeah, dont actually use this trash lmao
*/

Shader "Unlit/ShapeNoiseTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        LOD 100

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float rand (in float2 st) {
                return frac(sin(dot(st.xy,
                                    float2(12.9898,78.233)))
                            * 43758.5453123);
            }



        float2 rand2(float2 st){
            st = float2( dot(st,float2(127.1,311.7)),
                    dot(st,float2(269.5,183.3)) );
            return -1.0 + 2.0*frac(sin(st)*43758.5453123);
        }

        float noiseIQ(float2 st) {
            float2 i = floor(st);
            float2 f = frac(st);

            float2 u = f*f*(3.0-2.0*f);

            return lerp( lerp( dot( rand2(i + float2(0.0,0.0) ), f - float2(0.0,0.0) ),
                            dot( rand2(i + float2(1.0,0.0) ), f - float2(1.0,0.0) ), u.x),
                        lerp( dot( rand2(i + float2(0.0,1.0) ), f - float2(0.0,1.0) ),
                            dot( rand2(i + float2(1.0,1.0) ), f - float2(1.0,1.0) ), u.x), u.y);
        }


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                //the better solution would be to just use a texture on a plane and cut or place fake garbage far away but I dont wanna do that,
                //I want to try the maths for a fake mountain
                float2 uv = i.uv;
                uv.x *= 10;
                
                float2 noiseUV = uv * 5 + 6;
                //noiseUV.x -= _Time.y*0.1;
                //noiseUV.y -= _Time.y*0.1;
                float n = noiseIQ(noiseUV) * .5 + .5;
                
                //float2 uvc = i.uv * 2 - 1;
                //uvc *= 2;
                //float c = smoothstep(0.51,0.5,length(uvc) - (n * 1)) ;// ;
                float m = abs(uv.x - 5) - (uv.y - 0.4) * 0.3;
                m = saturate(m);
                float c = smoothstep(1,.05,(uv.y + 0.7) - (n * 0.4) + (1 - m) * 0.25) ;// ;
                clip(c - 0.001);
                float4 col = c;
                col *= _Color;
                //return col;
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
                



            }
            ENDCG
        }
    }
}
