#ifndef TOON_SHADER_INPUT_INCLUDED
#define TOON_SHADER_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _ShadowTint;
half4 _BaseColor;

half _Ramp0;
half _Ramp1;
half _RampSmoothness;

half3 _EmissionColor;

half4 _FresnelColor;
half _FresnelSmoothness;
half _FresnelThickness;

half4 _SpecularColor;
half _SpecularSmoothness;
half _SpecularThreshold;
half _SpecularExponent;

half _AdditionalLightsMultiplier;
half _EnvironmentLightingMultiplier;

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_RampMap);
SAMPLER(sampler_RampMap);

#endif
