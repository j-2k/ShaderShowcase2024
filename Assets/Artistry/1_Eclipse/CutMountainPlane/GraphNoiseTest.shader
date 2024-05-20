/*
This shader is basically a over-engineered/garbage solution to making fake mountains on a plane that is affected by fog
I only chose to do this to test my math skills, so yeah, dont actually use this trash lmao
*/

Shader "Unlit/GraphNoiseTest"
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
                return frac(sin(dot(st,
                                    float2(12.9898,78.233)))
                            * 43758.5453123);
            }


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                //the better solution would be to just use a texture on a plane and cut or place fake garbage far away but I dont wanna do that,
                //I want to try the maths for a fake mountain

                float2 uv = i.uv*1;
                uv.x *= 20;
                float4 col = 0;
                
               
                float l = (rand(floor(uv.x)));
                l = smoothstep(l+0.01,l-0.01,uv.y);


                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                //book of shaders
                //float ix = floor(uv.x);  // integer
                //float fx = frac(uv.x);  // fraction
                //return rand(floor(uv.x));
                //return lerp(rand(ix), rand(ix + 1.0), fx);
                //return lerp(rand(ix), rand(ix + 1.0), smoothstep(0.,1.,fx));
                //float u = fx * fx * (3.0 - 2.0 * fx); // custom cubic curve
                //return lerp(rand(ix), rand(ix + 1.0), u);
                
                clip(l-0.1);

                return l;

            }
            ENDCG
        }
    }
}
