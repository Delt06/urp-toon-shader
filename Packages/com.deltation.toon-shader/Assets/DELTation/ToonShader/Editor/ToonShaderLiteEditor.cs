using JetBrains.Annotations;
using UnityEditor;
using UnityEngine;

namespace DELTation.ToonShader.Editor
{
	[UsedImplicitly]
	public class ToonShaderLiteEditor : ToonShaderEditorBase
	{
		protected override void DrawProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawColorProperties(materialEditor, properties);
			DrawShadowTintProperty(materialEditor, properties);
			RampLabel();
			DrawRampProperty0(materialEditor, properties);
			DrawRampSmoothnessProperty(materialEditor, properties);
			MiscLabel();
			DrawProperty(materialEditor, properties, "_VertexLit");
			DrawProperty(materialEditor, properties, "_ReceiveShadows");
			DrawFogProperty(materialEditor, properties);
			DrawVertexColorProperty(materialEditor, properties);
		}
	}
}