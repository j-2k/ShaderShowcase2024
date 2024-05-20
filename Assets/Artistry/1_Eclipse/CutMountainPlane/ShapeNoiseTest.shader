/*
This shader is basically a over-engineered/garbage solution to making fake mountains on a plane that is affected by fog
I only chose to do this to test my math skills, so yeah, dont actually use this trash lmao
*/

Shader "Unlit/ShapeNoiseTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
                float2 uv = float2(i.uv*8);
            
                float n = noiseIQ(uv) * .5 + .5;

                return float4(n.xxx,1);


                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                
                



            }
            ENDCG
        }
    }
}
