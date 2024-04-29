# Shader Showcase 2024
**Unity BIRP - Version 2022.3.21f1 (LTS)  
THIS PROJECT WILL PROBABLY ONLY LAST FOR THE CURRENT YEAR ITS BEING WORKED ON (2024).**

*The yearly showcase project every year so this will probably be for the year of 2024 & again another new project will come in 2025... maybe.*  
*Link to previous shader showcase project here > [Shader Showcase 2023](https://github.com/j-2k/ShaderShowcase2023Public)*

I'll try to make this readme less messy this time since the last shadershowcase's readme was very messy, my bad!

## Jumping into Art Piece Ideas & Reference Images!
![EclipseScene](https://github.com/j-2k/ShaderShowcase2024/assets/52252068/0f7a8e9f-b78c-428d-9b96-c72eb2524df7)

This is the end of the readme the only thing below is my personal notes & cheatsheet where I post code that is commonly duplicated & used in many shader scripts mainly for myself but could be useful to you also!

# My Notes & Cheatsheet you can skip this!
### Credits & Learning resources at the end!
I will try commenting the code below in each section to help me understand what's going on for each section of the cheatsheet! Should be useful when revising certain topics & mainly just learning & understanding for myself.

**IMPORTANT NOTE: DONT FORGET YOUR VARIABLES IN THE V2F STRUCT & APP DATA STRUCT!!!**

---
### Get world position of the mesh's verticies!
```hlsl
//IN VERT SHADER:
o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
```
---
###  Matcap Shader Implementation (w/ Perspective Fix)
NO PERSPECTIVE FIX
```hlsl
//IN VERT SHADER:
float3 viewNorm = normalize(mul(UNITY_MATRIX_MV, v.normal));
o.matcapUV = viewNorm.xy * 0.5 + 0.5;
//Use the matcapUV as a substitute for the UV slot in sampling textures!
//If its working you should see a non tiled texture facing you with some perspective deviation when you looking away from it!
//If its tiled it needs to be normalized! when you look directly at it, it should directly face you!
```
WITH PERSPECTIVE FIX
```hlsl
//IN VERT SHADER:
float3 worldNorm = UnityObjectToWorldNormal(v.normal);
float3 viewNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);

//The bulk of the prespective fix below from bgolus : 
{ //https://forum.unity.com/threads/getting-normals-relative-to-camera-view.452631/
  // get view space position of vertex
  float3 viewPos = UnityObjectToViewPos(v.vertex);
  float3 viewDir = normalize(viewPos);
  
  // get vector perpendicular to both view direction and view normal
  float3 viewCross = cross(viewDir, viewNorm);
                     
  // swizzle perpendicular vector components to create a new perspective corrected view normal
  viewNorm = float3(-viewCross.y, viewCross.x, 0.0);
}
o.matcapUV = viewNorm.xy * 0.5 + 0.5;
//Use the matcapUV as a substitute for the UV slot in sampling textures!
//If you use this the matcap will always look at the camera!
```
---
### UV Spherical Unwrapping!
```hlsl
//IN VERT SHADER:
o.worldPos = mul(unity_ObjectToWorld,v.vertex);

//IN FRAG SHADER:
float3 worldPos = normalize(i.worldPos);
float arcSineY = asin(worldPos.y)/(PI/2); //PI/2;
float arcTan2X = atan2(worldPos.x,worldPos.z)/TAU;
float2 skyUV = float2(arcTan2X,arcSineY);
```
---
### *DEPENDENT VIEW* Water Depth!
```hlsl
//IN FRAG SHADER:
//Get Linear Depth Value
float depth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;
//The operation above is the same as the bottom one! just showing to help understand why we use the proj function
//float depth01 = tex2D(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition.xy / i.screenPosition.w)).r;
float depthFromEyeLinear = LinearEyeDepth(depth01);
                
float depthDifference = depthFromEyeLinear - i.screenPos.w;
float depthFade = 1 - saturate(depthDifference/_DepthFadeDist);
```
---
### *INDEPENDENT VIEW* Water Depth!  
```hlsl
//IN FRAG SHADER:
//(I converted it to shader code, since im on BIRP, hope its correct lmfao (seems to be atleast...😳))
float3 viewVectorWorldSpace = -1 * (_WorldSpaceCameraPos.xyz - i.worldPos); //CARE THIS IS NOT NORMALIZED!!!
//float3 viewVectorViewSpace = normalize(UnityWorldSpaceViewDir(vertexWorldPos));

float3 vvws = (viewVectorWorldSpace/i.screenPos.w) * depthFromEyeLinear;
float3 worldSpaceScenePos = vvws + _WorldSpaceCameraPos.xyz;

float3 worldWaterPos = i.worldPos - worldSpaceScenePos;
float worldWaterSurfaceToBottomDepth = worldWaterPos.y * -1;
worldWaterSurfaceToBottomDepth = saturate(exp(worldWaterSurfaceToBottomDepth/_DepthFadeDist));

return worldWaterSurfaceToBottomDepth;
```
---

# Optimization Notes
- Adding & Multiplication operations in a shader can be done in one gpu cycle and is very optimal & fast in a shader. Try using it as much as possible and avoid subtracting & diving whenever you can!

[![An old rock in the desert](https://github.com/j-2k/ShaderShowcase2024/assets/52252068/ace16119-1aab-4439-9264-464426769c46 "Texture Memory Table by Ben Cloward")](https://www.youtube.com/watch?v=WJkEacYRhPU)  

***IMPORTANT NOTE: THE TEXTURE MEMORY COST IS IN KB & THIS IS THE FINAL TEXTURE CREATED BY THE >>> GAME ENGINE <<< THIS IS NOT THE SOURCE FILE SIZE OF THE TEXUTRE AFTER ITS BEEN EXPORTED TO PNG/TGA/ETC BY PHOTOSHOP/TEXTURE EDITOR OF CHOICE, AKA, THIS IS NOT THE SAME SIZE AS SEEN IN THE FILE EXPLORER!***  

IMPORTANT NOTES ABOUT VRAM & FILE SIZE:
- REDUCE TEXTURE SIZE, AS MUCH AS POSSIBLE IF THE QUALITY IS MAINTAINABLE! (This reduces VRAM usage extremely important!)
- USE COMPRESSION IF THE ARTIFICATING IS MINIMAL AND IS OKAY! (This reduces file size)

<ul>
  <b>Compression Types starting from highest compressions to lowest/no compression!</b>
    <ol type="1">
      <li>DXT1 : Strongest compression & only uses RGB Texture Channels</li>
      <li>DXT5 : Maximum compression but uses all RGBA Texture Channels</li>
      <li>BC7 : Maximum compression but supports 3 (RGB) or 4 (RGBA) Texture Channels</li>
      <li>R : NO compression and supports 1 (R) Color Texture Channel</li>
      <li>RGB : NO compression and supports 3 (RGB) Color Texture Channel</li>
      <li>RGBA : NO compression and supports 4 (RGBA) Color Texture Channel</li>
    </ol>
  If you are still interested in sizes & optimizing VRAM via textures check this <a href="https://www.poiyomi.com/blog/2022-10-17-texture-optimization#:~:text=GPU%20texture%20formats%20almost%20always,what%20the%20texture%20data%20contains.">blog post on poiyomi's site</a> for VRChat (texture memory in that game is pretty important & most people are b.d when it comes to understanding vram in that game except the japanese community)
</ul>

---

# Important Shader notes or videos
I'm more of a visual learner so I prefer watching videos than reading garbage, so most resoures here will be in video format unless something in writing is insanely well explained.  
*The resources below are simply a reminder for myself but they are very useful in general as a refresher to some topics even*
- Ben Cloward explaining all input vectors nicely in shader graph! - https://www.youtube.com/watch?v=lrc-j7ub28U
- TBD

---
### Credits & Resources used to help me ❤️💚💙
- https://catlikecoding.com/ literally the holy bible for unity shader code
- https://roystan.net/articles/toon-water/ Roy helped a ton during university <3 
- https://ameye.dev/notes/stylized-water-shader/ Amazing stylized water blog
- https://www.youtube.com/@BenCloward for the shader graph enjoyers
- https://halisavakis.com/category/blog-posts/my-take-on-shaders/ An incredible blog with tons of amazing shaders!
