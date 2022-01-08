#ifndef TOON_SHADER_LITE_FORWARD_PASS
#define TOON_SHADER_LITE_FORWARD_PASS

#if defined(_TOON_RECEIVE_SHADOWS) && defined(_MAIN_LIGHT_SHADOWS)
#define LITE_MAIN_LIGHT_SHADOWS
#endif

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
    float4 positionCS : SV_POSITION;

    float fogFactor : TEXCOORD1;

    #ifdef _TOON_VERTEX_LIT
    half4 mainLightColorAndBrightness : TEXCOORD2;
    #else
	half3 normalWS : TEXCOORD2;
    #endif

    #ifdef _VERTEX_COLOR
    half3 vertexColor : COLOR;
    #endif

    #if defined(LITE_MAIN_LIGHT_SHADOWS) && !defined(_TOON_VERTEX_LIT)
    float4 shadowCoord : TEXCOORD3;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

#include "./ToonShaderUtils.hlsl"

inline half4 get_main_light_color_and_brightness(in const float4 position_cs, in const half3 normal_ws,
                                                 const float4 shadow_coords = 0)
{
    #ifdef TOON_SHADER_LITE_HOOK_MAIN_LIGHT
    const Light main_light = TOON_SHADER_LITE_HOOK_MAIN_LIGHT(shadow_coords);
    #else
    const Light main_light = GetMainLight(shadow_coords);
    #endif
    
    const half3 light_direction_ws = normalize(main_light.direction);
    const half main_light_attenuation = main_light.shadowAttenuation * main_light.distanceAttenuation;
    const half brightness = get_brightness(position_cs, normal_ws, light_direction_ws,
                                           main_light_attenuation);

    return half4(main_light.color, brightness);
}

inline float4 get_shadow_coord(const float3 position_ws)
{
    #ifdef TOON_SHADER_LITE_HOOK_GET_SHADOW_COORD
    return TOON_SHADER_LITE_HOOK_GET_SHADOW_COORD(position_ws);
    #else
    return TransformWorldToShadowCoord(position_ws);
    #endif
}

v2f vert(appdata input)
{
    v2f output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    const float4 basemap_st = _BaseMap_ST;
    output.uv = apply_tiling_offset(input.uv, basemap_st);

    const float3 position_ws = TransformObjectToWorld(input.positionOS.xyz);
    const float4 position_cs = TransformWorldToHClip(position_ws);
    output.positionCS = position_cs;

    output.fogFactor = get_fog_factor(position_cs.z);
    const half3 normal_ws = TransformObjectToWorldDir(input.normalOS);

    #ifdef _TOON_VERTEX_LIT
    output.mainLightColorAndBrightness =
        get_main_light_color_and_brightness(position_cs,
                                            normalize(normal_ws)
                                            #ifdef LITE_MAIN_LIGHT_SHADOWS
                , get_shadow_coord(position_ws)
                                            #endif
        );
    #else
	output.normalWS = normal_ws;

    #ifdef LITE_MAIN_LIGHT_SHADOWS
    output.shadowCoord = get_shadow_coord(position_ws);
    #endif

    #endif

    #ifdef _VERTEX_COLOR
    output.vertexColor = input.vertexColor;
    #endif


    return output;
}

half4 frag(const v2f input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);

    half4 base_color = _BaseColor;
    #ifdef _VERTEX_COLOR
    base_color.xyz *= input.vertexColor;
    #endif
    const half3 sample_color = (SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * base_color).rgb;


    #ifdef _TOON_VERTEX_LIT
    const half4 main_light_color_and_brightness = input.mainLightColorAndBrightness;
    #else
    
	const half4 main_light_color_and_brightness = get_main_light_color_and_brightness(input.positionCS,
	    normalize(input.normalWS)
    #ifdef LITE_MAIN_LIGHT_SHADOWS
	    , input.shadowCoord
    #endif
	    );
    
    #endif

    const half4 shadow_tint = _ShadowTint;
    const half3 shadow_color = lerp(sample_color, shadow_tint.xyz, shadow_tint.a);
    half3 fragment_color = lerp(shadow_color, sample_color, main_light_color_and_brightness.w);


    fragment_color *= main_light_color_and_brightness.xyz;

    #ifdef _FOG
    fragment_color = MixFog(fragment_color, input.fogFactor);
    #endif

    return half4(max(fragment_color, 0), 1);
}

#endif
