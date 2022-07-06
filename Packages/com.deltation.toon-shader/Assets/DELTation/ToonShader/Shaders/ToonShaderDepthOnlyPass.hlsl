#ifndef TOON_SHADER_DEPTH_ONLY_PASS_INCLUDED
#define TOON_SHADER_DEPTH_ONLY_PASS_INCLUDED

#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderDepthOnlyPass_AppData.hlsl"

struct v2f
{
    float4 position_cs : SV_POSITION;
    float2 uv : TEXCOORD0;
};

#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderUtils.hlsl"
#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderUtilsV2f.hlsl"

v2f DepthOnlyVertex(appdata input)
{
    v2f output;
    UNITY_SETUP_INSTANCE_ID(input);

    #ifdef TOON_SHADER_HOOK_VERTEX_INPUT
    TOON_SHADER_HOOK_VERTEX_INPUT;
    #endif

    output.position_cs = TransformObjectToHClip(input.positionOS.xyz);
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
