Shader "Unlit/FarAway"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+10" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            //#include "Assets/ShaderDebugger/debugger.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                sample float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            sampler2D _FarAwayPlanarColor, _FarAwayPlanarDepth;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float4 world = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = world.xyz / world.w;
                return o;
            }

            float LinearEyeDepthForDepthTexture(float z)
            {
                const float near = 8;
                const float far = 10000;

                const float b = 1 / far;
                const float a = 1 / near;

                return 1.0 / ((a - b) * z + b);
            }

            float DepthSampleFromWorldPos(float3 world_pos)
            {
                float2 uv = world_pos.xy / world_pos.z;
                uv = uv * 0.5 + 0.5;
                float smpl = SAMPLE_DEPTH_TEXTURE(_FarAwayPlanarDepth, uv);
                return LinearEyeDepthForDepthTexture(smpl);
            }

            float4 ColorSampleFromWorldPos(float3 world_pos)
            {
                float2 uv = world_pos.xy / world_pos.z;
                uv = uv * 0.5 + 0.5;
                return tex2D(_FarAwayPlanarColor, uv);
            }

            bool TestHit(float3 world_pos, inout float3 hit_point)
            {
                if (DepthSampleFromWorldPos(world_pos) <= world_pos.z)
                {
                    hit_point = world_pos;
                    return true;
                }
                else
                    return false;
            }

            /*float rand_1_05(in float2 uv)
            {
                float2 noise = (frac(sin(dot(uv, float2(12.9898, 78.233)*2.0)) * 43758.5453));
                return abs(noise.x + noise.y) * 0.5;
            }*/

            float4 sample_at_pixel(float3 world_pos, out float depth)
            {
                float3 eye1 = world_pos - _WorldSpaceCameraPos;
                float3 unit1 = eye1 / eye1.z;   /* normalize z */

                float extra_z_prev = 0;
                float extra_z;
                int j;
                //float j_factor = rand_1_05(i.vertex.xy) * 0.1 + 0.9;
                float3 hit_point = world_pos + unit1 * 20000;

                [unroll] for (j = 0; j < 27; j++)
                {
                    extra_z = pow(1.4, j + 1) /* * j_factor*/ - 1.0;
                    if (TestHit(world_pos + unit1 * extra_z, hit_point))
                        break;
                    extra_z_prev = extra_z;
                }

                [unroll] for (int k = 0; k < 8; k++)
                {
                    float extra_z_middle = (extra_z_prev + extra_z) * 0.5;
                    if (TestHit(world_pos + unit1 * extra_z_middle, hit_point))
                    {
                        extra_z = extra_z_middle;
                    }
                    else
                    {
                        extra_z_prev = extra_z_middle;
                    }
                }


                /*uint root = DebugFragment(i.vertex);
                DbgValue1(root, extra_z_prev);*/
                /*return float4(0, extra_z_prev / 30.0, 0, 1);*/


                float3 pixel_position = world_pos + unit1 * extra_z_prev;
                float4 col = ColorSampleFromWorldPos(pixel_position);

                /*if (col.a < 0.5)
                {
                    depth = 0;
                    return fixed4(0, 0, 0, 1);
                }*/

                //clip(col.a - 0.5);


                /* inverse of LinearEyeDepth(depth) = 1.0 / (_ZBufferParams.z * depth + _ZBufferParams.w); */
                float z1 = dot(hit_point - _WorldSpaceCameraPos, unity_CameraWorldClipPlanes[5].xyz);
                depth = (1.0 / z1 - _ZBufferParams.w) / _ZBufferParams.z;

                return col;



                /*
                float2 uv = i.worldPos.xy / near;
                uv = uv * 0.5 + 0.5;

                float smpl = SAMPLE_DEPTH_TEXTURE(_FarAwayPlanarDepth, uv);
                float depth = LinearEyeDepthForDepthTexture(smpl);

                uint root = DebugFragment(i.vertex);
                DbgValue2(root, float2(smpl, depth));

                return float4(0, depth / 20, 0.6, 1);*/




                /*const float plane_depth = 8;
                float3 unit_delta = (_WorldSpaceCameraPos - i.worldPos) / plane_depth;*/



                /*return float4(1, 0, 0, 1);*/
            }


            fixed4 frag(v2f i, out float depth : SV_DepthLessEqual) : SV_Target
            {
                float3 dx = ddx(i.worldPos);
                float3 dy = ddy(i.worldPos);

                float depth0, depth1, depth2, depth3;
                float4 col0, col1, col2, col3;

                col0 = sample_at_pixel(i.worldPos - 0.125 * dx - 0.375 * dy, depth0);
                col1 = sample_at_pixel(i.worldPos + 0.125 * dx + 0.375 * dy, depth1);
                col2 = sample_at_pixel(i.worldPos + 0.375 * dx - 0.125 * dy, depth2);
                col3 = sample_at_pixel(i.worldPos - 0.375 * dx + 0.125 * dy, depth3);

                depth = (depth0 + depth1 + depth2 + depth3) * 0.25;
                return (col0 + col1 + col2 + col3) * 0.25;
            }
            ENDCG
        }
    }
}
