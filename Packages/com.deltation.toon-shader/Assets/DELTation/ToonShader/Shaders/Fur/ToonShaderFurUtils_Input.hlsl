﻿#ifndef TOON_SHADER_FUR_UTILS_INPUT
#define TOON_SHADER_FUR_UTILS_INPUT

#define TOON_SHADER_FUR_INPUT_BUFFER \
UNITY_DEFINE_INSTANCED_PROP(half, _FurLength) \
UNITY_DEFINE_INSTANCED_PROP(half, _FurStep) \
UNITY_DEFINE_INSTANCED_PROP(float4, _FurNoise_ST) \

#define TOON_SHADER_FUR_INPUT_TEXTURES \
TEXTURE2D(_FurNoise); \
SAMPLER(sampler_FurNoise); \
TEXTURE2D(_FurMask); \
SAMPLER(sampler_FurMask); \

#endif