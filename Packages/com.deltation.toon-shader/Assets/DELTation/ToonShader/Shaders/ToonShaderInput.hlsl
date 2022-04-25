#ifndef TOON_SHADER_INPUT_INCLUDED
#define TOON_SHADER_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInstancing.hlsl"

#define TOON_SHADER_CBUFFER_START CBUFFER_START(UnityPerMaterial)

#ifdef TOON_SHADER_CUSTOM_INSTANCING_BUFFER 
TOON_SHADER_INSTANCING_BUFFER_START
TOON_SHADER_CUSTOM_INSTANCING_BUFFER
TOON_SHADER_INSTANCING_BUFFER_END
#endif

#ifdef TOON_SHADER_CUSTOM_CBUFFER

TOON_SHADER_CBUFFER_START
TOON_SHADER_CUSTOM_CBUFFER
CBUFFER_END

#else

TOON_SHADER_CBUFFER_START
float4 _BaseColor;
float4 _BaseMap_ST;
half4 _ShadowTint;

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
half _Surface;
half _Cutoff;

half _ReflectionSmoothness;
half _ReflectionBlend;

#ifdef TOON_SHADER_HOOK_INPUT_BUFFER
TOON_SHADER_HOOK_INPUT_BUFFER
#endif

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);
TEXTURE2D(_RampMap);
SAMPLER(sampler_RampMap);
TEXTURE2D(_BumpMap);
SAMPLER(sampler_BumpMap);

#ifdef TOON_SHADER_HOOK_INPUT_TEXTURES
TOON_SHADER_HOOK_INPUT_TEXTURES
#endif

CBUFFER_END
#endif

#endif
