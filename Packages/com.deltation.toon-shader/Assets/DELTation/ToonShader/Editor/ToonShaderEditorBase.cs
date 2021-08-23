using UnityEditor;
using UnityEngine;

namespace DELTation.ToonShader.Editor
{
	public abstract class ToonShaderEditorBase : ShaderGUI
	{
		private GUIStyle _headerStyle;

		protected virtual bool InstancingField => true;
		protected virtual bool RenderQueueField => true;

		public sealed override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var material = materialEditor.target as Material;
			if (material == null) return;

			_headerStyle = new GUIStyle
			{
				normal = new GUIStyleState
				{
					textColor = Color.white,
				},
				richText = true,
			};

			DrawProperties(materialEditor, properties, material);

			if (InstancingField)
				materialEditor.EnableInstancingField();

			if (RenderQueueField)
				materialEditor.RenderQueueField();
		}

		protected abstract void DrawProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material);

		protected void Label(string text) => GUILayout.Label($"<b>{text}</b>", _headerStyle);

		protected void MiscLabel() => Label("Misc");

		protected void RampLabel() => Label("Ramp");

		protected static void DrawProperty(MaterialEditor materialEditor, MaterialProperty[] properties, string name)
		{
			var property = FindProperty(name, properties);
			materialEditor.ShaderProperty(property, property.displayName);
		}

		protected static void DrawColorProperties(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			DrawProperty(materialEditor, properties, "_BaseMap");
			DrawProperty(materialEditor, properties, "_BaseColor");
		}

		protected static void DrawRampProperty0(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			DrawProperty(materialEditor, properties, "_Ramp0");
		}

		protected static void DrawRampSmoothnessProperty(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			DrawProperty(materialEditor, properties, "_RampSmoothness");
		}

		protected static void DrawShadowTintProperty(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			DrawProperty(materialEditor, properties, "_ShadowTint");
		}

		protected static void DrawFogProperty(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			DrawProperty(materialEditor, properties, "_Fog");
		}

		protected static void DrawVertexColorProperty(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			DrawProperty(materialEditor, properties, "_VertexColor");
		}
	}
}