#ifndef TOON_SHADER_INPUT_INCLUDED
#define TOON_SHADER_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
UNITY_DEFINE_INSTANCED_PROP(half4, _ShadowTint)
UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)

UNITY_DEFINE_INSTANCED_PROP(half, _Ramp0)
UNITY_DEFINE_INSTANCED_PROP(half, _Ramp1)
UNITY_DEFINE_INSTANCED_PROP(half, _RampSmoothness)

UNITY_DEFINE_INSTANCED_PROP(half3, _EmissionColor)

UNITY_DEFINE_INSTANCED_PROP(half4, _FresnelColor)
UNITY_DEFINE_INSTANCED_PROP(half, _FresnelSmoothness)
UNITY_DEFINE_INSTANCED_PROP(half, _FresnelThickness)

UNITY_DEFINE_INSTANCED_PROP(half4, _SpecularColor)
UNITY_DEFINE_INSTANCED_PROP(half, _SpecularSmoothness)
UNITY_DEFINE_INSTANCED_PROP(half, _SpecularThreshold)
UNITY_DEFINE_INSTANCED_PROP(half, _SpecularExponent)

UNITY_DEFINE_INSTANCED_PROP(half, _AdditionalLightsMultiplier)
UNITY_DEFINE_INSTANCED_PROP(half, _EnvironmentLightingMultiplier)

UNITY_DEFINE_INSTANCED_PROP(half, _Surface)
UNITY_DEFINE_INSTANCED_PROP(half, _Cutoff)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_RampMap);
SAMPLER(sampler_RampMap);

#endif
