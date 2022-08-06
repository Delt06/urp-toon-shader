using System.Collections.Generic;
using JetBrains.Annotations;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine;

namespace DELTation.ToonShader.Editor
{
	public abstract class ToonShaderEditorBase : ShaderGUI
	{
		private readonly Dictionary<string, bool> _foldouts = new();

		protected virtual bool InstancingField => true;
		protected virtual bool RenderQueueField => true;

		public sealed override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var material = materialEditor.target as Material;
			if (material == null) return;

			DrawProperties(materialEditor, properties, material);

			EditorGUILayout.Space();

			if (InstancingField)
				materialEditor.EnableInstancingField();

			if (RenderQueueField)
				materialEditor.RenderQueueField();
		}

		protected abstract void DrawProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material);

		protected void Foldout(in MaterialEditorContext context, string text, MaterialPropertiesDrawer drawer,
			bool openByDefault = false)
		{
			const int space = 1;
			EditorGUILayout.Space(space);

			if (!_foldouts.TryGetValue(text, out var foldout))
				foldout = openByDefault;

			foldout = CoreEditorUtils.DrawHeaderFoldout(new GUIContent(text), foldout);
			_foldouts[text] = foldout;

			if (foldout)
			{
				EditorGUI.indentLevel++;
				drawer(context);
				EditorGUI.indentLevel--;
			}

			EditorGUILayout.Space(space);
		}

		protected void MiscFoldout(in MaterialEditorContext context, MaterialPropertiesDrawer drawer,
			bool openByDefault = false) => Foldout(context, "Misc", drawer, openByDefault);

		protected void RampFoldout(in MaterialEditorContext context, MaterialPropertiesDrawer drawer,
			bool openByDefault = true) => Foldout(context, "Ramp", drawer, openByDefault);

		protected static void DrawProperty(in MaterialEditorContext ctx, string name,
			[CanBeNull] string labelOverride = null)
		{
			var property = FindProperty(name, ctx.Properties);
			ctx.MaterialEditor.ShaderProperty(property, labelOverride ?? property.displayName);
		}

		protected static void DrawProperty(in MaterialEditorContext ctx, int index)
		{
			var property = ctx.Properties[index];
			ctx.MaterialEditor.ShaderProperty(property, property.displayName);
		}

		protected static void DrawAlbedo(in MaterialEditorContext ctx)
		{
			DrawProperty(ctx, "_BaseMap");
			DrawProperty(ctx, "_BaseColor");
		}

		protected static void DrawRampProperty0(in MaterialEditorContext ctx) =>
			DrawProperty(ctx, "_Ramp0");

		protected static void DrawRampSmoothnessProperty(in MaterialEditorContext ctx) =>
			DrawProperty(ctx, "_RampSmoothness");

		protected static void DrawShadowTintProperty(in MaterialEditorContext ctx) =>
			DrawProperty(ctx, "_ShadowTint");

		protected static void DrawFogProperty(in MaterialEditorContext ctx) =>
			DrawProperty(ctx, "_Fog");

		protected static void DrawVertexColorProperty(in MaterialEditorContext ctx) =>
			DrawProperty(ctx, "_VertexColor");
	}
}