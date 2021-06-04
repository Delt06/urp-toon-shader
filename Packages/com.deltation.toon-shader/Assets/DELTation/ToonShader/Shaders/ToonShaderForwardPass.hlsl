#ifndef TOON_SHADER_FORWARD_PASS_INCLUDED
#define TOON_SHADER_FORWARD_PASS_INCLUDED

struct appdata
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
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

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

#include "./ToonShaderUtils.hlsl"

v2f vert(appdata input)
{
    v2f output;
	
	UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    const VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(input.positionOS.xyz);
    const VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
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

half3 frag(const v2f input) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(input);

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

    const half main_light_attenuation = main_light.shadowAttenuation * main_light.distanceAttenuation;
    const half brightness = get_brightness(input.positionCS, normal_ws, light_direction_ws,
                                           main_light_attenuation,
                                           additional_lights_attenuation);
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
