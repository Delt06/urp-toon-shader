Shader "DELTation/Outline"
{
    Properties
    {
        _DepthSensitivity("Depth Sensitivity", Range(0, 10)) = 0
        _NormalsSensitivity("Normals Sensitivity", Range(0, 10)) = 2
        _ColorSensitivity("Color Sensitivity", Range(0, 10)) = 0
        [HDR] _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineThickness ("Outline Thickness", Range(0, 4)) = 1
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"="Geometry+0"
        }
        
        Pass
        {
            Name "Pass"
            Tags 
            { 
            }
           
            Blend One Zero, One Zero
            Cull Back
            ZTest LEqual
            ZWrite On
        
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
        
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
            CBUFFER_START(UnityPerMaterial)
            float _DepthSensitivity;
            float _NormalsSensitivity;
            float _ColorSensitivity;
            float4 _OutlineColor;
            float _OutlineThickness;
            CBUFFER_END
            
            #include "Outline.hlsl"
            struct appdata
            {
                float4 uv : TEXCOORD0;
                float3 positionOS : POSITION;
            };
        
            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            v2f vert(const appdata input)
            {
                v2f output;
                output.uv = input.uv;
                const half3 positionWS = TransformObjectToWorld(input.positionOS);
                output.positionCS = TransformWorldToHClip(positionWS);
                return output;
            }

            float4 frag(const v2f input) : SV_TARGET
            {
                float4 outline_out;
                Outline_float(input.uv.xy, _OutlineThickness, _DepthSensitivity, _NormalsSensitivity, _ColorSensitivity, _OutlineColor, outline_out);
                return float4(outline_out.xyz, 1);
            }
        
            ENDHLSL
        }
    }
    FallBack "Hidden/Shader Graph/FallbackError"
}