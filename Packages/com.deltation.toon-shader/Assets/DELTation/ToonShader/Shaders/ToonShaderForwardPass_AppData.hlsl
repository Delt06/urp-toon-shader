#ifndef TOON_SHADER_APP_DATA
#define TOON_SHADER_APP_DATA

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct appdata
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;

    #if defined(_ENVIRONMENT_LIGHTING_ENABLED) && defined(LIGHTMAP_ON)
    float2 staticLightmapUV : TEXCOORD1;
    #endif

    #ifdef _VERTEX_COLOR
    half3 vertexColor : COLOR;
    #endif
    
    #ifdef TOON_SHADER_HOOK_APP_DATA
    TOON_SHADER_HOOK_APP_DATA
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

#endif