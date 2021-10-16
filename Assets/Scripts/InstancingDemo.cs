using UnityEngine;
using Random = UnityEngine.Random;

public class InstancingDemo : MonoBehaviour
{
	public Material Material;
	public Mesh Mesh;

	private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");

	// https://catlikecoding.com/unity/tutorials/custom-srp/draw-calls/
	private readonly Matrix4x4[] _matrices = new Matrix4x4[1023];
	private readonly Vector4[] _baseColors = new Vector4[1023];
	private MaterialPropertyBlock _block;

	private void Awake()
	{
		for (var i = 0; i < _matrices.Length; i++)
		{
			_matrices[i] = Matrix4x4.TRS(
				Random.insideUnitSphere * 10f, Quaternion.identity, Vector3.one
			);
			_baseColors[i] =
				new Vector4(Random.value, Random.value, Random.value, 1f);
		}
	}

	private void Update()
	{
		if (_block == null)
		{
			_block = new MaterialPropertyBlock();
			_block.SetVectorArray(BaseColorId, _baseColors);
		}

		Graphics.DrawMeshInstanced(Mesh, 0, Material, _matrices, 1023, _block);
	}
}