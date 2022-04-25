Shader "DELTation/Toon Shader (Fur)"
{
    Properties
    {
        [MainTexture]
        _BaseMap ("Texture", 2D) = "white" {}
        [MainColor]
        _BaseColor ("Tint", Color) = (1.0, 1.0, 1.0)
        _ShadowTint ("Shadow Tint", Color) = (0.0, 0.0, 0.0, 1.0)
        [Toggle(_PURE_SHADOW_COLOR)]
        _PureShadowColor ("Pure Shadow Color", Float) = 0
        
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
        [Toggle(_SHADOW_MASK)] _ShadowMask ("Baked Shadows", Float) = 0
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
        
        _FurLength ("Fur Length", Range(0, 1)) = 0.1
        _FurStep ("Fur Step", Range(0, 1)) = 0.1
        
        _FurNoise ("Fur Noise", 2D) = "white" {}
        [NoScaleOffset]
        _FurMask ("Fur Mask", 2D) = "white" {}
                
        [Toggle(_REFLECTIONS)] _Reflections("Reflections", Float) = 0.0
        [Toggle(_REFLECTION_PROBES)] _ReflectionProbes("Reflection Probes", Float) = 0.0
        _ReflectionSmoothness ("Smoothness", Range(0, 1)) = 0.5
        _ReflectionBlend ("Blend", Range(0, 1)) = 0.5
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

            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _FRESNEL
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _RAMP_TRIPLE
            #pragma multi_compile_local_fragment _ _RAMP_MAP _PURE_SHADOW_COLOR

            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
            
            #pragma shader_feature_local_fragment _REFLECTIONS
            #pragma shader_feature_local_fragment _REFLECTION_PROBES
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            
            
            // Unity
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
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
            
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderForwardPass_AppData.hlsl"
            

            #include "./ToonShaderFurUtils_Input.hlsl"
            #define TOON_SHADER_HOOK_INPUT_BUFFER TOON_SHADER_FUR_INPUT_BUFFER
            #define TOON_SHADER_HOOK_INPUT_TEXTURES TOON_SHADER_FUR_INPUT_TEXTURES
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInput.hlsl"

            #include "./ToonShaderFurUtils.hlsl"
            #define TOON_SHADER_HOOK_VERTEX_INPUT fur_hook_vertex_input
            #define TOON_SHADER_HOOK_FRAGMENT_ALBEDO fur_hook_fragment_albedo
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderForwardPass.hlsl"
            
            ENDHLSL
        }
    }
    
    CustomEditor "DELTation.ToonShader.Editor.Fur.ToonShaderFurEditor"
}
