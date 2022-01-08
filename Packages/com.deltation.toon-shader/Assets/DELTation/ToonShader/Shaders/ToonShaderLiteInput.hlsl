#ifndef TOON_SHADER_LITE_INPUT_INCLUDED
#define TOON_SHADER_LITE_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _ShadowTint;
half4 _BaseColor;

half _Ramp0;
half _RampSmoothness;

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
CBUFFER_END

#endif
