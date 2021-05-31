#ifndef TOON_SHADER_LIT_PASS_INCLUDED
#define TOON_SHADER_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct appdata
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    // xyz components are for positionWS, w is for fog factor
    float4 positionWSAndFogFactor : TEXCOORD1;
    half3 normalWS : TEXCOORD2;
    float4 positionCS : SV_POSITION;

    #ifdef _MAIN_LIGHT_SHADOWS
    float4 shadowCoord : TEXCOORD3;
    #endif
    

    #ifdef TOON_ADDITIONAL_LIGHTS_VERTEX
    half4 additional_lights_vertex : TEXCOORD4; // a is attenuation
    #endif
};

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

v2f vert(appdata v)
{
    v2f output;
    const VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(v.positionOS.xyz);
    const VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
    output.uv = TRANSFORM_TEX(v.uv, _BaseMap);
    float fog_factor = get_fog_factor(vertex_position_inputs.positionCS.z);
    float3 position_ws = vertex_position_inputs.positionWS;
    output.positionWSAndFogFactor = float4(position_ws, fog_factor);
    output.normalWS = vertex_normal_inputs.normalWS;
    
    #ifdef _MAIN_LIGHT_SHADOWS
    output.shadowCoord = GetShadowCoord(vertex_position_inputs);
    #endif
    
    output.positionCS = vertex_position_inputs.positionCS;

    #ifdef TOON_ADDITIONAL_LIGHTS_VERTEX
    output.additional_lights_vertex = get_additional_lights_color_attenuation(position_ws);
    #endif

    return output;
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

inline half get_brightness(in v2f input, half3 normal_ws, half3 light_direction, half shadow_attenuation,
                           half distance_attenuation, half additional_lights_attenuation)
{
    const half dot_value = dot(normal_ws, light_direction);
    const half attenuation = shadow_attenuation * distance_attenuation;
    half brightness = min(dot_value, dot_value * attenuation);

    #ifdef TOON_ADDITIONAL_LIGHTS        
    brightness += additional_lights_attenuation;
    #endif

    #if defined(_SCREEN_SPACE_OCCLUSION)
    const float2 normalized_screen_space_uv = GetNormalizedScreenSpaceUV(input.positionCS);
    const AmbientOcclusionFactor ao_factor = GetScreenSpaceAmbientOcclusion(normalized_screen_space_uv);
    brightness = min(brightness, brightness * ao_factor.directAmbientOcclusion * ao_factor.indirectAmbientOcclusion);
    #endif

    return get_ramp(brightness);
}

half3 frag(const v2f input) : SV_Target
{
    const Light main_light = get_main_light(input);
    const half3 normal_ws = normalize(input.normalWS);
    const half3 light_direction_ws = normalize(main_light.direction);
    const float3 position_ws = input.positionWSAndFogFactor.xyz;
    const half3 view_direction_ws = SafeNormalize(GetCameraPositionWS() - position_ws);

    half3 sample_color = (SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor).xyz;
    sample_color *= main_light.color;

    half additional_lights_attenuation = 0;
    
    #if defined(TOON_ADDITIONAL_LIGHTS_VERTEX) || defined(TOON_ADDITIONAL_LIGHTS)
    half4 additional_lights_color_attenuation = 0;
    #endif
    
    #if defined(TOON_ADDITIONAL_LIGHTS_VERTEX)
    additional_lights_color_attenuation = input.additional_lights_vertex;
    #elif defined(TOON_ADDITIONAL_LIGHTS)
    additional_lights_color_attenuation = get_additional_lights_color_attenuation(position_ws);
    #endif
    
    #if defined(TOON_ADDITIONAL_LIGHTS_VERTEX) || defined(TOON_ADDITIONAL_LIGHTS)
    half3 additional_lights_color = additional_lights_color_attenuation.xyz;
    additional_lights_attenuation = additional_lights_color_attenuation.a * _AdditionalLightsMultiplier;
    additional_lights_color *= get_ramp(additional_lights_attenuation);
    sample_color += additional_lights_color;
    #endif

    #ifdef _ENVIRONMENT_LIGHTING_ENABLED
    sample_color += _EnvironmentLightingMultiplier * SampleSH(input.normalWS);
    #endif

    const half brightness = get_brightness(input, normal_ws, light_direction_ws, main_light.shadowAttenuation,
                                           main_light.distanceAttenuation, additional_lights_attenuation);
    #ifdef _RAMP_MAP
    const half2 ramp_uv = half2(brightness, 0.5);
    const half3 ramp_color = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, ramp_uv).xyz;
    half3 fragment_color = sample_color * ramp_color;
    #else
    const half3 shadow_color = lerp(sample_color, _ShadowTint.xyz, _ShadowTint.a);
    half3 fragment_color = lerp(shadow_color, sample_color, brightness);
    #endif


    #ifdef _SPECULAR
    fragment_color += get_specular_color(main_light.color, view_direction_ws, normal_ws, light_direction_ws);
    #endif
    #ifdef _FRESNEL
    fragment_color += get_fresnel_color(main_light.color, view_direction_ws, normal_ws, brightness);
    #endif
    #ifdef _EMISSION
    fragment_color += _EmissionColor;
    #endif

    #ifdef _FOG
    const float fog_factor = input.positionWSAndFogFactor.w;
    fragment_color = MixFog(fragment_color, fog_factor);
    #endif

    return max(fragment_color, 0);
}

#endif
