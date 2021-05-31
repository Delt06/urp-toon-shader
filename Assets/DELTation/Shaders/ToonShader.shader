Shader "DELTation/Toon Shader"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
        _BaseColor ("Tint", Color) = (1.0, 1.0, 1.0)
        _ShadowTint ("Shadow Tint", Color) = (0.0, 0.0, 0.0, 1.0)
        
        [Toggle(_RAMP_MAP)]
        _UseRampMap("Use Ramp Texture", Float) = 0
        [NoScaleOffset]
        _RampMap ("Ramp Texture", 2D) = "white" {}
        [Toggle(_RAMP_TRIPLE)] _RampTriple ("Triple Ramp", Float) = 1
        _Ramp0 ("Ramp0", Range(-1, 1)) = 0
        _Ramp1 ("Ramp1", Range(-1, 1)) = 0.5
        _RampSmoothness ("Ramp Smoothness", Range(0, 1)) = 0.005
        
        [Toggle(_EMISSION)] _Emission ("Emission", Float) = 0
        [HDR] _EmissionColor ("Emission Color", Color) = (0.0, 0.0, 0.0, 0.0)
        
        [Toggle(_FRESNEL)] _Fresnel ("Rim", Float) = 1
        _FresnelThickness ("Rim Thickness", Range(0, 1)) = 0.45
        _FresnelSmoothness ("Rim Smoothness", Range(0, 1)) = 0.1
        [HDR] _FresnelColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Toggle(_SPECULAR)] _Specular ("Specular", Float) = 1
        _SpecularThreshold ("Specular Threshold", Range(0, 1)) = 0.8
        _SpecularExponent ("Specular Exponent", Range(0, 1000)) = 200
        _SpecularSmoothness ("Specular Smoothness", Range(0, 1)) = 0.025
        [HDR] _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Toggle(_FOG)] _Fog ("Fog", Float) = 1
        [Toggle(_ADDITIONAL_LIGHTS_ENABLED)] _AdditionalLights ("Additonal Lights", Float) = 1
        _AdditionalLightsMultiplier ("Additonal Lights Multiplier", Range(0, 10)) = 0.1
        [Toggle(_ENVIRONMENT_LIGHTING_ENABLED)] _EnvironmentLightingEnabled ("Environment Lighting", Float) = 1
        _EnvironmentLightingMultiplier ("Environment Lighting Multiplier", Range(0, 10)) = 0.5
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
            #pragma shader_feature_local _ADDITIONAL_LIGHTS_ENABLED
            #pragma shader_feature_local_fragment _SPECULAR
            #pragma shader_feature_local_fragment _FRESNEL
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _ENVIRONMENT_LIGHTING_ENABLED
            #pragma shader_feature_local_fragment _RAMP_MAP
            #pragma shader_feature_local_fragment _RAMP_TRIPLE
            
            // URP
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            
            // Unity
            #pragma multi_compile_fog
            

#if defined(_ADDITIONAL_LIGHTS) && defined(_ADDITIONAL_LIGHTS_ENABLED) 
                
            #define TOON_ADDITIONAL_LIGHTS
            
#endif

#if defined(_ADDITIONAL_LIGHTS_VERTEX) && defined(_ADDITIONAL_LIGHTS_ENABLED) 
                
            #define TOON_ADDITIONAL_LIGHTS_VERTEX
            
#endif

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "./ToonShaderInput.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float2 uvLM : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uvLM : TEXCOORD1;
                // xyz components are for positionWS, w is for fog factor
                float4 positionWSAndFogFactor : TEXCOORD2;
                half3  normalWS : TEXCOORD3;

#ifdef _MAIN_LIGHT_SHADOWS
                float4 shadowCoord : TEXCOORD6;
#endif
                float4 positionCS : SV_POSITION;

#ifdef TOON_ADDITIONAL_LIGHTS_VERTEX
                half4 additional_lights_vertex : TEXCOORD7; // a is attenuation
#endif                
            };

            inline float get_fog_factor(float depth)
            {
#ifdef _FOG
                return ComputeFogFactor(depth);
#else
                return 0;
#endif          
            }

            v2f vert (appdata v)
            {
                v2f output;
                VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(v.positionOS.xyz);
                const VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                output.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                output.uvLM = v.uvLM.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                float fog_factor = get_fog_factor(vertex_position_inputs.positionCS.z);
                output.positionWSAndFogFactor = float4(vertex_position_inputs.positionWS, fog_factor);
                output.normalWS = vertex_normal_inputs.normalWS;
#ifdef _MAIN_LIGHT_SHADOWS
                output.shadowCoord = GetShadowCoord(vertex_position_inputs);
#endif
                output.positionCS = vertex_position_inputs.positionCS;

#ifdef TOON_ADDITIONAL_LIGHTS_VERTEX

                half4 additional_lights_vertex = 0;

                const int additional_lights_count = GetAdditionalLightsCount();
                for (int i = 0; i < additional_lights_count; ++i)
                {
                    const Light light = GetAdditionalLight(i, vertex_position_inputs.positionWS);
                    additional_lights_vertex += half4(light.color, light.distanceAttenuation * light.shadowAttenuation);
                }

                output.additional_lights_vertex = additional_lights_vertex;
#endif
                
                
                return output;
            }

            inline Light get_main_light(v2f input)
            {
                float4 shadow_coord;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                shadow_coord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                shadow_coord = TransformWorldToShadowCoord(input.positionWSAndFogFactor.xyz);
#else
                shadow_coord = float4(0, 0, 0, 0);
#endif
                return GetMainLight(shadow_coord);
            }

            inline half3 get_simple_ramp(half3 color, half opacity, half thickness, half smoothness, half value)
            {
                smoothness *= thickness;
                color *= opacity;
                return color * smoothstep(1 - thickness, 1 - thickness + smoothness, value);
            }

            inline half get_specular(half3 view_direction_ws, half3 normal_ws, half3 light_direction_ws)
            {
                const half3 half_vector = normalize(view_direction_ws + light_direction_ws);
                return saturate(dot(normal_ws, half_vector));
            }

            inline half3 get_specular_color(half3 light_color, half3 view_direction_ws, half3 normal_ws, half3 light_direction_ws)
            {
#ifndef _SPECULAR
                return 0;

#else
                half specular = get_specular(view_direction_ws, normal_ws, light_direction_ws);
                specular = pow(specular, _SpecularExponent);
                const half3 ramp = get_simple_ramp(light_color, _SpecularColor.a, _SpecularThreshold, _SpecularSmoothness, specular);
                return _SpecularColor.xyz * ramp;
#endif                
            }

            inline half get_fresnel(half3 view_direction_ws, half3 normal_ws)
            {
                return 1 - saturate(dot(view_direction_ws, normal_ws)); 
            }

            inline half3 get_fresnel_color(half3 light_color, half3 view_direction_ws, half3 normal_ws, half brightness)
            {
#ifndef _FRESNEL
                return 0;
#else                
                const half fresnel = get_fresnel(view_direction_ws, normal_ws);
                return _FresnelColor.xyz * get_simple_ramp(light_color, _FresnelColor.a, _FresnelThickness, _FresnelSmoothness, brightness * fresnel);
#endif                
            }

            inline half get_ramp(half value)
            {
#ifdef _RAMP_MAP
                return (value + 1) * 0.5;
#elif defined(_RAMP_TRIPLE)
                const half ramp0 = smoothstep(_Ramp0, _Ramp0 + _RampSmoothness, value);
                const half ramp1 = smoothstep(_Ramp1, _Ramp1 + _RampSmoothness, value);
                return (ramp0 + ramp1) * 0.5;
#else
                return smoothstep(_Ramp0, _Ramp0 + _RampSmoothness, value);
#endif
            }

            inline half get_additional_lights_attenuation(in v2f input)
            {
#ifdef TOON_ADDITIONAL_LIGHTS_VERTEX
                return input.additional_lights_vertex.a;
#else
                
                half brightness = 0;
                
                const int additional_lights_count = GetAdditionalLightsCount();
                for (int i = 0; i < additional_lights_count; ++i)
                {
                    const Light light = GetAdditionalLight(i, input.positionWSAndFogFactor.xyz);
                    brightness += light.distanceAttenuation * light.shadowAttenuation;
                }

                return brightness;
#endif                
            }

            inline half get_brightness(in v2f input, half3 normal_ws, half3 light_direction, half shadow_attenuation, half distance_attenuation)
            {
                const half dot_value = dot(normal_ws, light_direction);
                const half attenuation = shadow_attenuation * distance_attenuation;
                half brightness = min(dot_value, dot_value * attenuation); 

#ifdef TOON_ADDITIONAL_LIGHTS
                
                brightness += get_additional_lights_attenuation(input);
#endif

#if defined(_SCREEN_SPACE_OCCLUSION)
                const float2 normalized_screen_space_uv = GetNormalizedScreenSpaceUV(input.positionCS);
                const AmbientOcclusionFactor ao_factor = GetScreenSpaceAmbientOcclusion(normalized_screen_space_uv);
                brightness = min(brightness, brightness * ao_factor.directAmbientOcclusion * ao_factor.indirectAmbientOcclusion);
#endif
                
                return get_ramp(brightness);
            }

            inline half3 get_additional_lights_color(in v2f input)
            {
#ifndef _ADDITIONAL_LIGHTS_ENABLED
                return 0;
#else
                
#ifdef  TOON_ADDITIONAL_LIGHTS_VERTEX
                const half4 additional_lights_vertex = input.additional_lights_vertex; 
                half4 color = half4(additional_lights_vertex.xyz * additional_lights_vertex.a, additional_lights_vertex.a);
#else          
                half4 color = 0;

                const int additional_lights_count = GetAdditionalLightsCount();
                for (int i = 0; i < additional_lights_count; ++i)
                {
                    const Light light = GetAdditionalLight(i, input.positionWSAndFogFactor.xyz);
                    const half attenuation = light.shadowAttenuation * light.distanceAttenuation; 
                    color += half4(light.color, attenuation);
                }
#endif        
                
                return color.xyz * get_ramp(color.a * _AdditionalLightsMultiplier);
#endif                
            }

            half3 frag (const v2f input) : SV_Target
            {
                const Light main_light = get_main_light(input);
                const half3 normal_ws = normalize(input.normalWS);
                const half3 light_direction_ws = normalize(main_light.direction);
                const half3 view_direction_ws = SafeNormalize(GetCameraPositionWS() - input.positionWSAndFogFactor.xyz);
 
                half3 sample_color = (SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor).xyz;
                sample_color *= main_light.color;

                

#if defined(TOON_ADDITIONAL_LIGHTS) || defined(TOON_ADDITIONAL_LIGHTS_VERTEX)
                
                sample_color += get_additional_lights_color(input);

#endif

#ifdef _ENVIRONMENT_LIGHTING_ENABLED

                sample_color += _EnvironmentLightingMultiplier * SampleSH(input.normalWS);

#endif              

                const half brightness = get_brightness(input, normal_ws, light_direction_ws, main_light.shadowAttenuation, main_light.distanceAttenuation);
#ifdef _RAMP_MAP
                const half2 ramp_uv = half2(brightness, 0.5);
                const half3 ramp_color = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, ramp_uv).xyz;
                half3 fragment_color =  sample_color * ramp_color;
#else
                const half3 shadow_color = lerp(sample_color, _ShadowTint.xyz, _ShadowTint.a);
                half3 fragment_color =  lerp(shadow_color, sample_color, brightness);
#endif
               

#ifdef _SPECULAR
                fragment_color += get_specular_color(main_light.color, view_direction_ws, normal_ws, light_direction_ws);
#endif
#ifdef _FRESNEL
                fragment_color += get_fresnel_color(main_light.color, view_direction_ws, normal_ws, brightness);
#endif
#ifdef _EMISSION
                fragment_color += _EmissionColor;
#endif

#ifdef _FOG
                const float fog_factor = input.positionWSAndFogFactor.w;
                fragment_color = MixFog(fragment_color, fog_factor);
#endif
               
                
                return max(fragment_color, 0);
            }
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
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_instancing

            #include "./ToonShaderInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

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

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
           

            #include "./ToonShaderInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            
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

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma multi_compile_instancing

            #include "./ToonShaderInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
    
    CustomEditor "DELTation.Editor.ToonShaderEditor"
}
