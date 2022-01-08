#ifndef TOON_SHADER_DEPTH_ONLY_PASS
#define TOON_SHADER_DEPTH_ONLY_PASS

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct appdata
{
    float4 position : POSITION;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 position_cs : SV_POSITION;
    float2 uv : TEXCOORD0;
};

#include "./ToonShaderUtils.hlsl"
#include "./ToonShaderUtilsV2f.hlsl"

v2f DepthOnlyVertex(appdata input)
{
    v2f output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.position_cs = TransformObjectToHClip(input.position.xyz);
    const float4 basemap_st = _BaseMap_ST;
    output.uv = apply_tiling_offset(input.uv, basemap_st);
    return output;
}

half4 DepthOnlyFragment(v2f input) : SV_TARGET
{
    alpha_discard(input);
    return 0;
}

#endif
