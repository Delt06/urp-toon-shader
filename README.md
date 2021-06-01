# URP Toon Shader for Unity
A toon shader compatible with the Universal Rendering Pipeline.
> Developed and verified with Unity 2020.3.0f1 LTS and URP package 10.3.2

![Main](Showcase/main.png)

## Shader Capabilities
- 2 or 3-step ramp with configurable thresholds and smoothness
- Ramp textures
- Main and additional lights
- Casting and receiving shadows
- Configurable shadow color
- Emission
- Rim lighting (Fresnel effect) and specular highlights with HDR color support (e.g. for bloom)
- Fog
- SSAO
- SRP Batcher compatibility

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

## Used Assets
- [Animated Mech Pack](https://quaternius.com/packs/animatedmech.html) by Quaternius
