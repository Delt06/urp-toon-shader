using System;
using System.Collections.Generic;
using System.Linq;
using JetBrains.Annotations;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityBlendMode = UnityEngine.Rendering.BlendMode;

// ReSharper disable Unity.PreferAddressByIdToGraphicsParams

namespace DELTation.ToonShader.Editor
{
	[UsedImplicitly]
	public class ToonShaderEditor : ToonShaderEditorBase
	{
		private const int QueueOffsetRange = 50;

		private static readonly Dictionary<(UnityBlendMode src, UnityBlendMode dst), BlendMode>
			UnityBlendModeToBlendMode =
				new()
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
			var ctx = new MaterialEditorContext(materialEditor, properties, material);
			Foldout(ctx, "Surface Options", DrawSurfaceProperties);
			DrawCustomProperties(ctx);
			Foldout(ctx, "Color", DrawColorProperties, true);
			RampFoldout(ctx, DrawRampProperties);
			Foldout(ctx, "Normal Map", DrawNormalMapProperties);
			Foldout(ctx, "Emission", DrawEmissionProperties);
			Foldout(ctx, "Rim", DrawRimProperties);
			Foldout(ctx, "Specular", DrawSpecularProperties);
			Foldout(ctx, "Reflections", DrawReflectionProperties);
			MiscFoldout(ctx, DrawMiscProperties);
		}

		private static void DrawColorProperties(in MaterialEditorContext ctx) =>
			DrawAlbedo(ctx);

		private static void DrawSurfaceProperties(in MaterialEditorContext ctx)
		{
			DrawPropertyCustom(ctx, "Surface Type", DrawSurfaceType);
			if (IsTransparent(ctx.Properties))
				DrawPropertyCustom(ctx, "Blending Mode", DrawBlendMode);

			DrawPropertyCustom(ctx, "Alpha Clipping", DrawAlphaClip);
			if (IsAlphaClip(ctx.Properties))
				DrawProperty(ctx, "_Cutoff");

			DrawProperty(ctx, "_Cull");
		}

		private void DrawCustomProperties(in MaterialEditorContext context)
		{
			var shader = context.Material.shader;
			var customPropertyIndices = new List<int>();

			for (var i = 0; i < context.Properties.Length; i++)
			{
				var attributes = shader.GetPropertyAttributes(i);
				if (attributes.Contains("CustomProperty"))
					customPropertyIndices.Add(i);
			}

			if (customPropertyIndices.Count == 0) return;

			Foldout(context, "Custom", (in MaterialEditorContext ctx) =>
				{
					foreach (var index in customPropertyIndices)
					{
						DrawProperty(ctx, index);
					}
				}
			);
		}

		private static void DrawNormalMapProperties(in MaterialEditorContext ctx)
		{
			EditorGUI.BeginChangeCheck();
			const string bumpMapProperty = "_BumpMap";
			DrawProperty(ctx, bumpMapProperty);

			if (!EditorGUI.EndChangeCheck()) return;

			var property = FindProperty(bumpMapProperty, ctx.Properties);
			const string normalMapKeyword = "_NORMALMAP";
			if (property.textureValue == null)
				ctx.Material.DisableKeyword(normalMapKeyword);
			else
				ctx.Material.EnableKeyword(normalMapKeyword);
			ctx.MaterialEditor.PropertiesChanged();
		}

		private static bool IsAlphaClip(MaterialProperty[] properties) =>
			FindProperty("_AlphaClip", properties).floatValue > 0.5f;

		private static bool IsTransparent(MaterialProperty[] properties) =>
			(SurfaceType)FindProperty("_Surface", properties).floatValue == SurfaceType.Transparent;

		private static void DrawAlphaClip(in MaterialEditorContext ctx)
		{
			var properties = ctx.Properties;
			var materialEditor = ctx.MaterialEditor;

			var property = FindProperty("_AlphaClip", properties);
			var alphaClip = property.floatValue > 0.5f;

			EditorGUI.showMixedValue = property.hasMixedValue;
			EditorGUI.BeginChangeCheck();
			var newAlphaClip = EditorGUILayout.Toggle(alphaClip);

			if (EditorGUI.EndChangeCheck())
			{
				property.floatValue = newAlphaClip ? 1f : 0f;
				materialEditor.PropertiesChanged();
				TryUpdateSurfaceData(ctx);
			}

			EditorGUI.showMixedValue = false;
		}

		private static void DrawSurfaceType(in MaterialEditorContext ctx)
		{
			var surfaceProperty = FindProperty("_Surface", ctx.Properties);
			var surfaceType = (SurfaceType)surfaceProperty.floatValue;

			EditorGUI.showMixedValue = surfaceProperty.hasMixedValue;
			EditorGUI.BeginChangeCheck();
			var newSurfaceType = (SurfaceType)EditorGUILayout.EnumPopup(surfaceType);

			if (EditorGUI.EndChangeCheck())
			{
				surfaceProperty.floatValue = (float)newSurfaceType;
				ctx.MaterialEditor.PropertiesChanged();
				TryUpdateSurfaceData(ctx);
			}

			EditorGUI.showMixedValue = false;
		}

		private static void TryUpdateSurfaceData(in MaterialEditorContext ctx)
		{
			var properties = ctx.Properties;
			var surfaceProperty = FindProperty("_Surface", properties);
			var surfaceType = (SurfaceType)surfaceProperty.floatValue;
			var materialEditor = ctx.MaterialEditor;
			var material = (Material)materialEditor.target;
			var alphaClip = IsAlphaClip(properties);

			const string alphaTestOnKeyword = "_ALPHATEST_ON";
			if (alphaClip)
				material.EnableKeyword(alphaTestOnKeyword);
			else
				material.DisableKeyword(alphaTestOnKeyword);

			const string surfaceTypeTransparentKeyword = "_SURFACE_TYPE_TRANSPARENT";
			if (surfaceType == SurfaceType.Transparent)
				material.EnableKeyword(surfaceTypeTransparentKeyword);
			else
				material.DisableKeyword(surfaceTypeTransparentKeyword);

			const string alphapremultiplyOnKeyword = "_ALPHAPREMULTIPLY_ON";
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
				material.DisableKeyword(alphapremultiplyOnKeyword);
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


				switch (blendMode)
				{
					case BlendMode.Alpha:
						material.DisableKeyword(alphapremultiplyOnKeyword);
						break;
					case BlendMode.Premultiply:
						material.EnableKeyword(alphapremultiplyOnKeyword);
						break;
					case BlendMode.Additive:
						material.DisableKeyword(alphapremultiplyOnKeyword);
						break;
					case BlendMode.Multiply:
						material.DisableKeyword(alphapremultiplyOnKeyword);
						break;
					default:
						throw new ArgumentOutOfRangeException();
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

		private static void DrawBlendMode(in MaterialEditorContext ctx)
		{
			var properties = ctx.Properties;
			var materialEditor = ctx.MaterialEditor;

			var blendProperty = FindProperty("_Blend", properties);
			var currentBlendMode = (BlendMode)blendProperty.floatValue;

			EditorGUI.showMixedValue =
				blendProperty.hasMixedValue || FindProperty("_Surface", properties).hasMixedValue;
			EditorGUI.BeginChangeCheck();
			var newBlendMode = (BlendMode)EditorGUILayout.EnumPopup(currentBlendMode);


			var (newSrcBlend, newDstBlend) = ConvertBlendModeToUnityBlendMode(newBlendMode);

			if (EditorGUI.EndChangeCheck())
			{
				var srcBlendProperty = FindProperty("_SrcBlend", properties);
				srcBlendProperty.floatValue = (float)newSrcBlend;
				var dstBlendProperty = FindProperty("_DstBlend", properties);
				dstBlendProperty.floatValue = (float)newDstBlend;
				blendProperty.floatValue = (float)newBlendMode;
				materialEditor.PropertiesChanged();
				TryUpdateSurfaceData(ctx);
			}

			EditorGUI.showMixedValue = false;
		}

		private static void DrawPropertyCustom(in MaterialEditorContext ctx,
			string label,
			MaterialPropertiesDrawer draw)
		{
			GUILayout.BeginHorizontal();
			GUILayout.Label(label);
			GUILayout.FlexibleSpace();

			draw(ctx);

			GUILayout.EndHorizontal();
		}

		private static (UnityBlendMode src, UnityBlendMode dst) ConvertBlendModeToUnityBlendMode(BlendMode blendMode)
		{
			var result = UnityBlendModeToBlendMode.FirstOrDefault(x => x.Value == blendMode).Key;
			return result != default ? result : (UnityBlendMode.SrcAlpha, UnityBlendMode.OneMinusSrcAlpha);
		}

		private static void DrawRampProperties(in MaterialEditorContext ctx)
		{
			var material = ctx.Material;

			DrawProperty(ctx, "_UseRampMap");

			if (material.IsKeywordEnabled("_RAMP_MAP"))
			{
				DrawProperty(ctx, "_RampMap");
			}
			else
			{
				DrawProperty(ctx, "_PureShadowColor");
				DrawShadowTintProperty(ctx);
				DrawProperty(ctx, "_RampTriple");
				DrawRampProperty0(ctx);

				if (material.IsKeywordEnabled("_RAMP_TRIPLE"))
					DrawProperty(ctx, "_Ramp1");

				DrawRampSmoothnessProperty(ctx);
			}
		}

		private static void DrawEmissionProperties(in MaterialEditorContext ctx)
		{
			EditorGUILayout.BeginHorizontal();
			DrawProperty(ctx, "_Emission", "Enable");

			if (ctx.Material.IsKeywordEnabled("_EMISSION"))
				DrawProperty(ctx, "_EmissionColor");

			EditorGUILayout.EndHorizontal();
		}

		private static void DrawRimProperties(in MaterialEditorContext ctx)
		{
			DrawProperty(ctx, "_Fresnel", "Enable");
			if (!ctx.Material.IsKeywordEnabled("_FRESNEL")) return;

			DrawProperty(ctx, "_FresnelColor");
			DrawProperty(ctx, "_FresnelThickness");
			DrawProperty(ctx, "_FresnelSmoothness");
		}

		private static void DrawSpecularProperties(in MaterialEditorContext ctx)
		{
			DrawProperty(ctx, "_Specular", "Enable");
			if (!ctx.Material.IsKeywordEnabled("_SPECULAR")) return;

			DrawProperty(ctx, "_AnisoSpecular");
			DrawProperty(ctx, "_SpecularColor");
			DrawProperty(ctx, "_SpecularThreshold");
			DrawProperty(ctx, "_SpecularExponent");
			DrawProperty(ctx, "_SpecularSmoothness");
		}

		private static void DrawReflectionProperties(in MaterialEditorContext ctx)
		{
			DrawProperty(ctx, "_Reflections", "Enable");
			if (!ctx.Material.IsKeywordEnabled("_REFLECTIONS")) return;

			DrawProperty(ctx, "_ReflectionSmoothness");
			DrawProperty(ctx, "_ReflectionBlend");
			DrawProperty(ctx, "_ReflectionProbes");
		}

		private static void DrawMiscProperties(in MaterialEditorContext ctx)
		{
			DrawFogProperty(ctx);

			DrawProperty(ctx, "_AdditionalLights");

			var material = ctx.Material;
			if (material.IsKeywordEnabled("_ADDITIONAL_LIGHTS_ENABLED") &&
			    material.IsKeywordEnabled("_SPECULAR"))
				DrawProperty(ctx, "_AdditionalLightsSpecular");

			DrawProperty(ctx, "_EnvironmentLightingEnabled");
			DrawProperty(ctx, "_ShadowMask");


			DrawVertexColorProperty(ctx);

			DrawPropertyCustom(ctx, "Priority", DrawQueueOffset);
		}

		private static void DrawQueueOffset(in MaterialEditorContext ctx)
		{
			var property = FindProperty("_QueueOffset", ctx.Properties);
			EditorGUI.showMixedValue = property.hasMixedValue;
			var currentValue = (int)property.floatValue;
			var newValue = EditorGUILayout.IntSlider(currentValue, -QueueOffsetRange, QueueOffsetRange);
			if (currentValue != newValue)
			{
				property.floatValue = newValue;
				ctx.MaterialEditor.PropertiesChanged();
			}

			EditorGUI.showMixedValue = false;
		}

		private enum BlendMode
		{
			Alpha,
			Premultiply,
			Additive,
			Multiply,
		}

		private enum SurfaceType
		{
			Opaque,
			Transparent,
		}
	}
}