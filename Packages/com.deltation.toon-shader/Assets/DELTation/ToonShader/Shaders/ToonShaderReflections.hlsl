#ifndef TOON_SHADER_REFLECTIONS_INCLUDED
#define TOON_SHADER_REFLECTIONS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInput.hlsl"

inline void add_reflections(inout half3 fragment_color, const in float3 view_direction_ws, const in float3 normal_ws, const in float3 position_ws, const in half3 albedo)
{
    const half3 reflect_vector = reflect(-view_direction_ws, normal_ws);
    const half roughness = 1 - _ReflectionSmoothness;

    half3 reflection;
    #ifdef _REFLECTION_PROBES
    reflection = CalculateIrradianceFromReflectionProbes(reflect_vector, position_ws, roughness);
    #else
    reflection = GlossyEnvironmentReflection(reflect_vector, roughness, 1);
    #endif
    
    fragment_color = lerp(fragment_color, reflection * albedo, _ReflectionBlend);
} 

#endif