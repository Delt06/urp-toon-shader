#ifndef TOON_SHADER_UTILS_INCLUDED
#define TOON_SHADER_UTILS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

#if defined(_SHADOW_MASK) && (defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON) || !defined (LIGHTMAP_ON))
#define USE_SHADOW_MASK
#endif

#ifndef USE_SHADOW_MASK

#define DECLARE_SHADOW_MASK(input) ;

#else

#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)

#define DECLARE_SHADOW_MASK(input) const half4 shadow_mask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

#elif !defined (LIGHTMAP_ON)

#define DECLARE_SHADOW_MASK(input) const half4 shadow_mask = unity_ProbesOcclusion;

#endif

#endif

#ifdef USE_SHADOW_MASK
#define SHADOW_MASK_ARG , shadow_mask
#define SHADOW_MASK_PARAM , const half4 shadow_mask 
#else
#define SHADOW_MASK_ARG
#define SHADOW_MASK_PARAM
#endif

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

inline half4 get_additional_lights_color_attenuation(const float3 position_ws SHADOW_MASK_PARAM)
{
    half4 color_attenuation = 0;

    const uint additional_lights_count = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(additional_lights_count)
        const Light light = GetAdditionalLight(lightIndex, position_ws SHADOW_MASK_ARG);
        const half attenuation = light.distanceAttenuation * light.shadowAttenuation;
        color_attenuation += half4(light.color, attenuation);
    LIGHT_LOOP_END

    return color_attenuation;
}

inline half3 get_simple_ramp(half3 color, half opacity, half thickness, half smoothness, half value)
{
    smoothness *= thickness;
    color *= opacity;
    return color * smoothstep(1 - thickness, 1 - thickness + smoothness, value);
}

float get_aniso_specular(const float3 view_direction_ws, const float3 tangent_ws, const half3 light_direction_ws)
{
    const float l_dot_t = dot(light_direction_ws, tangent_ws);
    const float v_dot_t = dot(view_direction_ws, tangent_ws);
    const half specular = saturate((sqrt(1 - l_dot_t * l_dot_t) * sqrt(1 - v_dot_t * v_dot_t) -
        l_dot_t * v_dot_t));
    return max(0, specular);
}

inline half get_specular(float3 view_direction_ws, float3 normal_ws, float3 light_direction_ws)
{
    const half3 half_vector = normalize(view_direction_ws + light_direction_ws);
    return saturate(dot(normal_ws, half_vector));
}

inline half3 get_specular_color(half3 light_color, float3 view_direction_ws, float3 normal_ws, float3 tangent_ws,
                                float3 light_direction_ws)
{
    #ifndef _SPECULAR
    return 0;

    #else
    #if _ANISO_SPECULAR
    half specular = get_aniso_specular(view_direction_ws, cross(normal_ws, tangent_ws), light_direction_ws);
    #else
    half specular = get_specular(view_direction_ws, normal_ws, light_direction_ws);
    #endif
    
    const half specular_exponent = _SpecularExponent;
    specular = pow(specular, specular_exponent);
    const half4 specular_color = _SpecularColor;
    const half specular_threshold = _SpecularThreshold;
    const half specular_smoothness = _SpecularSmoothness;
    const half3 ramp = get_simple_ramp(light_color, specular_color.a, specular_threshold, specular_smoothness,
                                       specular);
    return specular_color.xyz * ramp;
    #endif
}

inline half get_fresnel(float3 view_direction_ws, float3 normal_ws)
{
    return 1 - saturate(dot(view_direction_ws, normal_ws));
}

inline half3 get_fresnel_color(float3 light_color, float3 view_direction_ws, float3 normal_ws, half brightness)
{
    #ifndef _FRESNEL
    return 0;
    #else
    const half fresnel = get_fresnel(view_direction_ws, normal_ws);
    const half4 fresnel_color = _FresnelColor;
    const half fresnel_thickness = _FresnelThickness;
    const half fresnel_smothness = _FresnelSmoothness;
    return fresnel_color.xyz * get_simple_ramp(light_color, fresnel_color.a, fresnel_thickness, fresnel_smothness, brightness * fresnel);
    #endif
}

inline half get_ramp(half value)
{
    #ifdef _RAMP_MAP
    return (value + 1) * 0.5;
    #elif defined(_RAMP_TRIPLE)
    const half ramp0 = _Ramp0;
    const half ramp1 = _Ramp1;
    const half ramp_smoothness = _RampSmoothness;
    const half ramp0_value = smoothstep(ramp0, ramp0 + ramp_smoothness, value);
    const half ramp1_value = smoothstep(ramp1, ramp1 + ramp_smoothness, value);
    return (ramp0_value + ramp1_value) * 0.5;
    #else
    const half ramp0 = _Ramp0;  
    const half ramp_smoothness = _RampSmoothness;
    return smoothstep(ramp0, ramp0 + ramp_smoothness, value);
    #endif
}

inline half get_brightness_lambert_base(const half3 normal_ws, const half3 light_direction, const half main_light_attenuation)
{
    const half dot_value = dot(normal_ws, light_direction);
    const half brightness = min(dot_value, dot_value * main_light_attenuation);
    return brightness;
}


inline half get_brightness(const half4 position_cs, const half3 normal_ws, const half3 light_direction, const half main_light_attenuation)
{
    // ReSharper disable once CppLocalVariableMayBeConst
    half brightness = get_brightness_lambert_base(normal_ws, light_direction, main_light_attenuation);

    #if defined(_SCREEN_SPACE_OCCLUSION)
    const float2 normalized_screen_space_uv = GetNormalizedScreenSpaceUV(position_cs);
    const AmbientOcclusionFactor ao_factor = GetScreenSpaceAmbientOcclusion(normalized_screen_space_uv);
    brightness = min(brightness, brightness * ao_factor.directAmbientOcclusion);
    #endif

    #ifdef TOON_SHADER_HOOK_RAMP_BRIGHTNESS
    TOON_SHADER_HOOK_RAMP_BRIGHTNESS
    #endif

    return get_ramp(brightness);
}

inline half get_brightness_vs(const half3 normal_ws, const half3 light_direction, const half main_light_attenuation)
{
    const half brightness = get_brightness_lambert_base(normal_ws, light_direction, main_light_attenuation);
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
    
    #ifdef _PURE_SHADOW_COLOR
    ramp_color *= SAMPLE_RAMP_MAP(brightness);
    #else
    ramp_color *= SAMPLE_RAMP_MAP(brightness);
    #endif
    
    #else
    const half3 shadow_color = lerp(ramp_color, shadow_color_opacity.rgb, shadow_color_opacity.a);
    ramp_color = lerp(shadow_color, ramp_color, brightness);
    #endif

    return ramp_color;
}

inline void additional_lights(const float3 position_ws, const half3 normal_ws,
                              const half3 tangent_ws, inout half3 diffuse_color, inout half3 specular_color
                              SHADOW_MASK_PARAM
                              , const half3 albedo = half3(1, 1, 1)
                              
                              )
{
    #ifdef TOON_ADDITIONAL_LIGHTS_SPECULAR
    const half3 view_direction_ws = SafeNormalize(GetCameraPositionWS() - position_ws);
    #endif

    const uint pixel_light_count = GetAdditionalLightsCount();

    LIGHT_LOOP_BEGIN(pixel_light_count)
        const Light light = GetAdditionalLight(lightIndex, position_ws
        #ifdef _ADDITIONAL_LIGHT_SHADOWS
            #ifdef USE_SHADOW_MASK
                SHADOW_MASK_ARG
            #else
                , 0
            #endif
        #endif
            );
        const half attenuation = light.distanceAttenuation * light.shadowAttenuation;
        const half brightness = get_brightness_vs(normal_ws, light.direction, attenuation) * step(0.001, attenuation);
        half3 ramp_color = light.color * albedo; 

        #ifdef _RAMP_MAP
        ramp_color *= SAMPLE_RAMP_MAP(brightness);
        #else
        ramp_color *= brightness;
        #endif
        diffuse_color += ramp_color;

        #ifdef TOON_ADDITIONAL_LIGHTS_SPECULAR
        specular_color += get_specular_color(light.color, view_direction_ws, normal_ws, tangent_ws, light.direction) *
            attenuation;
        #endif
    LIGHT_LOOP_END
}

#endif
