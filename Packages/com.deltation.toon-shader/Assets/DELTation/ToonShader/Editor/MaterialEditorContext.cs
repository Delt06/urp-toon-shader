using UnityEditor;
using UnityEngine;

namespace DELTation.ToonShader.Editor
{
	public readonly struct MaterialEditorContext
	{
		public readonly MaterialEditor MaterialEditor;
		public readonly MaterialProperty[] Properties;
		public readonly Material Material;

		public MaterialEditorContext(MaterialEditor materialEditor, MaterialProperty[] properties, Material material)
		{
			MaterialEditor = materialEditor;
			Properties = properties;
			Material = material;
		}
	}
}