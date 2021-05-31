// Taken from the Unity built-in shader source

// MIT License

// Copyright(c) 2016 Unity Technologies

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#ifndef DECODEDEPTHNORMALS_INCLUDED
#define DECODEDEPTHNORMALS_INCLUDED

inline float decode_float_rg(const float2 enc) {
	const float2 decode_dot = float2(1.0, 1 / 255.0);
	return dot(enc, decode_dot);
}

inline float3 decode_view_normal_stereo(const float4 enc) {
	const float k_scale = 1.7777;
	const float3 nn = enc.xyz * float3(2 * k_scale, 2 * k_scale, 0) + float3(-k_scale, -k_scale, 1);
	const float g = 2.0 / dot(nn.xyz, nn.xyz);
	float3 n;
	n.xy = g * nn.xy;
	n.z = g - 1;
	return n;
}

inline void decode_depth_normal(const float4 enc, out float depth, out float3 normal) {
	depth = decode_float_rg(enc.zw);
	normal = decode_view_normal_stereo(enc);
}

#endif