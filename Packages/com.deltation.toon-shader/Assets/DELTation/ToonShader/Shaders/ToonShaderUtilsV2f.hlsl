#ifndef TOON_SHADER_UTILS_V2F_INCLUDED
#define TOON_SHADER_UTILS_V2F_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

inline void alpha_discard(v2f input)
{
    #ifdef _ALPHATEST_ON
    const half4 base_color = _BaseColor;
    const half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * base_color;
    const half cutoff = _Cutoff;
    AlphaDiscard(albedo.a, cutoff);
    #endif
}

inline Light get_main_light(in v2f input SHADOW_MASK_PARAM)
{
    float4 shadow_coord;
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    shadow_coord = input.shadowCoord;
    #elif defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT)
    shadow_coord = ComputeScreenPos(input.positionCS);
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    shadow_coord = TransformWorldToShadowCoord(input.positionWSAndFogFactor.xyz);
    #else
    shadow_coord = float4(0, 0, 0, 0);
    #endif

    #ifdef USE_SHADOW_MASK
    return GetMainLight(shadow_coord, input.positionWSAndFogFactor.xyz, shadow_mask);
    #else
    
    // ReSharper disable once CppLocalVariableMayBeConst
    Light light = GetMainLight(shadow_coord);
    
    #ifdef MAIN_LIGHT_CALCULATE_SHADOWS
    light.shadowAttenuation = lerp(light.shadowAttenuation, 1, GetShadowFade(input.positionWSAndFogFactor.xyz));
    #endif
    
    return light;
    
    #endif
}

#endif
