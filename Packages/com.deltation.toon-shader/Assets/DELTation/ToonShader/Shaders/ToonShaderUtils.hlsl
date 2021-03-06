﻿#ifndef TOON_SHADER_UTILS_INCLUDED
#define TOON_SHADER_UTILS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

inline float get_fog_factor(float depth)
{
    #ifdef _FOG
    return ComputeFogFactor(depth);
    #else
    return 0;
    #endif
}

inline half4 get_additional_lights_color_attenuation(const float3 position_ws)
{
    half4 color_attenuation = 0;

    const int additional_lights_count = GetAdditionalLightsCount();
    for (int i = 0; i < additional_lights_count; ++i)
    {
        const Light light = GetAdditionalLight(i, position_ws);
        const half attenuation = light.distanceAttenuation * light.shadowAttenuation;
        color_attenuation += half4(light.color, attenuation);
    }

    return color_attenuation;
}

inline Light get_main_light(in v2f input)
{
    float4 shadow_coord;
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    shadow_coord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    shadow_coord = TransformWorldToShadowCoord(input.positionWSAndFogFactor.xyz);
    #else
    shadow_coord = float4(0, 0, 0, 0);
    #endif
    return GetMainLight(shadow_coord);
}

inline half3 get_simple_ramp(half3 color, half opacity, half thickness, half smoothness, half value)
{
    smoothness *= thickness;
    color *= opacity;
    return color * smoothstep(1 - thickness, 1 - thickness + smoothness, value);
}

inline half get_specular(half3 view_direction_ws, half3 normal_ws, half3 light_direction_ws)
{
    const half3 half_vector = normalize(view_direction_ws + light_direction_ws);
    return saturate(dot(normal_ws, half_vector));
}

inline half3 get_specular_color(half3 light_color, half3 view_direction_ws, half3 normal_ws, half3 light_direction_ws)
{
    #ifndef _SPECULAR
    return 0;

    #else
    half specular = get_specular(view_direction_ws, normal_ws, light_direction_ws);
    specular = pow(specular, _SpecularExponent);
    const half3 ramp = get_simple_ramp(light_color, _SpecularColor.a, _SpecularThreshold, _SpecularSmoothness, specular);
    return _SpecularColor.xyz * ramp;
    #endif
}

inline half get_fresnel(half3 view_direction_ws, half3 normal_ws)
{
    return 1 - saturate(dot(view_direction_ws, normal_ws));
}

inline half3 get_fresnel_color(half3 light_color, half3 view_direction_ws, half3 normal_ws, half brightness)
{
    #ifndef _FRESNEL
    return 0;
    #else
    const half fresnel = get_fresnel(view_direction_ws, normal_ws);
    return _FresnelColor.xyz * get_simple_ramp(light_color, _FresnelColor.a, _FresnelThickness, _FresnelSmoothness, brightness * fresnel);
    #endif
}

inline half get_ramp(half value)
{
    #ifdef _RAMP_MAP
    return (value + 1) * 0.5;
    #elif defined(_RAMP_TRIPLE)
    const half ramp0 = smoothstep(_Ramp0, _Ramp0 + _RampSmoothness, value);
    const half ramp1 = smoothstep(_Ramp1, _Ramp1 + _RampSmoothness, value);
    return (ramp0 + ramp1) * 0.5;
    #else
    return smoothstep(_Ramp0, _Ramp0 + _RampSmoothness, value);
    #endif
}

inline half get_brightness(const half4 position_cs, half3 normal_ws, half3 light_direction, half main_light_attenuation,
                           half additional_lights_attenuation)
{
    const half dot_value = dot(normal_ws, light_direction);
    half brightness = min(dot_value, dot_value * main_light_attenuation);

    #ifdef TOON_ADDITIONAL_LIGHTS
    brightness += additional_lights_attenuation;
    #endif

    #if defined(_SCREEN_SPACE_OCCLUSION)
    const float2 normalized_screen_space_uv = GetNormalizedScreenSpaceUV(position_cs);
    const AmbientOcclusionFactor ao_factor = GetScreenSpaceAmbientOcclusion(normalized_screen_space_uv);
    brightness = min(brightness, brightness * ao_factor.directAmbientOcclusion * ao_factor.indirectAmbientOcclusion);
    #endif

    return get_ramp(brightness);
}

#endif