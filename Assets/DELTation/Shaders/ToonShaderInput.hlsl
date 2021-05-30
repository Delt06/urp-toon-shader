#ifndef TOON_SHADER_INPUT_INCLUDED
#define TOON_SHADER_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _ShadowTint;
half _Ramp0;
half _Ramp1;
half _RampSmoothness;
half4 _BaseColor;
half3 _EmissionColor;
half _Cutoff;

half4 _FresnelColor;
half _FresnelSmoothness;
half _FresnelThickness;

half4 _SpecularColor;
half _SpecularSmoothness;
half _SpecularThreshold;
half _SpecularExponent;

half _AdditionalLightsMultiplier;
half _EnvironmentLightingMultiplier;
            
CBUFFER_END

TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);

half Alpha(half albedoAlpha, half4 color, half cutoff)
{
    half alpha = color.a;

    #if defined(_ALPHATEST_ON)
    clip(alpha - cutoff);
    #endif

    return alpha;
}

half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    return SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
}

#endif