Shader "Unlit/CloudsUL"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpherePos("Sphere Position", Vector) = (0,1,8,1)
        _PlanePos("Plane Position", Vector) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
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
                //UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 camPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _SpherePos;
            float4 _PlanePos;

            v2f vert (appdata v)
            {
                v2f o;
                o.camPos = _WorldSpaceCameraPos;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                
                return o;
            }

            #define PI 3.1415926535897932384626433832795
            #define TWO_PI 6.283185307179586476925286766559
            #define MAX_DIST 1000.0
            #define MIN_DIST 0.01

            float sdSphere(float3 p, float radius) {
                return length(p) - radius;
            }

            float GetDistance(float3 pos)
            {   
                float3 sp = _SpherePos.xyz;
                float dSphere = length(pos - (sp)) - _SpherePos.w;
                float dPlane = pos.y - _PlanePos.y;

                float distanceToScene = min(dSphere, dPlane);
                return distanceToScene;
            }

            float RayMarch (float3 rayOrigin, float3 rayDirection, uint maxSteps)
            {
                float dO = 0.0; //Distance from Origin
                float dS = 0.0; //Distance from Scene
                for (uint i = 0; i < maxSteps; i++)
                {
                    float3 p = rayOrigin + rayDirection * dO;             // standard point calculation dO is the offset for direction or magnitude
                    dS = GetDistance(p);                             
                    dO += dS;
                    if (dS < MIN_DIST|| dO > MAX_DIST) break;            // if we are close enough to the surface or too far away, break
                }
                
                return dO;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float2 cuv = i.uv * 2 - 1;
                float3 camPos = float3(0,0,0);//i.camPos;
                float3 camDir = normalize(float3(cuv.xy,1));

                float rm = RayMarch(camPos,camDir,50);
                float3 p = camPos + camDir * rm;
                return rm*0.1;
                //return float4(p,1);
                
                //return float4(uv,0,1);
                /*
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
                */
            }
            ENDCG
        }
    }
}