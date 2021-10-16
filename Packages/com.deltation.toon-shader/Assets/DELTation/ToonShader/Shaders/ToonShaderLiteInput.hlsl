#ifndef TOON_SHADER_LITE_INPUT_INCLUDED
#define TOON_SHADER_LITE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
UNITY_DEFINE_INSTANCED_PROP(half4, _ShadowTint)
UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)

UNITY_DEFINE_INSTANCED_PROP(half, _Ramp0)
UNITY_DEFINE_INSTANCED_PROP(half, _RampSmoothness)

UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

#endif
