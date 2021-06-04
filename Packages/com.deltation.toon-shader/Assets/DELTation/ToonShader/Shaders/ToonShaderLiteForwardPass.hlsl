#ifndef TOON_SHADER_LITE_FORWARD_PASS_INCLUDED
#define TOON_SHADER_LITE_FORWARD_PASS_INCLUDED

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
    float4 positionCS : SV_POSITION;

	float fogFactor : TEXCOORD1;
	
	#ifdef _TOON_VERTEX_LIT
	half4 mainLightColorAndBrightness : TEXCOORD2;
	#else
	half3 normalWS : TEXCOORD2;
	#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

#include "./ToonShaderUtils.hlsl"

inline half4 get_main_light_color_and_brightness(in const float4 position_cs, in const half3 normal_ws)
{
	const Light main_light = GetMainLight(float4(0, 0, 0, 0));
	const half3 light_direction_ws = normalize(main_light.direction);
	const half main_light_attenuation = main_light.shadowAttenuation * main_light.distanceAttenuation;
	const half brightness = get_brightness(position_cs, normal_ws, light_direction_ws,
										main_light_attenuation,
										0);

	return half4(main_light.color, brightness);
}

v2f vert(appdata input)
{
    v2f output;
	
	UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    const VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(input.positionOS.xyz);
    const VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

	float4 position_cs = vertex_position_inputs.positionCS;
	output.positionCS = position_cs;
	
	output.fogFactor = get_fog_factor(position_cs.z);

	#ifdef _TOON_VERTEX_LIT
	output.mainLightColorAndBrightness = get_main_light_color_and_brightness(position_cs, vertex_normal_inputs.normalWS);
	#else
	output.normalWS = vertex_normal_inputs.normalWS;
	#endif

    return output;
}

half3 frag(const v2f input) : SV_Target
{
	UNITY_SETUP_INSTANCE_ID(input);
	
    half3 sample_color = (SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor).xyz;

	#ifdef _TOON_VERTEX_LIT
	const half4 main_light_color_and_brightness = input.mainLightColorAndBrightness;
	#else
	const half4 main_light_color_and_brightness = get_main_light_color_and_brightness(input.positionCS, input.normalWS);
	#endif
	
    sample_color *= main_light_color_and_brightness.xyz;
	
	const half3 shadow_color = lerp(sample_color, _ShadowTint.xyz, _ShadowTint.a);
	half3 fragment_color = lerp(shadow_color, sample_color, main_light_color_and_brightness.w);

    #ifdef _FOG
    fragment_color = MixFog(fragment_color, input.fogFactor);
    #endif

    return max(fragment_color, 0);
}

#endif
