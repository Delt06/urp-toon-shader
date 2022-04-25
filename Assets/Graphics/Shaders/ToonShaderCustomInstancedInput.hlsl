#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInstancing.hlsl"

// define instanced property name
#define BASE_COLOR_INSTANCED i_BaseColor
// define the property in the instancing buffer
#define TOON_SHADER_CUSTOM_INSTANCING_BUFFER TOON_SHADER_DEFINE_INSTANCED_PROP(half4, BASE_COLOR_INSTANCED)
// define property accessor macro to ensure compability with the rest of the shader
#define _BaseColor TOON_SHADER_ACCESS_INSTANCED_PROP(BASE_COLOR_INSTANCED)

// copy all old properties except _BaseColor
#define TOON_SHADER_CUSTOM_CBUFFER \
float4 _BaseMap_ST; \
half4 _ShadowTint; \
\
half _Ramp0; \
half _Ramp1; \
half _RampSmoothness; \
half3 _EmissionColor; \
half4 _FresnelColor; \
half _FresnelSmoothness; \
half _FresnelThickness; \
half4 _SpecularColor; \
half _SpecularSmoothness; \
half _SpecularThreshold; \
half _SpecularExponent; \
half _Surface; \
half _Cutoff; \
half _ReflectionSmoothness; \
half _ReflectionBlend; \
\
TEXTURE2D(_BaseMap); \
SAMPLER(sampler_BaseMap); \
TEXTURE2D(_RampMap); \
SAMPLER(sampler_RampMap); \
TEXTURE2D(_BumpMap); \
SAMPLER(sampler_BumpMap); \

// include usual input file
#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInput.hlsl"