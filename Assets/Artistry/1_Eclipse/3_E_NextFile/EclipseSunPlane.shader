Shader "Unlit/EclipseSun"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                float2 uv = i.uv * 10 - 5;
                float2 offset = float2(cos(_Time.y/2.0),sin(_Time.y/2.0));;

                float3 light_color = float3(0.9, 0.65, 0.5);
                float light = 0.1 / distance(normalize(uv), uv);
                
                if(length(uv) < 1.0){
                    light *= 0.1 / distance(normalize(uv-offset), uv-offset);
                }
                //clip(light-0.03);
                return float4(light*light_color, 1.0);
            }
            ENDCG
        }
    }
}
