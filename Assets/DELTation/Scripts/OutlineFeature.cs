using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace DELTation.Scripts
{
	public class OutlineFeature : ScriptableRendererFeature
	{
		private class OutlinePass : ScriptableRenderPass
		{
			private RenderTargetIdentifier Source { get; set; }
			private RenderTargetHandle Destination { get; set; }
			private readonly Material _outlineMaterial;
			private RenderTargetHandle _temporaryColorTexture;

			public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination)
			{
				Source = source;
				Destination = destination;
			}

			public OutlinePass(Material outlineMaterial) => _outlineMaterial = outlineMaterial;


			public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor) { }

			public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
			{
				var cmd = CommandBufferPool.Get("Outline Pass");

				var opaqueDescriptor = renderingData.cameraData.cameraTargetDescriptor;
				opaqueDescriptor.depthBufferBits = 0;

				if (Destination == RenderTargetHandle.CameraTarget)
				{
					cmd.GetTemporaryRT(_temporaryColorTexture.id, opaqueDescriptor, FilterMode.Point);
					Blit(cmd, Source, _temporaryColorTexture.Identifier(), _outlineMaterial, 0);
					Blit(cmd, _temporaryColorTexture.Identifier(), Source);
				}
				else
				{
					Blit(cmd, Source, Destination.Identifier(), _outlineMaterial, 0);
				}

				context.ExecuteCommandBuffer(cmd);
				CommandBufferPool.Release(cmd);
			}

			/// Cleanup any allocated resources that were created during the execution of this render pass.
			public override void FrameCleanup(CommandBuffer cmd)
			{
				if (Destination == RenderTargetHandle.CameraTarget)
					cmd.ReleaseTemporaryRT(_temporaryColorTexture.id);
			}
		}

		[System.Serializable]
		public class OutlineSettings
		{
			public Material OutlineMaterial = default;
		}

		public OutlineSettings Settings = new OutlineSettings();
		private OutlinePass _outlinePass;
		private RenderTargetHandle _outlineTexture;

		public override void Create()
		{
			_outlinePass = new OutlinePass(Settings.OutlineMaterial)
			{
				renderPassEvent = RenderPassEvent.AfterRenderingTransparents,
			};
			_outlineTexture.Init("_OutlineTexture");
		}

		public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
		{
			if (Settings.OutlineMaterial == null)
			{
				Debug.LogWarningFormat("Missing Outline Material");
				return;
			}
#if UNITY_EDITOR

			if (!Lightmapping.isRunning)
			{
#endif


				_outlinePass.Setup(renderer.cameraColorTarget, RenderTargetHandle.CameraTarget);
				renderer.EnqueuePass(_outlinePass);

#if UNITY_EDITOR
			}

#endif
		}
	}
}