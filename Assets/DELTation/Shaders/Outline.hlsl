TEXTURE2D(_CameraColorTexture);
SAMPLER(sampler_CameraColorTexture);
float4 _CameraColorTexture_TexelSize;

TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

TEXTURE2D(_CameraDepthNormalsTexture);
SAMPLER(sampler_CameraDepthNormalsTexture);

float3 decode_normal(const float4 enc)
{
    const float scale = 1.7777;
    const float3 nn = enc.xyz * float3(2 * scale, 2 * scale, 0) + float3(-scale, -scale, 1);
    const float g = 2.0 / dot(nn.xyz, nn.xyz);
    float3 n;
    n.xy = g * nn.xy;
    n.z = g - 1;
    return n;
}

void Outline_float(float2 UV, float OutlineThickness, float DepthSensitivity, float NormalsSensitivity,
                   float ColorSensitivity, float4 OutlineColor, out float4 Out)
{
    const float half_scale_floor = floor(OutlineThickness * 0.5);
    const float half_scale_ceil = ceil(OutlineThickness * 0.5);
    float2 texel = 1.0 / float2(_CameraColorTexture_TexelSize.z, _CameraColorTexture_TexelSize.w);

    float2 uv_samples[4];
    float depth_samples[4];

    float3 normal_samples[4], color_samples[4];

    uv_samples[0] = UV - float2(texel.x, texel.y) * half_scale_floor;
    uv_samples[1] = UV + float2(texel.x, texel.y) * half_scale_ceil;
    uv_samples[2] = UV + float2(texel.x * half_scale_ceil, -texel.y * half_scale_floor);
    uv_samples[3] = UV + float2(-texel.x * half_scale_floor, texel.y * half_scale_ceil);

    [unroll]
    for (int i = 0; i < 4; i++)
    {
        depth_samples[i] = SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture,
                                           uv_samples[i]).a;
        normal_samples[i] = decode_normal(SAMPLE_TEXTURE2D(_CameraDepthNormalsTexture, sampler_CameraDepthNormalsTexture,
                                                         uv_samples[i]));
        color_samples[i] = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, uv_samples[i]).xyz;
    }

    // Depth
    const float depth_finite_difference0 = depth_samples[1] - depth_samples[0];
    const float depth_finite_difference1 = depth_samples[3] - depth_samples[2];
    float edge_depth = sqrt(pow(depth_finite_difference0, 2) + pow(depth_finite_difference1, 2)) * 100;
    const float depth_threshold = 1 / DepthSensitivity * depth_samples[0];
    edge_depth = edge_depth > depth_threshold ? 1 : 0;

    // Normals
    const float3 normal_finite_difference0 = normal_samples[1] - normal_samples[0];
    const float3 normal_finite_difference1 = normal_samples[3] - normal_samples[2];
    float edge_normal = sqrt(
        dot(normal_finite_difference0, normal_finite_difference0) + dot(normal_finite_difference1, normal_finite_difference1));
    edge_normal = edge_normal > 1 / NormalsSensitivity ? 1 : 0;

    // Color
    const float3 color_finite_difference0 = color_samples[1] - color_samples[0];
    const float3 color_finite_difference1 = color_samples[3] - color_samples[2];
    float edge_color = sqrt(
        dot(color_finite_difference0, color_finite_difference0) + dot(color_finite_difference1, color_finite_difference1));
    edge_color = edge_color > 1 / ColorSensitivity ? 1 : 0;

    const float edge = max(edge_depth, max(edge_normal, edge_color));

    const float4 original = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, uv_samples[0]);
    Out = (1 - edge) * original + edge * lerp(original, OutlineColor, OutlineColor.a);
}
