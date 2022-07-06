#ifndef TOON_SHADER_DEPTH_NORMALS_PASS_INCLUDED
#define TOON_SHADER_DEPTH_NORMALS_PASS_INCLUDED

#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderDepthNormalsPass_AppData.hlsl"

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

    #ifdef TOON_SHADER_HOOK_VERTEX_INPUT
    TOON_SHADER_HOOK_VERTEX_INPUT;
    #endif

    output.position_cs = TransformObjectToHClip(input.positionOS.xyz);
    output.normal_ws = TransformObjectToWorldNormal(input.normalOS);
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
