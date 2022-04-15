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
    float2 uv : TEXCOORD0;
    float3 normal_ws : TEXCOORD1;
};

#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderUtils.hlsl"
#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderUtilsV2f.hlsl"

v2f DepthNormalsVertex(appdata input)
{
    v2f output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.position_cs = TransformObjectToHClip(input.position_os.xyz);
    output.normal_ws = TransformObjectToWorldNormal(input.normal);
    const float4 basemap_st = _BaseMap_ST;
    output.uv = apply_tiling_offset(input.uv, basemap_st);

    return output;
}

float4 DepthNormalsFragment(const v2f input) : SV_TARGET
{
    alpha_discard(input);
    return half4(normalize(input.normal_ws), 0);
}

#endif
