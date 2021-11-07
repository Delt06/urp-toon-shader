#ifndef TOON_SHADER_UTILS_INCLUDED
#define TOON_SHADER_UTILS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

inline float get_fog_factor(float depth)
{
    #ifdef _FOG
    return ComputeFogFactor(depth);
    #else
    return 0;
    #endif
}

inline float2 apply_tiling_offset(const float2 uv, const float4 map_st)
{
    return uv * map_st.xy + map_st.zw;
}

inline void alpha_discard(v2f input)
{
    #ifdef _ALPHATEST_ON
    const half4 base_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
    const half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * base_color;
    const half cutoff = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
    AlphaDiscard(albedo.a, cutoff);
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
    const half specular_exponent = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SpecularExponent);
    specular = pow(specular, specular_exponent);
    const half4 specular_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SpecularColor);
    const half specular_threshold = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SpecularThreshold);
    const half specular_smothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _SpecularSmoothness);
    const half3 ramp = get_simple_ramp(light_color, specular_color.a, specular_threshold, specular_smothness, specular);
    return specular_color.xyz * ramp;
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
    const half4 fresnel_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FresnelColor);
    const half fresnel_thickness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FresnelThickness);
    const half fresnel_smothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _FresnelSmoothness);
    return fresnel_color.xyz * get_simple_ramp(light_color, fresnel_color.a, fresnel_thickness, fresnel_smothness, brightness * fresnel);
    #endif
}

inline half get_ramp(half value)
{
    #ifdef _RAMP_MAP
    return (value + 1) * 0.5;
    #elif defined(_RAMP_TRIPLE)
    const half ramp0 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Ramp0);
    const half ramp1 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Ramp1);
    const half ramp_smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _RampSmoothness);
    const half ramp0_value = smoothstep(ramp0, ramp0 + ramp_smoothness, value);
    const half ramp1_value = smoothstep(ramp1, ramp1 + ramp_smoothness, value);
    return (ramp0_value + ramp1_value) * 0.5;
    #else
    const half ramp0 = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Ramp0);
    const half ramp_smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _RampSmoothness);
    return smoothstep(ramp0, ramp0 + ramp_smoothness, value);
    #endif
}


inline half get_brightness(const half4 position_cs, half3 normal_ws, half3 light_direction, half main_light_attenuation)
{
    const half dot_value = dot(normal_ws, light_direction);
    // ReSharper disable once CppLocalVariableMayBeConst
    half brightness = min(dot_value, dot_value * main_light_attenuation);

    #if defined(_SCREEN_SPACE_OCCLUSION)
    const float2 normalized_screen_space_uv = GetNormalizedScreenSpaceUV(position_cs);
    const AmbientOcclusionFactor ao_factor = GetScreenSpaceAmbientOcclusion(normalized_screen_space_uv);
    brightness = min(brightness, brightness * ao_factor.directAmbientOcclusion * ao_factor.indirectAmbientOcclusion);
    #endif

    return get_ramp(brightness);
}

#define SAMPLE_RAMP_MAP(brightness) SAMPLE_TEXTURE2D_LOD(_RampMap, sampler_RampMap, half2(brightness, 0.5), 0).rgb

inline half3 get_ramp_color(const half4 position_cs, const half3 normal_ws, const half3 light_direction,
                            const half3 light_color, const half light_attenuation, const half4 shadow_color_opacity,
                            out half brightness)
{
    brightness = get_brightness(position_cs, normal_ws, light_direction, light_attenuation);
    half3 ramp_color = light_color;

    #ifdef _RAMP_MAP
    ramp_color *= SAMPLE_RAMP_MAP(brightness);
    #else
    const half3 shadow_color = lerp(ramp_color, shadow_color_opacity.rgb, shadow_color_opacity.a);
    ramp_color = lerp(shadow_color, ramp_color, brightness);
    #endif

    return ramp_color;
}

inline void additional_lights(const half4 position_cs, const float3 position_ws, const half3 normal_ws,
                              inout half3 diffuse_color)
{
    const uint pixel_light_count = GetAdditionalLightsCount();

    for (uint light_index = 0u; light_index < pixel_light_count; ++light_index)
    {
        const Light light = GetAdditionalLight(light_index, position_ws);
        const half attenuation = light.distanceAttenuation * light.shadowAttenuation;
        const half brightness = get_brightness(position_cs, normal_ws, light.direction, attenuation);
        half3 ramp_color = light.color;

        #ifdef _RAMP_MAP
        ramp_color *= SAMPLE_RAMP_MAP(brightness) * step(0.001, attenuation);
        #else
        ramp_color *= brightness;
        #endif
        diffuse_color += ramp_color;
    }
}

#endif
