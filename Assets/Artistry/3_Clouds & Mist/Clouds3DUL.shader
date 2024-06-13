Shader "Unlit/Clouds3DUL"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _3DCloudTex ("3D Texture", 3D) = "white" {}
        _3DCloudOffset("3D Texture Offset", Vector) = (0,0,0,0)
        _SpherePos("Sphere Position", Vector) = (0,1,8,1)
        _PlanePos("Plane Position", Vector) = (0,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend One OneMinusSrcAlpha
        //Cull Off

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
                float3 hitPos : TEXCOORD2;

            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler3D _3DCloudTex;
            float4 _3DCloudTex_ST;

            float4 _SpherePos;
            float4 _PlanePos;
            float4 _3DCloudOffset;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                o.camPos = mul(unity_ObjectToWorld, float4(_WorldSpaceCameraPos,1));
                o.hitPos = v.vertex;
                
                return o;
            }

            #define PI 3.1415926535897932384626433832795
            #define TWO_PI 6.283185307179586476925286766559
            #define MARCH_SIZE 0.07
            #define MAX_DIST 1000.0
            #define MIN_DIST 0.01

            float sdSphere(float3 p, float radius) {return length(p) - radius;}

            float rand (in float2 st) {return frac(sin(dot(st.xy,float2(12.9898,78.233)))* 43758.5453123);}

            float noise(float3 x ) 
            {
                float3 p = floor(x);
                float3 f = frac(x);
                f = f * f * (3. - 2. * f);

                float2 uv = (p.xy + float2(37.0, 239.0) * p.z) + f.xy;
                float2 tex = tex2D(_MainTex,float2((uv + 0.5) / 256.0)).yx;

                return lerp( tex.x, tex.y, f.z ) * 2.0 - 1.0;
            }

            float noise3D( float3 x )
            {
                int3 i = int3(floor(x));
                float3 f = frac(x);
                f = f*f*(3.0-2.0*f);
                
                return lerp(lerp(lerp( rand(i+int3(0,0,0)), 
                                    rand(i+int3(1,0,0)),f.x),
                            lerp( rand(i+int3(0,1,0)), 
                                    rand(i+int3(1,1,0)),f.x),f.y),
                        lerp(lerp( rand(i+int3(0,0,1)), 
                                    rand(i+int3(1,0,1)),f.x),
                            lerp( rand(i+int3(0,1,1)), 
                                    rand(i+int3(1,1,1)),f.x),f.y),f.z);
            }

            float fbm(float3 p) 
            {
            float3 q = p + _Time.y * 0.5 * float3(1.0, -0.2, -1.0);
            float g = noise3D(q);//using noise(q) insted of noise3D will give you 2d-like noise

            float f = 0.0;
            float scale = 0.5;
            float factor = 2.02;

            for (int i = 0; i < 4; i++) {
                f += scale * noise3D(q);//using noise(q) insted of noise3D will give you 2d-like noise
                q *= factor;
                factor += 0.21;
                scale *= 0.5;
            }

            return f;
            }


            float GetDistance(float3 pos)
            {   
                float3 sp = _SpherePos.xyz;
                float dSphere = length(pos - (sp)) - _SpherePos.w;
                /*float dPlane = pos.y - _PlanePos.y;
                float distanceToScene = min(dSphere, dPlane);
                return distanceToScene;*/

                //float f = fbm(pos);
                //return -dSphere;// + f;

                float f = fbm(pos);
                return -dSphere + f;
            }

            /*
            float4 CloudMarch(float3 rayOrigin, float3 rayDirection, uint maxSteps)
            {
                float depth = 0.0;
                float3 p = rayOrigin + depth * rayDirection;             // standard point calculation dO is the offset for direction or magnitude

                float4 cols = float4(0,0,0,0);

                for (uint i = 0; i < maxSteps; i++)
                {
                    float dist = GetDistance(p);                             
                    
                    if(dist > 0)
                    {
                        float4 color = float4(lerp(float3(1.0,1.0,1.0), float3(0.0, 0.0, 0.0), dist), dist );
                        color.rgb *= color.a;
                        cols += color * (1.0 - cols.a);
                    }
                    /*else
                    {
                        discard;
                    } *//*

                    float density3D = tex3D(_3DCloudTex, p).r;
                    depth += MARCH_SIZE + density3D;
                    p = rayOrigin + depth * rayDirection;
                }
                return cols;
            }
            */


            float raymarchv1(float3 ro, float3 rd, float steps, float stepsize, float densityScale, float4 sphere)
            {
                float density = 0;
                for (int i = 0; i<steps; i++)
                {
                    ro += rd * stepsize;
                    float sphereSDF = distance(ro, sphere.xyz);
                    if(sphereSDF < sphere.w){
                        density += 0.1;
                    }
                }

                return float(density * densityScale);
            }

            float raymarchv2(float3 ro, float3 rd, float steps, float stepsize, float densityScale, sampler3D _3DCloudTex, float3 offset)
            {
                float density = 0;
                float transmission = 0;
                for (int i = 0; i<steps; i++)
                {
                    ro += rd * stepsize;

                    float sampDensity = tex3D(_3DCloudTex, ro + offset  - (fbm(ro) * 0.1) ).r ;    
                    density += sampDensity ;
                }

                return float(density * densityScale);
            }


            fixed4 frag (v2f i) : SV_Target
            {
                //return rand(i.uv);
                float2 uv = i.uv;
                float2 cuv = i.uv - 0.5;
                /*// flat 2d coordinate system
                float3 camPos = float3(0,0,0);//i.camPos;
                float3 camDir = normalize(float3(cuv.xy,1));
                */
                
                //Swapping to 3D coordinate system
                float3 camPos = i.camPos;
                float3 camDir = normalize(i.hitPos - camPos);
            

                //Cloud RM
                float3 color = float3(1,1,1);

                //float4 cm = raymarchv2(camPos,camDir,64,0.02,0.2,_SpherePos);//CloudMarch3D(camPos,camDir,25);
                float4 cm = raymarchv2(camPos,camDir,128,0.02,0.03,_3DCloudTex,_3DCloudOffset);

                return float4(cm.rgb,cm.a);

                /*
                float rm = CloudMarch(camPos,camDir,50);
                float3 p = camPos + camDir * rm;
                float fc = 1 - rm * 0.1;
                //clip (fc -0.01);
                return fc;*/
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