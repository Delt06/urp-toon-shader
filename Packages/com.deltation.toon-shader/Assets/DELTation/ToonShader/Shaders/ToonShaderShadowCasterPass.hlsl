#ifndef TOON_SHADER_SHADOW_CASTER_PASS
#define TOON_SHADER_SHADOW_CASTER_PASS

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

float3 _LightDirection;

struct appdata
{
    float4 position_os : POSITION;
    float3 normal_os : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 position_cs : SV_POSITION;
};

#include "./ToonShaderUtils.hlsl"

float4 get_shadow_position_h_clip(appdata input)
{
    const float3 position_ws = TransformObjectToWorld(input.position_os.xyz);
    const float3 normal_ws = TransformObjectToWorldNormal(input.normal_os);

    float4 position_cs = TransformWorldToHClip(ApplyShadowBias(position_ws, normal_ws, _LightDirection));

    #if UNITY_REVERSED_Z
    position_cs.z = min(position_cs.z, position_cs.w * UNITY_NEAR_CLIP_VALUE);
    #else
    position_cs.z = max(position_cs.z, position_cs.w * UNITY_NEAR_CLIP_VALUE);
    #endif

    return position_cs;
}

v2f ShadowPassVertex(const appdata input)
{
    v2f output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.position_cs = get_shadow_position_h_clip(input);
    return output;
}

half4 ShadowPassFragment(v2f input) : SV_TARGET
{
    return 0;
}

#endif
