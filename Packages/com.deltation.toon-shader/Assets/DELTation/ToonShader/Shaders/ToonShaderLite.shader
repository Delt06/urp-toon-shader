Shader "DELTation/Toon Shader (Lite)"
{
    Properties
    {
        [MainTexture]
        _BaseMap ("Texture", 2D) = "white" {}
        [MainColor]
        _BaseColor ("Tint", Color) = (1.0, 1.0, 1.0)

		_ShadowTint ("Shadow Tint", Color) = (0.0, 0.0, 0.0, 1.0)
        _Ramp0 ("Ramp Threshold", Range(-1, 1)) = 0
        _RampSmoothness ("Ramp Smoothness", Range(0, 2)) = 0.005

		[Toggle(_TOON_VERTEX_LIT)] _VertexLit ("Vertex Lighting", Float) = 0
        [Toggle(_TOON_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1
        [Toggle(_FOG)] _Fog ("Fog", Float) = 1
        [Toggle(_VERTEX_COLOR)] _VertexColor ("Vertex Color", Float) = 0
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 300

        Pass
        {
            HLSLPROGRAM
            
            #pragma target 2.0
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local _FOG
            #pragma shader_feature_local _VERTEX_COLOR
            #pragma shader_feature_local _TOON_VERTEX_LIT
            #pragma shader_feature_local _TOON_RECEIVE_SHADOWS

            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            
            // Unity
            #pragma multi_compile_fog

			#pragma multi_compile_instancing
            
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderLiteInput.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderLiteForwardPass.hlsl"
            
            ENDHLSL
        }
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_instancing

            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderLiteInput.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderShadowCasterPass.hlsl"

            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing

            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderLiteInput.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderDepthOnlyPass.hlsl"
            
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma multi_compile_instancing

            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderLiteInput.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderDepthNormalsPass.hlsl"
            
            ENDHLSL
        }
    }
    
    CustomEditor "DELTation.ToonShader.Editor.ToonShaderLiteEditor"
}
