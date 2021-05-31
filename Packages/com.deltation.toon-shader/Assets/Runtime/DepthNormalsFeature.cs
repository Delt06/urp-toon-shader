using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

// ReSharper disable once CheckNamespace
namespace DELTation.ToonShader
{
	public class DepthNormalsFeature : ScriptableRendererFeature
	{
		private class DepthNormalsPass : ScriptableRenderPass
		{
			private RenderTargetHandle Destination { get; set; }

			private readonly Material _depthNormalsMaterial;
			private FilteringSettings _filteringSettings;
			private readonly ShaderTagId _shaderTagId = new ShaderTagId("DepthOnly");

			public DepthNormalsPass(RenderQueueRange renderQueueRange, LayerMask layerMask, Material material)
			{
				_filteringSettings = new FilteringSettings(renderQueueRange, layerMask);
				_depthNormalsMaterial = material;
			}

			public void Setup(RenderTargetHandle destination)
			{
				Destination = destination;
			}

			public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
			{
				var descriptor = cameraTextureDescriptor;
				descriptor.depthBufferBits = 32;
				descriptor.colorFormat = RenderTextureFormat.ARGB32;

				cmd.GetTemporaryRT(Destination.id, descriptor, FilterMode.Point);
				ConfigureTarget(Destination.Identifier());
				ConfigureClear(ClearFlag.All, Color.black);
			}

			public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
			{
				var cmd = CommandBufferPool.Get("DepthNormals Prepass");

				context.ExecuteCommandBuffer(cmd);
				cmd.Clear();

				var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
				var drawSettings = CreateDrawingSettings(_shaderTagId, ref renderingData, sortFlags);
				drawSettings.perObjectData = PerObjectData.None;

				ref var cameraData = ref renderingData.cameraData;
				var camera = cameraData.camera;
				if (cameraData.isStereoEnabled)
					context.StartMultiEye(camera);


				drawSettings.overrideMaterial = _depthNormalsMaterial;


				context.DrawRenderers(renderingData.cullResults, ref drawSettings,
					ref _filteringSettings
				);

				cmd.SetGlobalTexture("_CameraDepthNormalsTexture", Destination.id);

				context.ExecuteCommandBuffer(cmd);
				CommandBufferPool.Release(cmd);
			}

			public override void FrameCleanup(CommandBuffer cmd)
			{
				if (Destination != RenderTargetHandle.CameraTarget)
				{
					cmd.ReleaseTemporaryRT(Destination.id);
					Destination = RenderTargetHandle.CameraTarget;
				}
			}
		}


		[System.Serializable]
		public class DepthNormalsSettings
		{
			public LayerMask LayerMask;
		}

		public DepthNormalsSettings Settings = new DepthNormalsSettings();
		private DepthNormalsPass _depthNormalsPass;
		private RenderTargetHandle _depthNormalsTexture;
		private Material _depthNormalsMaterial;

		public override void Create()
		{
			_depthNormalsMaterial = CoreUtils.CreateEngineMaterial("Hidden/Internal-DepthNormalsTexture");
			_depthNormalsPass = new DepthNormalsPass(RenderQueueRange.opaque, Settings.LayerMask, _depthNormalsMaterial)
			{
				renderPassEvent = RenderPassEvent.AfterRenderingPrePasses,
			};
			_depthNormalsTexture.Init("_CameraDepthNormalsTexture");
		}

		public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
		{
			_depthNormalsPass.Setup(_depthNormalsTexture);
			renderer.EnqueuePass(_depthNormalsPass);
		}
	}
}