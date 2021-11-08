#ifndef TOON_SHADER_FORWARD_PASS_INCLUDED
#define TOON_SHADER_FORWARD_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"

struct appdata
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;

    #ifdef _VERTEX_COLOR
    half3 vertexColor : COLOR;
    #endif

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
    half3 additional_lights_diffuse_color : TEXCOORD4;

    #ifdef TOON_ADDITIONAL_LIGHTS_SPECULAR
    half3 additional_lights_specular_color : TEXCOORD5;
    #endif

    #endif

    #ifdef _NORMALMAP
    half3 tangentWS : TEXCOORD6;
    half3 bitangentWS : TEXCOORD7;
    #endif

    #ifdef _VERTEX_COLOR
    half3 vertexColor : COLOR;
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
    const float4 basemap_st = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
    output.uv = apply_tiling_offset(input.uv, basemap_st);
    float fog_factor = get_fog_factor(vertex_position_inputs.positionCS.z);
    float3 position_ws = vertex_position_inputs.positionWS;
    output.positionWSAndFogFactor = float4(position_ws, fog_factor);
    output.normalWS = vertex_normal_inputs.normalWS;

    #if _NORMALMAP
    output.tangentWS = vertex_normal_inputs.tangentWS;
    output.bitangentWS = vertex_normal_inputs.bitangentWS;
    #endif


    #ifdef _MAIN_LIGHT_SHADOWS
    output.shadowCoord = GetShadowCoord(vertex_position_inputs);
    #endif

    output.positionCS = vertex_position_inputs.positionCS;

    #ifdef TOON_ADDITIONAL_LIGHTS_VERTEX
    half3 additional_lights_diffuse_color = 0, additional_lights_specular_color = 0;
    additional_lights(output.positionCS, position_ws, output.normalWS, additional_lights_diffuse_color, additional_lights_specular_color);
    output.additional_lights_diffuse_color = additional_lights_diffuse_color;

    #ifdef TOON_ADDITIONAL_LIGHTS_SPECULAR
    output.additional_lights_specular_color = additional_lights_specular_color;
    #endif

    #endif

    #ifdef _VERTEX_COLOR
    output.vertexColor = input.vertexColor;
    #endif

    return output;
}

half3 sample_normal(float2 uv, TEXTURE2D_PARAM(bumpMap, sampler_bumpMap), half scale = 1.0h)
{
    #ifdef _NORMALMAP
    const half4 n = SAMPLE_TEXTURE2D(bumpMap, sampler_bumpMap, uv);
    return UnpackNormal(n);
    #else
    return half3(0.0h, 0.0h, 1.0h);
    #endif
}

half4 frag(const v2f input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    const Light main_light = get_main_light(input);

    #if _NORMALMAP
    const half3 normal_ts = sample_normal(input.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
    half3 normal_ws = TransformTangentToWorld(normal_ts,
                                              half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz)
    );
    #else
    half3 normal_ws = input.normalWS;
    #endif

    normal_ws = NormalizeNormalPerPixel(normal_ws);
    const half3 light_direction_ws = normalize(main_light.direction);
    const float3 position_ws = input.positionWSAndFogFactor.xyz;
    const half3 view_direction_ws = SafeNormalize(GetCameraPositionWS() - position_ws);

    half4 base_color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
    #ifdef _VERTEX_COLOR
    base_color.xyz *= input.vertexColor;
    #endif
    half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * base_color;
    const half cutoff = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
    AlphaDiscard(albedo.a, cutoff);

    half3 sample_color = albedo.xyz;
    #if _ALPHAPREMULTIPLY_ON
	albedo.xyz *= albedo.a;
    #endif


    const half4 position_cs = input.positionCS;

    #ifdef _RAMP_MAP
    const half4 shadow_tint = 0;
    #else
    const half4 shadow_tint = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ShadowTint);
    #endif


    const half main_light_attenuation = main_light.shadowAttenuation * main_light.distanceAttenuation;
    // ReSharper disable once CppEntityAssignedButNoRead
    half main_light_brightness;
    // ReSharper disable once CppLocalVariableMayBeConst
    half3 diffuse_color = get_ramp_color(position_cs, normal_ws, light_direction_ws, main_light.color,
                                         main_light_attenuation, shadow_tint, main_light_brightness);
    // ReSharper disable once CppInitializedValueIsAlwaysRewritten
    half3 specular_color = 0;
    #ifdef _SPECULAR
    specular_color = get_specular_color(main_light.color, view_direction_ws, normal_ws, light_direction_ws);
    #endif

    #if defined(TOON_ADDITIONAL_LIGHTS)
    additional_lights(position_cs, position_ws, normal_ws, diffuse_color, specular_color);
    #elif defined(TOON_ADDITIONAL_LIGHTS_VERTEX)
    diffuse_color += input.additional_lights_diffuse_color;
    #endif

    half3 fragment_color = albedo.xyz * diffuse_color;

    #ifdef _SPECULAR
    fragment_color += specular_color;
    #endif

    #ifdef _FRESNEL
    fragment_color += get_fresnel_color(main_light.color, view_direction_ws, normal_ws, main_light_brightness);
    #endif

    #ifdef _ENVIRONMENT_LIGHTING_ENABLED
    
    half3 gi = albedo.xyz * SampleSH(normal_ws);

    #if defined(_SCREEN_SPACE_OCCLUSION)
    const float2 normalized_screen_space_uv = GetNormalizedScreenSpaceUV(position_cs);
    const AmbientOcclusionFactor ao_factor = GetScreenSpaceAmbientOcclusion(normalized_screen_space_uv);
    gi *= ao_factor.indirectAmbientOcclusion;
    #endif
    
	fragment_color += gi;
    #endif

    #ifdef _EMISSION
	fragment_color += UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
    #endif

    #ifdef _FOG
    const float fog_factor = input.positionWSAndFogFactor.w;
    fragment_color = MixFog(fragment_color, fog_factor);
    #endif

    const half surface = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Surface);
    const half alpha = 1.0 * (1 - surface) + albedo.a * surface;
    return half4(max(fragment_color, 0), alpha);
}

#endif
