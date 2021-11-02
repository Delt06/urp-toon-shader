using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityBlendMode = UnityEngine.Rendering.BlendMode;
// ReSharper disable Unity.PreferAddressByIdToGraphicsParams

namespace DELTation.ToonShader.Editor
{
	// ReSharper disable once UnusedType.Global
	public class ToonShaderEditor : ToonShaderEditorBase
	{
		public enum BlendMode
		{
			Alpha,
			Premultiply,
			Additive,
			Multiply,
		}

		public enum SurfaceType
		{
			Opaque,
			Transparent,
		}

		private static readonly Dictionary<(UnityBlendMode src, UnityBlendMode dst), BlendMode>
			UnityBlendModeToBlendMode =
				new Dictionary<(UnityBlendMode src, UnityBlendMode dst), BlendMode>
				{
					[(UnityBlendMode.SrcAlpha, UnityBlendMode.OneMinusSrcAlpha)] = BlendMode.Alpha,
					[(UnityBlendMode.One, UnityBlendMode.OneMinusSrcAlpha)] = BlendMode.Premultiply,
					[(UnityBlendMode.One, UnityBlendMode.One)] = BlendMode.Additive,
					[(UnityBlendMode.DstColor, UnityBlendMode.Zero)] = BlendMode.Multiply,
				};

		protected override void DrawProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			Label("Surface Options");
			DrawSurfaceProperties(materialEditor, properties);
			Label("Color");
			DrawColorProperties(materialEditor, properties);
			RampLabel();
			DrawRampProperties(materialEditor, properties, material);
			Label("Emission");
			DrawEmissionProperties(materialEditor, properties, material);
			Label("Rim");
			DrawRimProperties(materialEditor, properties, material);
			Label("Specular");
			DrawSpecularProperties(materialEditor, properties, material);
			MiscLabel();
			DrawMiscProperties(materialEditor, properties, material);
		}

		private static void DrawSurfaceProperties(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			DrawPropertyCustom(materialEditor, properties, "Surface Type", DrawSurfaceType);
			if (IsTransparent(properties))
				DrawPropertyCustom(materialEditor, properties, "Blending Mode", DrawBlendMode);
			
			DrawProperty(materialEditor, properties, "_Cull");
		}

		private static bool IsTransparent(MaterialProperty[] properties) =>
			(SurfaceType)FindProperty("_Surface", properties).floatValue == SurfaceType.Transparent;

		private static void DrawSurfaceType(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var property = FindProperty("_Surface", properties);
			var surfaceType = (SurfaceType)property.floatValue;

			var newSurfaceType = (SurfaceType)EditorGUILayout.EnumPopup(surfaceType);
			if (surfaceType != newSurfaceType)
			{
				var material = (Material)materialEditor.target;

				if (newSurfaceType == SurfaceType.Opaque)
				{
					material.renderQueue = (int)RenderQueue.Geometry;
					material.SetOverrideTag("RenderType", "Opaque");

					material.SetInt("_SrcBlend", (int)UnityBlendMode.One);
					material.SetInt("_DstBlend", (int)UnityBlendMode.Zero);
					material.SetInt("_ZWrite", 1);
					material.SetShaderPassEnabled("ShadowCaster", true);
				}
				else
				{
					var srcBlendProperty = FindProperty("_SrcBlend", properties);
					var dstBlendProperty = FindProperty("_DstBlend", properties);
					var blendProperty = FindProperty("_Blend", properties);

					var blendMode = (BlendMode)blendProperty.floatValue;
					var (src, dst) = ConvertBlendModeToUnityBlendMode(blendMode);
					srcBlendProperty.floatValue = (float)src;
					dstBlendProperty.floatValue = (float)dst;

					material.SetOverrideTag("RenderType", "Transparent");
					material.SetInt("_ZWrite", 0);
					material.renderQueue = (int)RenderQueue.Transparent;
					material.SetShaderPassEnabled("ShadowCaster", false);
				}

				property.floatValue = (float)newSurfaceType;
				materialEditor.PropertiesChanged();
			}
		}

		private static void DrawBlendMode(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var blendProperty = FindProperty("_Blend", properties);
			var currentBlendMode = (BlendMode)blendProperty.floatValue;

			var newBlendMode = (BlendMode)EditorGUILayout.EnumPopup(currentBlendMode);
			var (newSrcBlend, newDstBlend) = ConvertBlendModeToUnityBlendMode(newBlendMode);
			if (currentBlendMode != newBlendMode)
			{
				var srcBlendProperty = FindProperty("_SrcBlend", properties);
				srcBlendProperty.floatValue = (float)newSrcBlend;
				var dstBlendProperty = FindProperty("_DstBlend", properties);
				dstBlendProperty.floatValue = (float)newDstBlend;
				blendProperty.floatValue = (float)newBlendMode;
				materialEditor.PropertiesChanged();
			}
		}

		private static void DrawPropertyCustom(MaterialEditor materialEditor, MaterialProperty[] properties,
			string label,
			Action<MaterialEditor, MaterialProperty[]> draw)
		{
			GUILayout.BeginHorizontal();
			GUILayout.Label(label);
			GUILayout.FlexibleSpace();

			draw(materialEditor, properties);

			GUILayout.EndHorizontal();
		}

		private static (UnityBlendMode src, UnityBlendMode dst) ConvertBlendModeToUnityBlendMode(BlendMode blendMode)
		{
			var result = UnityBlendModeToBlendMode.FirstOrDefault(x => x.Value == blendMode).Key;
			return result != default ? result : (UnityBlendMode.SrcAlpha, UnityBlendMode.OneMinusSrcAlpha);
		}

		private static void DrawRampProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawProperty(materialEditor, properties, "_UseRampMap");

			if (material.IsKeywordEnabled("_RAMP_MAP"))
			{
				DrawProperty(materialEditor, properties, "_RampMap");
			}
			else
			{
				DrawShadowTintProperty(materialEditor, properties);
				DrawProperty(materialEditor, properties, "_RampTriple");
				DrawRampProperty0(materialEditor, properties);

				if (material.IsKeywordEnabled("_RAMP_TRIPLE"))
					DrawProperty(materialEditor, properties, "_Ramp1");

				DrawRampSmoothnessProperty(materialEditor, properties);
			}
		}

		private static void DrawEmissionProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			EditorGUILayout.BeginHorizontal();
			DrawProperty(materialEditor, properties, "_Emission");

			if (material.IsKeywordEnabled("_EMISSION"))
				DrawProperty(materialEditor, properties, "_EmissionColor");

			EditorGUILayout.EndHorizontal();
		}

		private static void DrawRimProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawProperty(materialEditor, properties, "_Fresnel");

			if (material.IsKeywordEnabled("_FRESNEL"))
			{
				DrawProperty(materialEditor, properties, "_FresnelColor");
				DrawProperty(materialEditor, properties, "_FresnelThickness");
				DrawProperty(materialEditor, properties, "_FresnelSmoothness");
			}
		}

		private static void DrawSpecularProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawProperty(materialEditor, properties, "_Specular");

			if (material.IsKeywordEnabled("_SPECULAR"))
			{
				DrawProperty(materialEditor, properties, "_SpecularColor");
				DrawProperty(materialEditor, properties, "_SpecularThreshold");
				DrawProperty(materialEditor, properties, "_SpecularExponent");
				DrawProperty(materialEditor, properties, "_SpecularSmoothness");
			}
		}

		private static void DrawMiscProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawFogProperty(materialEditor, properties);

			DrawProperty(materialEditor, properties, "_AdditionalLights");
			if (material.IsKeywordEnabled("_ADDITIONAL_LIGHTS_ENABLED"))
				DrawProperty(materialEditor, properties, "_AdditionalLightsMultiplier");

			DrawProperty(materialEditor, properties, "_EnvironmentLightingEnabled");
			if (material.IsKeywordEnabled("_ENVIRONMENT_LIGHTING_ENABLED"))
				DrawProperty(materialEditor, properties, "_EnvironmentLightingMultiplier");

			DrawVertexColorProperty(materialEditor, properties);
		}
	}
}