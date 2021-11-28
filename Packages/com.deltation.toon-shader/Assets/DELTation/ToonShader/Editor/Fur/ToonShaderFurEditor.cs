using JetBrains.Annotations;
using UnityEditor;
using UnityEngine;

namespace DELTation.ToonShader.Editor.Fur
{
	[UsedImplicitly]
	public class ToonShaderFurEditor : ToonShaderEditor
	{
		protected override void DrawProperties(MaterialEditor materialEditor, MaterialProperty[] properties, Material material)
		{
			base.DrawProperties(materialEditor, properties, material);
			
			Label("Fur");
			DrawProperty(materialEditor, properties, "_FurLength");
			DrawProperty(materialEditor, properties, "_FurStep");
			DrawProperty(materialEditor, properties, "_FurNoise");
			DrawProperty(materialEditor, properties, "_FurMask");
		}
	}
}