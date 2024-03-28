Shader "Unlit/EclipseSunSphere"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 viewDir : TEXCOORD2;
                float3 normal : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = mul(UNITY_MATRIX_MV, float4(o.normal, 0.0));//float4(o.normal, 1.0));
                
                //o.normal = v.normal;
                //o.viewDir = normalize(UnityWorldSpaceViewDir(v.vertex));

                //float3 n = UnityObjectToWorldNormal(v.normal);
                //float3 viewVec = UnityWorldToViewPos(n);
                //o.viewDir = normalize(mul((float3x3)UNITY_MATRIX_MV, -n));
                //o.viewDir = (mul((float3x3)UNITY_MATRIX_V, -v.normal));
                //o.viewDir = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, -n));

                
                
                
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                
                return i.viewDir;
                return float4(i.normal,1);
            }
            ENDCG
        }
    }
}
