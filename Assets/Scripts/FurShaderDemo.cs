using UnityEngine;

public class FurShaderDemo : MonoBehaviour
{
	public Material[] OriginalMaterials;
	[Min(0f)]
	public float FurLength;
	[Min(1)]
	public int StepsCount = 1;
	public Material Material;

	private void OnValidate()
	{
		var r = GetComponent<Renderer>();

		var furStepIncrement = 1f / StepsCount;
		var materials = new Material[StepsCount + OriginalMaterials.Length];
		var propertyBlocks = new MaterialPropertyBlock[StepsCount];

		for (var i = 0; i < OriginalMaterials.Length; i++)
		{
			materials[i] = OriginalMaterials[i];
		}

		for (var i = 0; i < StepsCount; i++)
		{
			var furStep = i * furStepIncrement;
			var furMaterial = Material;
			var propertyBlock = new MaterialPropertyBlock();
			propertyBlock.SetFloat("_FurLength", FurLength);
			propertyBlock.SetFloat("_FurStep", furStep);

			var materialIndex = i + OriginalMaterials.Length;
			materials[materialIndex] = furMaterial;
			propertyBlocks[i] = propertyBlock;
		}

		r.sharedMaterials = materials;

		for (var i = 0; i < StepsCount; i++)
		{
			r.SetPropertyBlock(propertyBlocks[i], i + OriginalMaterials.Length);
		}
	}
}