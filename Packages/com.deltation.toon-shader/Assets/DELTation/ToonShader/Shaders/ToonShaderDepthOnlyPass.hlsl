#ifndef TOON_SHADER_DEPTH_ONLY_PASS
#define TOON_SHADER_DEPTH_ONLY_PASS

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct appdata
{
    float4 position : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 position_cs : SV_POSITION;
};

v2f DepthOnlyVertex(appdata input)
{
    v2f output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.position_cs = TransformObjectToHClip(input.position.xyz);
    return output;
}

half4 DepthOnlyFragment(v2f input) : SV_TARGET
{
    return 0;
}

#endif
