#ifndef TOON_SHADER_SHADOW_CASTER_PASS_INCLUDED
#define TOON_SHADER_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

float3 _LightDirection;
float3 _LightPosition;

#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderShadowCasterPass_AppData.hlsl"

struct v2f
{
    float4 position_cs : SV_POSITION;
    float2 uv : TEXCOORD0;
};

#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderUtils.hlsl"
#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderUtilsV2f.hlsl"

float4 get_shadow_position_h_clip(appdata input)
{
    const float3 position_ws = TransformObjectToWorld(input.positionOS.xyz);
    const float3 normal_ws = TransformObjectToWorldNormal(input.normalOS);

    #if _CASTING_PUNCTUAL_LIGHT_SHADOW
    const float3 light_direction_ws = normalize(_LightPosition - position_ws);
    #else
    const float3 light_direction_ws = _LightDirection;
    #endif

    float4 position_cs = TransformWorldToHClip(ApplyShadowBias(position_ws, normal_ws, light_direction_ws));

    #if UNITY_REVERSED_Z
    position_cs.z = min(position_cs.z, position_cs.w * UNITY_NEAR_CLIP_VALUE);
    #else
    position_cs.z = max(position_cs.z, position_cs.w * UNITY_NEAR_CLIP_VALUE);
    #endif

    return position_cs;
}

v2f ShadowPassVertex(appdata input)
{
    v2f output;
    UNITY_SETUP_INSTANCE_ID(input);

    #ifdef TOON_SHADER_HOOK_VERTEX_INPUT
    TOON_SHADER_HOOK_VERTEX_INPUT;
    #endif

    output.position_cs = get_shadow_position_h_clip(input);
    const float4 basemap_st = _BaseMap_ST;
    output.uv = apply_tiling_offset(input.uv, basemap_st);
    return output;
}

half4 ShadowPassFragment(v2f input) : SV_TARGET
{
    alpha_discard(input);
    return 0;
}

#endif
