#ifndef TOON_SHADER_DEPTH_NORMALS_APP_DATA
#define TOON_SHADER_DEPTH_NORMALS_APP_DATA

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct appdata
{
    float4 positionOS : POSITION;
    float4 tangentOS : TANGENT;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID

    #ifdef TOON_SHADER_HOOK_APP_DATA
    TOON_SHADER_HOOK_APP_DATA
    #endif
};

#endif