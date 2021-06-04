# URP Toon Shader for Unity
A toon shader compatible with the Universal Rendering Pipeline.
> Developed and verified with Unity 2020.3.0f1 LTS and URP package 10.3.2

![Main](Showcase/main.png)

## Toon Shader Capabilities
- 2 or 3-step ramp with configurable thresholds and smoothness
- Ramp textures
- Main light
- Additional lights (per-vertex or per-pixel, depending on URP settings)
- Casting and receiving shadows
- Configurable shadow color
- Emission
- Rim lighting (Fresnel effect) and specular highlights with HDR color support (e.g. for bloom)
- Fog
- SSAO
- Ambient Lighting
- SRP Batcher compatibility
- GPU Instancing

## Toon Shader (Lite) Capabilities
- 2-step ramp with configurable threshold and smoothness
- Main light (per-vertex or per-pixel)
- Casting shadows
- Configurable shadow color
- Fog
- SRP Batcher compatibility
- GPU Instancing

## Extras
- Depth+Normals+Color-based outline render feature

## Installation
### Option 1
- Open Package Manager through Window/Package Manager
- Click "+" and choose "Add package from git URL..."
- Insert the URL: https://github.com/Delt06/urp-toon-shader.git?path=Packages/com.deltation.toon-shader

### Option 2
Add the following line to `Packages/manifest.json`:
```
"com.deltation.toon-shader": "https://github.com/Delt06/urp-toon-shader.git?path=Packages/com.deltation.toon-shader",
```

## Performance
Lit vs. URP Toon Shader vs. Toony Colors Pro (Hybrid)

> The results are obtained with Mali Offline Compiler.

Shader Type               | Vertex Shader Cycles (L/S) | Fragment Shader Cycles (L/S)
--------------------------|----------------------------|-----------------------------
Lit                       | 9                          | 15
URP Toon Shader           | 12                         | 10
Toony Colors Pro (Hybrid) | 7                          | 15

> L/S = Load/Store.


### Configuration
```
Hardware: Mali-G78 r1p1
Architecture: Valhall
Driver: r25p0-00rel0
```

### Enabled keywords
Lit:
```
Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE  _SHADOWS_SOFT
Local Keywords: _EMISSION
```

URP Toon Shader:
```
Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT 
Local Keywords: _ADDITIONAL_LIGHTS_ENABLED _ENVIRONMENT_LIGHTING_ENABLED _FOG _FRESNEL _RAMP_TRIPLE _SPECULAR
```

Toony Colors Pro (Hybrid)
```
Global Keywords: FOG_LINEAR TCP2_HYBRID_URP _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT 
Local Keywords: TCP2_REFLECTIONS_FRESNEL TCP2_RIM_LIGHTING_LIGHTMASK TCP2_SHADOW_LIGHT_COLOR
```

## Used Assets
- [Animated Mech Pack](https://quaternius.com/packs/animatedmech.html) by Quaternius
