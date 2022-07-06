using System;
using UnityEngine;

namespace DELTation.ToonShader.Custom
{
	[CreateAssetMenu(menuName = "DELTation/Custom Toon Shader")]
	public class CustomToonShader : ScriptableObject
	{
		[HideInInspector]
		public Shader SourceShader;
		[HideInInspector]
		public Shader Shader;
		public string ShaderName;
		public CustomToonShaderProperty[] Properties;

		private void Reset()
		{
			if (string.IsNullOrEmpty(ShaderName))
				ShaderName = name;
		}

		[Serializable]
		public class CustomToonShaderProperty
		{
			public string Name = "_Property";
			public string DisplayName = "Property";
			public string Type = "Float";
			public string DefaultValue = "0";
		}
	}
}