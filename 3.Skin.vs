// Here is the PER-VERTEX data -- we use 16 vectors, 
// the maximum permitted by our graphics API 
struct a2vConnector 
{   
    float4 coord;                // 3D location     
    float4 normal;   
    float4 tangent;   
    float3 coordMorph0;          // 3D offset to target 0    
    float4 normalMorph0;         // matching offset     
    float3 coordMorph1;          // 3D offset to target 1     
    float4 normalMorph1;         // matching offset     
    float3 coordMorph2;          // 3D offset to target 2    
    float4 normalMorph2;         // matching offset     
    float3 coordMorph3;          // 3D offset to target 3     
    float4 normalMorph3;         // matching offset     
    float3 coordMorph4;          // 3D offset to target 4     
    float4 normalMorph4;         // matching offset     
    float4 boneWeight0_3;        // skull and neck bone     
    float4 boneIndex0_3;         // indices and weights     
    float4 skinColor_frontSpec;  // UV indices 
}; 

// Here is the data passed from the vertex shader 
// to the fragment shader 
struct v2fConnector 
{   
    float4 HPOS              : POSITION;   
    float4 SkinUVST          : TEXCOORD0;   
    float3 WorldEyeDir       : TEXCOORD2;   
    float4 SkinSilhouetteVec : TEXCOORD3;   
    float3 WorldTanMatrixX   : TEXCOORD5;   
    float3 WorldTanMatrixY   : TEXCOORD6;   
    float3 WorldTanMatrixZ   : TEXCOORD7; 
}; 

OUT.SkinSilhouetteVec = float4(objectNormal.w,                                
                        oneMinusVdotN * oneMinusVdotN,                                
                        oneMinusVdotN,                                
                        vecMul(G_DappleXf, worldNormal.xyz).z); 


// Helper function: 
// vecMul(matrix, float3) multiplies like a vector 
// instead of like a point (no translate) 
float3 vecMul(const float4x4 matrix, const float3 vec) 
{   
    return(float3(dot(vec, matrix._11_12_13),                 
            dot(vec, matrix._21_22_23),                 
            dot(vec, matrix._31_32_33))); 
} 
// The Vertex Shader for Dawn's Face 
v2fConnector faceVertexShader(a2vConnector IN,   
                        const uniform float MorphWeight0,   
                        const uniform float MorphWeight1,   
                        const uniform float MorphWeight2,   
                        const uniform float MorphWeight3,   
                        const uniform float MorphWeight4,   
                        const uniform float4x4 BoneXf[8],   
                        const uniform float4   GlobalCamPos,   
                        const uniform float4x4 ViewXf,   
                        const uniform float4x4 G_DappleXf,   
                        const uniform float4x4 ProjXf) 
{   
    v2fConnector OUT; 
    // The following large block is entirely     
    // concerned with shape skinning.     
    // First, do shape blending between the five     
    // blend shapes ("morph targets")

    float4 objectCoord = IN.coord;   
    objectCoord.xyz += (MorphWeight0 * IN.coordMorph0);   
    objectCoord.xyz += (MorphWeight1 * IN.coordMorph1);   
    objectCoord.xyz += (MorphWeight2 * IN.coordMorph2);   
    objectCoord.xyz += (MorphWeight3 * IN.coordMorph3);   
    objectCoord.xyz += (MorphWeight4 * IN.coordMorph4); 

    // Now transform the entire head by the neck bone     
    float4 worldCoord = IN.boneWeight0_3.x * 
            mul(BoneXf[IN.boneIndex0_3.x], objectCoord);  
    worldCoord += (IN.boneWeight0_3.y *                   
            mul(BoneXf[IN.boneIndex0_3.y], objectCoord));   
    worldCoord += (IN.boneWeight0_3.z * 
            mul(BoneXf[IN.boneIndex0_3.z], objectCoord));   
    worldCoord += (IN.boneWeight0_3.w *
            mul(BoneXf[IN.boneIndex0_3.w], objectCoord)); 

    // Repeat the previous skinning ops     
    // on the surface normal     
    float4 objectNormal = IN.normal;   
    objectNormal += (MorphWeight0 * IN.normalMorph0);  
    objectNormal += (MorphWeight1 * IN.normalMorph1);   
    objectNormal += (MorphWeight2 * IN.normalMorph2);   
    objectNormal += (MorphWeight3 * IN.normalMorph3);   
    objectNormal += (MorphWeight4 * IN.normalMorph4);   
    objectNormal.xyz = normalize(objectNormal.xyz);   
    float3 worldNormal = IN.boneWeight0_3.x * vecMul(BoneXf[IN.boneIndex0_3.x],objectNormal.xyz));   
    worldNormal += (IN.boneWeight0_3.y * vecMul(BoneXf[IN.boneIndex0_3.y],objectNormal.xyz));   
    worldNormal += (IN.boneWeight0_3.z * vecMul(BoneXf[IN.boneIndex0_3.z],objectNormal.xyz));   
    worldNormal += (IN.boneWeight0_3.w * vecMul(BoneXf[IN.boneIndex0_3.w],objectNormal.xyz));   
    worldNormal = normalize(worldNormal); 

    // Repeat the previous skinning ops     
    // on the orthonormalized surface tangent vector     
    float4 objectTangent = IN.tangent;   
    objectTangent.xyz = normalize(objectTangent.xyz - dot(objectTangent.xyz, objectNormal.xyz) *objectNormal.xyz);   
    float4 worldTangent;   
    worldTangent.xyz = IN.boneWeight0_3.x * vecMul(BoneXf[IN.boneIndex0_3.x], objectTangent.xyz);   
    worldTangent.xyz += (IN.boneWeight0_3.y * vecMul(BoneXf[IN.boneIndex0_3.y], objectTangent.xyz));   
    worldTangent.xyz += (IN.boneWeight0_3.z * vecMul(BoneXf[IN.boneIndex0_3.z], objectTangent.xyz));   
    worldTangent.xyz += (IN.boneWeight0_3.w * vecMul(BoneXf[IN.boneIndex0_3.w], objectTangent.xyz));   
    worldTangent.xyz = normalize(worldTangent.xyz);   
    worldTangent.w = objectTangent.w; 

    // Now our deformations are done.     
    // Create a binormal vector as the cross product     
    // of the normal and tangent vectors     
    float3 worldBinormal = worldTangent.w * normalize(cross(worldNormal, worldTangent.xyz));   
    // Reorder these values for output as a 3 x 3 matrix     
    // for bump mapping in the fragment shader   
    OUT.WorldTanMatrixX = float3(worldTangent.x,worldBinormal.x, worldNormal.x);   
    OUT.WorldTanMatrixY = float3(worldTangent.y,worldBinormal.y, worldNormal.y);   
    OUT.WorldTanMatrixZ = float3(worldTangent.z,worldBinormal.z, worldNormal.z);
 
    // The vectors are complete. Now use them     
    // to calculate some lighting values     
    float4 worldEyePos = GlobalCamPos;   
    OUT.WorldEyeDir = normalize(worldCoord.xyz - worldEyePos.xyz);   
    float4 eyespaceEyePos = {0.0f, 0.0f, 0.0f, 1.0f};   
    float4 eyespaceCoord = mul(ViewXf, worldCoord);   
    float3 eyespaceEyeVec = normalize(eyespaceEyePos.xyz - eyespaceCoord.xyz);   
    float3 eyespaceNormal = vecMul(ViewXf, worldNormal);   
    float VdotN = abs(dot(eyespaceEyeVec, eyespaceNormal));   
    float oneMinusVdotN = 1.0 - VdotN;   
    OUT.SkinUVST = IN.skinColor_frontSpec;   
    OUT.SkinSilhouetteVec = float4(objectNormal.w, oneMinusVdotN * oneMinusVdotN, oneMinusVdotN,
            vecMul(G_DappleXf, worldNormal.xyz).z);   
    float4 hpos = mul(ProjXf, eyespaceCoord);   
    OUT.HPOS = hpos;   
    return OUT; 
}                         


float4 faceFragmentShader(v2fConnector IN,   
            uniform sampler2D SkinColorFrontSpecMap,   
            uniform sampler2D SkinNormSideSpecMap,   
            // xyz normal map     
            uniform sampler2D SpecularColorShiftMap, 
            // and spec map in "w"     
            uniform samplerCUBE DiffuseCubeMap,   
            uniform samplerCUBE SpecularCubeMap,  
            uniform samplerCUBE HilightCubeMap) : COLOR 
{   
    half4 normSideSpec tex2D(SkinNormSideSpecMap,IN.SkinUVST.xy);   
    half3 worldNormal;   
    worldNormal.x = dot(normSideSpec.xyz, IN.WorldTanMatrixX);   
    worldNormal.y = dot(normSideSpec.xyz, IN.WorldTanMatrixY);   
    worldNormal.z = dot(normSideSpec.xyz, IN.WorldTanMatrixZ);   
    fixed nDotV = dot(IN.WorldEyeDir, worldNormal); 

    half4 skinColor = tex2D(SkinColorFrontSpecMap, IN.SkinUVST.xy);   
    fixed3 diffuse = skinColor * texCUBE(DiffuseCubeMap, worldNormal);   
    diffuse = diffuse * IN.SkinSilhouetteVec.x;   

    fixed4 sideSpec = normSideSpec.w * texCUBE(SpecularCubeMap,worldNormal);   
    fixed3 result = diffuse * IN.SkinSilhouetteVec.y + sideSpec;   
    fixed3 hilite = 0.7 * IN.SkinSilhouetteVec.x *IN.SkinSilhouetteVec.y *texCUBE(HilightCubeMap, IN.WorldEyeDir);   
    fixed reflVect = IN.WorldEyeDir * nDotV - (worldNormal * 2.0x);   
    fixed4 reflColor = IN.SkinSilhouetteVec.w *texCUBE(SpecularCubeMap, reflVect);   
    result += (reflColor.xyz * 0.02);   

    fixed hiLightAttenuator = tex2D(SpecularColorShiftMap,IN.SkinUVST.xy).x;   
    result += (hilite * hiLightAttenuator);   
    fixed haze = reflColor.w * hiLightAttenuator;   
    return float4(result.xyz, haze); 
} 