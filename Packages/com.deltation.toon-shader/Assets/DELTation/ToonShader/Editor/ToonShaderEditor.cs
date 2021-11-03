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

		private const int queueOffsetRange = 50;

		private static readonly Dictionary<(UnityBlendMode src, UnityBlendMode dst), BlendMode>
			UnityBlendModeToBlendMode =
				new Dictionary<(UnityBlendMode src, UnityBlendMode dst), BlendMode>
				{
					[(UnityBlendMode.SrcAlpha, UnityBlendMode.OneMinusSrcAlpha)] = BlendMode.Alpha,
					[(UnityBlendMode.One, UnityBlendMode.OneMinusSrcAlpha)] = BlendMode.Premultiply,
					[(UnityBlendMode.One, UnityBlendMode.One)] = BlendMode.Additive,
					[(UnityBlendMode.DstColor, UnityBlendMode.Zero)] = BlendMode.Multiply,
				};

		protected override bool RenderQueueField => false;

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

			DrawPropertyCustom(materialEditor, properties, "Alpha Clipping", DrawAlphaClip);
			if (IsAlphaClip(properties))
				DrawProperty(materialEditor, properties, "_Cutoff");

			DrawProperty(materialEditor, properties, "_Cull");
		}

		private static bool IsAlphaClip(MaterialProperty[] properties) =>
			FindProperty("_AlphaClip", properties).floatValue > 0.5f;

		private static bool IsTransparent(MaterialProperty[] properties) =>
			(SurfaceType)FindProperty("_Surface", properties).floatValue == SurfaceType.Transparent;

		private static void DrawAlphaClip(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var property = FindProperty("_AlphaClip", properties);
			var alphaClip = property.floatValue > 0.5f;

			EditorGUI.showMixedValue = property.hasMixedValue;
			EditorGUI.BeginChangeCheck();
			var newAlphaClip = EditorGUILayout.Toggle(alphaClip);

			if (EditorGUI.EndChangeCheck())
			{
				property.floatValue = newAlphaClip ? 1f : 0f;
				materialEditor.PropertiesChanged();
				TryUpdateSurfaceData(materialEditor, properties);
			}

			EditorGUI.showMixedValue = false;
		}

		private static void DrawSurfaceType(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var surfaceProperty = FindProperty("_Surface", properties);
			var surfaceType = (SurfaceType)surfaceProperty.floatValue;

			EditorGUI.showMixedValue = surfaceProperty.hasMixedValue;
			EditorGUI.BeginChangeCheck();
			var newSurfaceType = (SurfaceType)EditorGUILayout.EnumPopup(surfaceType);

			if (EditorGUI.EndChangeCheck())
			{
				surfaceProperty.floatValue = (float)newSurfaceType;
				materialEditor.PropertiesChanged();
				TryUpdateSurfaceData(materialEditor, properties);
			}

			EditorGUI.showMixedValue = false;
		}

		private static void TryUpdateSurfaceData(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var surfaceProperty = FindProperty("_Surface", properties);
			var surfaceType = (SurfaceType)surfaceProperty.floatValue;
			var material = (Material)materialEditor.target;
			var alphaClip = IsAlphaClip(properties);

			const string alphaTestOnKeyword = "_ALPHATEST_ON";
			if (alphaClip)
				material.EnableKeyword(alphaTestOnKeyword);
			else
				material.DisableKeyword(alphaTestOnKeyword);


			if (surfaceType == SurfaceType.Opaque)
			{
				if (alphaClip)
				{
					material.renderQueue = (int)RenderQueue.AlphaTest;
					material.SetOverrideTag("RenderType", "TransparentCutout");
				}
				else
				{
					material.renderQueue = (int)RenderQueue.Geometry;
					material.SetOverrideTag("RenderType", "Opaque");
				}

				material.renderQueue +=
					material.HasProperty("_QueueOffset") ? (int)material.GetFloat("_QueueOffset") : 0;
				material.SetInt("_SrcBlend", (int)UnityBlendMode.One);
				material.SetInt("_DstBlend", (int)UnityBlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON"); // TODO: check impl
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

				// TODO: check impl
				switch (blendMode)
				{
					case BlendMode.Alpha:
						material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
						break;
					case BlendMode.Premultiply:
						material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
						break;
					case BlendMode.Additive:
						material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
						break;
					case BlendMode.Multiply:
						material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
						material.EnableKeyword("_ALPHAMODULATE_ON");
						break;
				}

				material.SetOverrideTag("RenderType", "Transparent");
				material.SetInt("_ZWrite", 0);
				material.renderQueue = (int)RenderQueue.Transparent;
				material.renderQueue +=
					material.HasProperty("_QueueOffset") ? (int)material.GetFloat("_QueueOffset") : 0;
				material.SetShaderPassEnabled("ShadowCaster", false);
			}

			materialEditor.PropertiesChanged();
		}

		private static void DrawBlendMode(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var blendProperty = FindProperty("_Blend", properties);
			var currentBlendMode = (BlendMode)blendProperty.floatValue;

			EditorGUI.showMixedValue =
				blendProperty.hasMixedValue || FindProperty("_Surface", properties).hasMixedValue;
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

			EditorGUI.showMixedValue = false;
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

			DrawPropertyCustom(materialEditor, properties, "Priority", DrawQueueOffset);
		}

		private static void DrawQueueOffset(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var property = FindProperty("_QueueOffset", properties);
			EditorGUI.showMixedValue = property.hasMixedValue;
			var currentValue = (int)property.floatValue;
			var newValue = EditorGUILayout.IntSlider(currentValue, -queueOffsetRange, queueOffsetRange);
			if (currentValue != newValue)
			{
				property.floatValue = newValue;
				materialEditor.PropertiesChanged();
			}

			EditorGUI.showMixedValue = false;
		}
	}
}