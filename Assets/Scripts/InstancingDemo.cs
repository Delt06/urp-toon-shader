using UnityEngine;
using Random = UnityEngine.Random;

public class InstancingDemo : MonoBehaviour
{
	private const int MaxInstances = 1023;
	[SerializeField, Range(1, MaxInstances)] private int _instances = MaxInstances;
	public Material Material;
	public Mesh Mesh;

	private static readonly int BaseColorId = Shader.PropertyToID("i_BaseColor");

	// https://catlikecoding.com/unity/tutorials/custom-srp/draw-calls/
	private Matrix4x4[] _matrices;
	private Vector4[] _baseColors;
	private MaterialPropertyBlock _block;

	private void Awake()
	{
		_matrices = new Matrix4x4[_instances];
		_baseColors = new Vector4[_instances];
		
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

		Graphics.DrawMeshInstanced(Mesh, 0, Material, _matrices, _instances, _block);
	}
}