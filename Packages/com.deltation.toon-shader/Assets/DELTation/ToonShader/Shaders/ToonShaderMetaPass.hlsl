#ifndef TOON_SHADER_META_PASS_INCLUDED
#define TOON_SHADER_META_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
#include "./ToonShaderUtils.hlsl"

struct appdata
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv0 : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;

    #ifdef _VERTEX_COLOR
    half3 vertexColor : COLOR;
    #endif
};

struct v2f
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;

    #ifdef _VERTEX_COLOR
    half3 vertexColor : COLOR;
    #endif
};

#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderAlbedo.hlsl"

v2f MetaPassVertex(appdata input)
{
    v2f output;
    output.positionCS = MetaVertexPosition(input.positionOS, input.uv1, input.uv2, unity_LightmapST,
                                           unity_DynamicLightmapST);
    output.uv = apply_tiling_offset(input.uv0, _BaseMap_ST);
    #ifdef _VERTEX_COLOR
    output.vertexColor = input.vertexColor;
    #endif
    return output;
}

half4 MetaPassFragment(const v2f input) : SV_Target
{
    MetaInput meta_input;
    meta_input.Albedo = get_albedo_and_alpha_discard(input).rgb;

    #ifdef _EMISSION
    meta_input.Emission = _EmissionColor;
    #else
    meta_input.Emission = 0;
    #endif

    return MetaFragment(meta_input);
}

#endif
