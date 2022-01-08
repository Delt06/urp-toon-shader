#ifndef TOON_SHADER_DEPTH_NORMALS_PASS
#define TOON_SHADER_DEPTH_NORMALS_PASS

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct appdata
{
    float4 position_os : POSITION;
    float4 tangent_os : TANGENT;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 position_cs : SV_POSITION;
    float3 normal_ws : TEXCOORD2;
    float2 uv : TEXCOORD0;
};

#include "./ToonShaderUtils.hlsl"
#include "./ToonShaderUtilsV2f.hlsl"

v2f DepthNormalsVertex(appdata input)
{
    v2f output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.position_cs = TransformObjectToHClip(input.position_os.xyz);

    const VertexNormalInputs normal_input = GetVertexNormalInputs(input.normal, input.tangent_os);
    output.normal_ws = NormalizeNormalPerVertex(normal_input.normalWS);
    const float4 basemap_st = _BaseMap_ST;
    output.uv = apply_tiling_offset(input.uv, basemap_st);

    return output;
}

float4 DepthNormalsFragment(const v2f input) : SV_TARGET
{
    alpha_discard(input);
    return float4(PackNormalOctRectEncode(TransformWorldToViewDir(input.normal_ws, true)), 0.0, 0.0);
}

#endif
