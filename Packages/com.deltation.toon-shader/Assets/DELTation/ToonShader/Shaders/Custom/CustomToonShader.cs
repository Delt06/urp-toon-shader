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
	}
}