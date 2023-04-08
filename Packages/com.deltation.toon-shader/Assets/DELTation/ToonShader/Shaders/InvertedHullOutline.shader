Shader "DELTation/Inverted Hull Outline"
{
	Properties
	{
		_Color ("Color", Color) = (0, 0, 0, 0)
		_Scale ("Scale", Range(0, 10)) = 0.05
		_ViewBiasEdge ("View Bias Edge", Range(-1, 1)) = -1
		_ViewBiasSmoothness ("View Bias Smoothness", Range(0, 2)) = 0
		_DepthOffsetFactor ("Depth Offset Factor", Float) = 0
		_DepthOffsetUnits ("Depth Offset Units", Float) = 0
		[Toggle(CLIP_SPACE)]
		_ClipSpace ("Clip Space", Float) = 1
		[Toggle(CUSTOM_NORMALS)]
		_CustomNormals ("Custom Normals (UV2)", Float) = 0
	}
	SubShader
	{
		Cull Front ZWrite On ZTest LEqual
		Offset [_DepthOffsetFactor], [_DepthOffsetUnits]

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature_vertex CLIP_SPACE
			#pragma shader_feature_vertex CUSTOM_NORMALS
			#pragma shader_feature_vertex FALLBACK_TO_DEFAULT_NORMALS

			#pragma multi_compile_fog
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct appdata
			{
				float3 vertex : POSITION;
				#ifdef CUSTOM_NORMALS
				float3 normal : TEXCOORD2;
				#else
				float3 normal : NORMAL;
				#endif
			};

			struct v2f
			{
				float4 position_cs : SV_POSITION;
				float fog_factor : FOG_FACTOR;
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float _Scale;
			float _ViewBiasEdge;
			float _ViewBiasSmoothness;
			CBUFFER_END

			v2f vert (const appdata input)
			{
				v2f output;

				float3 normalWs = TransformObjectToWorldNormal(input.normal, true);
				const float3 position_ws = TransformObjectToWorld(input.vertex);
				const float3 view_dir_ws = GetWorldSpaceViewDir(position_ws);
				const float bias = smoothstep(_ViewBiasEdge, _ViewBiasEdge + _ViewBiasSmoothness, -dot(normalWs, view_dir_ws));
				
#ifdef CLIP_SPACE
				float4 vertex_hclip = TransformWorldToHClip(position_ws);
				float3 normal_hclip = TransformWorldToHClipDir(normalWs);
				output.position_cs = vertex_hclip + float4(normal_hclip * _Scale * bias, 0);
#else				
				output.position_cs = TransformWorldToHClip(position_ws + normalWs * _Scale * bias);
#endif

				output.fog_factor = ComputeFogFactor(output.position_cs.z);

				return output;

			}

			float4 frag(const v2f input) : SV_Target
			{
				float4 output = _Color;
				output.rgb = MixFog(output.rgb, input.fog_factor);
				return output;
			}
			ENDHLSL
		}
	}
}