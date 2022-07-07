#ifndef TOON_SHADER_FORWARD_PASS_INCLUDED
#define TOON_SHADER_FORWARD_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#define REQUIRE_TANGENT_INTERPOLATOR defined(_NORMALMAP) || defined(_SPECULAR) && defined(_ANISO_SPECULAR)

struct v2f
{
    float2 uv : TEXCOORD0;
    // xyz components are for positionWS, w is for fog factor
    float4 positionWSAndFogFactor : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
    float4 positionCS : SV_POSITION;


    #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
    float4 shadowCoord : TEXCOORD3;
    #endif

    #ifdef TOON_ADDITIONAL_LIGHTS_VERTEX
    half3 additional_lights_diffuse_color : TEXCOORD4;

    #ifdef TOON_ADDITIONAL_LIGHTS_SPECULAR
    half3 additional_lights_specular_color : TEXCOORD5;
    #endif

    #endif

    #if REQUIRE_TANGENT_INTERPOLATOR
    float3 tangentWS : TEXCOORD6;
    #endif

    #ifdef _NORMALMAP
    float3 bitangentWS : TEXCOORD7;
    #endif

    #ifdef _VERTEX_COLOR
    half3 vertexColor : COLOR;
    #endif

    #ifdef _ENVIRONMENT_LIGHTING_ENABLED
    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 8);
    #endif

    #ifdef TOON_SHADER_HOOK_FORWARD_PASS_V2F
    TOON_SHADER_HOOK_FORWARD_PASS_V2F
    #endif


    UNITY_VERTEX_INPUT_INSTANCE_ID
};

#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderUtils.hlsl"
#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderUtilsV2f.hlsl"

v2f vert(appdata input)
{
    v2f output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    #ifdef TOON_SHADER_HOOK_VERTEX_INPUT
    TOON_SHADER_HOOK_VERTEX_INPUT;
    #endif

    const VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(input.positionOS.xyz);
    const VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    const float4 basemap_st = _BaseMap_ST;
    output.uv = apply_tiling_offset(input.uv, basemap_st);
    float fog_factor = get_fog_factor(vertex_position_inputs.positionCS.z);
    float3 position_ws = vertex_position_inputs.positionWS;
    output.positionWSAndFogFactor = float4(position_ws, fog_factor);
    output.normalWS = vertex_normal_inputs.normalWS;

    #if REQUIRE_TANGENT_INTERPOLATOR
    output.tangentWS = vertex_normal_inputs.tangentWS;
    #endif

    #ifdef _NORMALMAP
    output.bitangentWS = vertex_normal_inputs.bitangentWS;
    #endif
    
    #ifdef _VERTEX_COLOR
    output.vertexColor = input.vertexColor;
    #endif

    #ifdef _ENVIRONMENT_LIGHTING_ENABLED
    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
    OUTPUT_SH(output.normalWS, output.vertexSH);
    #endif

    #ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
    output.shadowCoord = GetShadowCoord(vertex_position_inputs);
    #endif

    output.positionCS = vertex_position_inputs.positionCS;

    #ifdef TOON_ADDITIONAL_LIGHTS_VERTEX
    half3 additional_lights_diffuse_color = 0, additional_lights_specular_color = 0;
    DECLARE_SHADOW_MASK(output)
    additional_lights(position_ws, output.normalWS, vertex_normal_inputs.tangentWS, additional_lights_diffuse_color, additional_lights_specular_color SHADOW_MASK_ARG);
    output.additional_lights_diffuse_color = additional_lights_diffuse_color;

    #ifdef TOON_ADDITIONAL_LIGHTS_SPECULAR
    output.additional_lights_specular_color = additional_lights_specular_color;
    #endif

    #endif

    #ifdef TOON_SHADER_HOOK_VERTEX_OUTPUT
    TOON_SHADER_HOOK_VERTEX_OUTPUT;
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

#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderAlbedo.hlsl"
#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderReflections.hlsl"

half4 frag(const v2f input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    DECLARE_SHADOW_MASK(input)
    const Light main_light = get_main_light(input SHADOW_MASK_ARG);

    #if REQUIRE_TANGENT_INTERPOLATOR
    const float3 tangent_ws = input.tangentWS;
    #else
    const float3 tangent_ws = 0;
    #endif

    #if _NORMALMAP
    const float3 normal_ts = sample_normal(input.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
    float3 normal_ws = TransformTangentToWorld(normal_ts,
                                              half3x3(tangent_ws, input.bitangentWS, input.normalWS)
    );
    #else
    float3 normal_ws = input.normalWS;
    #endif

    normal_ws = normalize(normal_ws);
    
    const float3 light_direction_ws = normalize(main_light.direction);
    const float3 position_ws = input.positionWSAndFogFactor.xyz;
    const float3 view_direction_ws = normalize(GetWorldSpaceViewDir(position_ws));

    half4 albedo = get_albedo_and_alpha_discard(input);
    half3 sample_color = albedo.xyz;
    #if _ALPHAPREMULTIPLY_ON
	albedo.xyz *= albedo.a;
    #endif


    const half4 position_cs = input.positionCS;

    #ifdef _RAMP_MAP
    const half4 shadow_tint = 0;
    #else
    const half4 shadow_tint = _ShadowTint;
    #endif

    const half main_light_attenuation = main_light.shadowAttenuation * main_light.distanceAttenuation;
    // ReSharper disable once CppEntityAssignedButNoRead
    half main_light_brightness;
    // ReSharper disable once CppLocalVariableMayBeConst
    half3 diffuse_color = get_ramp_color(position_cs, normal_ws, light_direction_ws,
                                         #ifdef _PURE_SHADOW_COLOR
                                         main_light.color * albedo.rgb,
                                         #else
                                         main_light.color,
                                         #endif
                                         main_light_attenuation, shadow_tint, main_light_brightness
    );
    // ReSharper disable once CppInitializedValueIsAlwaysRewritten
    half3 specular_color = 0;
    #ifdef _SPECULAR
    specular_color = get_specular_color(main_light.color, view_direction_ws, normal_ws, tangent_ws, light_direction_ws);
    specular_color *= main_light_attenuation;
    #endif

    #if defined(TOON_ADDITIONAL_LIGHTS)
    additional_lights(position_ws, normal_ws, tangent_ws, diffuse_color, specular_color
        SHADOW_MASK_ARG
    #ifdef _PURE_SHADOW_COLOR
        , albedo.rgb
    #endif
        );
    #elif defined(TOON_ADDITIONAL_LIGHTS_VERTEX)
    diffuse_color += input.additional_lights_diffuse_color
    #ifdef _PURE_SHADOW_COLOR
        * albedo.rgb
    #endif
    ;
    #endif

    half3 fragment_color = diffuse_color;

    #ifndef _PURE_SHADOW_COLOR
    fragment_color *= albedo.rgb;
    #endif
 
    #ifdef _ENVIRONMENT_LIGHTING_ENABLED

    half3 gi = albedo.xyz * SAMPLE_GI(input.staticLightmapUV, input.vertexSH, input.normalWS);

    #if defined(_SCREEN_SPACE_OCCLUSION)
    const float2 normalized_screen_space_uv = GetNormalizedScreenSpaceUV(position_cs);
    const AmbientOcclusionFactor ao_factor = GetScreenSpaceAmbientOcclusion(normalized_screen_space_uv);
    gi *= ao_factor.indirectAmbientOcclusion;
    #endif

    fragment_color += gi;
    #endif

    #ifdef _REFLECTIONS
    add_reflections(fragment_color, view_direction_ws, normal_ws, position_ws, albedo.rgb);
    #endif

    #ifdef _SPECULAR
    fragment_color += specular_color;
    #endif

    #ifdef _FRESNEL
    fragment_color += get_fresnel_color(main_light.color, view_direction_ws, normal_ws, main_light_brightness);
    #endif

    #ifdef _EMISSION
	fragment_color += _EmissionColor;
    #endif

    #ifdef _FOG
    const float fog_factor = input.positionWSAndFogFactor.w;
    fragment_color = MixFog(fragment_color, fog_factor);
    #endif

    const half surface = _Surface;
    const half alpha = 1.0 * (1 - surface) + albedo.a * surface;
    return half4(max(fragment_color, 0), alpha);
}

#endif
