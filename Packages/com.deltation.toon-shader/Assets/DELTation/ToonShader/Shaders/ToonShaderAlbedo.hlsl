#ifndef TOON_SHADER_ALBEDO_INCLUDED
#define TOON_SHADER_ALBEDO_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInput.hlsl"

inline half4 get_albedo_and_alpha_discard(const v2f input)
{
    // ReSharper disable once CppLocalVariableMayBeConst
    half4 base_color = _BaseColor;

    #ifdef _VERTEX_COLOR
    base_color.rgb *= input.vertexColor;
    #endif

    half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * base_color;
    #ifdef TOON_SHADER_HOOK_FRAGMENT_ALBEDO
	TOON_SHADER_HOOK_FRAGMENT_ALBEDO;
    #endif
    const half cutoff = _Cutoff;
    AlphaDiscard(albedo.a, cutoff);
    return albedo;
}

#endif
