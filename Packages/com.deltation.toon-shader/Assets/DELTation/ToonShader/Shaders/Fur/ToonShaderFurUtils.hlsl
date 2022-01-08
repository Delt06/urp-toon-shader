#ifndef TOON_SHADER_FUR_UTILS
#define TOON_SHADER_FUR_UTILS

#include "../ToonShaderUtils.hlsl"

void fur_hook_vertex_input(inout appdata input)
{
    const half fur_length = _FurLength;
    const half fur_step = _FurStep;
    
    input.positionOS.xyz += input.normalOS * fur_length * fur_step;
}

void fur_hook_fragment_albedo(const half2 uv, inout half4 albedo)
{
    const half mask = SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, uv).r;
    clip(mask - 1);
    const float4 fur_noise_st = _FurNoise_ST;
    const half2 noise_uv = apply_tiling_offset(uv, fur_noise_st);
    albedo.a *= SAMPLE_TEXTURE2D(_FurNoise, sampler_FurNoise, noise_uv).r; 
}

#endif