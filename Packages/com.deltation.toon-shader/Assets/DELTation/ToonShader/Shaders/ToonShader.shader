Shader "DELTation/Toon Shader"
{
    Properties
    {
        [MainTexture]
        _BaseMap ("Texture", 2D) = "white" {}
        [MainColor]
        _BaseColor ("Tint", Color) = (1.0, 1.0, 1.0)
        _ShadowTint ("Shadow Tint", Color) = (0.0, 0.0, 0.0, 1.0)
        
        [Toggle(_RAMP_MAP)]
        _UseRampMap("Use Ramp Texture", Float) = 0
        [NoScaleOffset]
        _RampMap ("Ramp Texture", 2D) = "white" {}
        [Toggle(_RAMP_TRIPLE)] _RampTriple ("Triple Ramp", Float) = 0
        _Ramp0 ("Ramp Threshold 0", Range(-1, 1)) = 0
        _Ramp1 ("Ramp Threshold 1", Range(-1, 1)) = 0.5
        _RampSmoothness ("Ramp Smoothness", Range(0, 2)) = 0.005
        
        [NoScaleOffset]
        _BumpMap("Normal Map", 2D) = "bump" {}
        
        [Toggle(_EMISSION)] _Emission ("Emission", Float) = 0
        [HDR] _EmissionColor ("Emission Color", Color) = (0.0, 0.0, 0.0, 0.0)
        
        [Toggle(_FRESNEL)] _Fresnel ("Rim", Float) = 1
        _FresnelThickness ("Rim Thickness", Range(0, 1)) = 0.45
        _FresnelSmoothness ("Rim Smoothness", Range(0, 1)) = 0.1
        [HDR] _FresnelColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Toggle(_SPECULAR)] _Specular ("Specular", Float) = 1
        [Toggle(_ANISO_SPECULAR)] _AnisoSpecular("Anisotropic Specular", Float) = 0
        _SpecularThreshold ("Specular Threshold", Range(0, 1)) = 0.8
        _SpecularExponent ("Specular Exponent", Range(0, 1000)) = 200
        _SpecularSmoothness ("Specular Smoothness", Range(0, 1)) = 0.025
        [HDR] _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Toggle(_FOG)] _Fog ("Fog", Float) = 1
        [Toggle(_ADDITIONAL_LIGHTS_ENABLED)] _AdditionalLights ("Additonal Lights", Float) = 1
        [Toggle(_ADDITIONAL_LIGHTS_SPECULAR)] _AdditionalLightsSpecular ("Additonal Lights Specular", Float) = 0
        [Toggle(_ENVIRONMENT_LIGHTING_ENABLED)] _EnvironmentLightingEnabled ("Environment Lighting", Float) = 1
        [Toggle(_VERTEX_COLOR)] _VertexColor ("Vertex Color", Float) = 0
        
        [Slider(0, 1)]
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        // Blending state
        [Toggle] _ZWrite("Z Write", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Float) = 0
        
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [Toggle] _AlphaClip("Alpha Clipping", Float) = 0.0
        
        // Editmode props
        [HideInInspector] _QueueOffset("Queue Offset", Float) = 0.0
        
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _FOG
            #pragma shader_feature_local _VERTEX_COLOR
            #pragma shader_feature_local _ADDITIONAL_LIGHTS_ENABLED
            #pragma shader_feature_local _SPECULAR
            #pragma shader_feature_local _ANISO_SPECULAR
            #pragma shader_feature_local _ADDITIONAL_LIGHTS_SPECULAR
            #pragma shader_feature_local _ENVIRONMENT_LIGHTING_ENABLED
            
            #pragma shader_feature_local_fragment _FRESNEL
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _RAMP_MAP
            #pragma shader_feature_local_fragment _RAMP_TRIPLE

            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            
            // Unity
            #pragma multi_compile_fog

			#pragma multi_compile_instancing
            

            #if defined(_ADDITIONAL_LIGHTS) && defined(_ADDITIONAL_LIGHTS_ENABLED) 
            #define TOON_ADDITIONAL_LIGHTS
            #endif

            #if defined(_ADDITIONAL_LIGHTS_VERTEX) && defined(_ADDITIONAL_LIGHTS_ENABLED)
            #define TOON_ADDITIONAL_LIGHTS_VERTEX
            #endif

            #if defined(_ADDITIONAL_LIGHTS_SPECULAR) && defined(_SPECULAR)
            #define TOON_ADDITIONAL_LIGHTS_SPECULAR
            #endif
            
            #include "./ToonShaderInput.hlsl"
            #include "./ToonShaderForwardPass_AppData.hlsl"
            #include "./ToonShaderForwardPass.hlsl"
            
            ENDHLSL
        }
                
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_instancing

            #include "./ToonShaderInput.hlsl"
            #include "./ToonShaderShadowCasterPass.hlsl"

            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            
            #pragma target 2.0

            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
           

            #include "./ToonShaderInput.hlsl"
            #include "./ToonShaderDepthOnlyPass.hlsl"
            
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma multi_compile_instancing

            #include "./ToonShaderInput.hlsl"
            #include "./ToonShaderDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
    
    CustomEditor "DELTation.ToonShader.Editor.ToonShaderEditor"
}
