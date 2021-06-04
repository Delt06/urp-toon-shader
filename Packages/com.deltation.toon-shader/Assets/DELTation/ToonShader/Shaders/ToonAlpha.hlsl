#ifndef TOON_ALPHA_INCLUDED
#define TOON_ALPHA_INCLUDED

half Alpha(half albedoAlpha, half4 color, half cutoff)
{
    half alpha = color.a * albedoAlpha;
    return alpha;
}

half4 SampleAlbedoAlpha(float2 uv, TEXTURE2D_PARAM(albedoAlphaMap, sampler_albedoAlphaMap))
{
    return SAMPLE_TEXTURE2D(albedoAlphaMap, sampler_albedoAlphaMap, uv);
}

#endif