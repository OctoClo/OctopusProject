#if !defined(LIGHTING_INCLUDED)
#define LIGHTING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

float4 _Tint;
sampler2D _MainTex, _DetailTex;
float4 _MainTex_ST, _DetailTex_ST;

sampler2D _NormalMap, _DetailNormalMap;
float _BumpScale, _DetailBumpScale;

sampler2D _MetallicMap;
float _Metallic;
float _Smoothness;

sampler2D _EmissionMap;
float3 _Emission;

struct VertexInput
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};
			
struct VertexOutput
{
    float4 pos : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;

#if defined(BINORMAL_PER_FRAGMENT)
		float4 tangent : TEXCOORD2;
#else
    float3 tangent : TEXCOORD2;
    float3 binormal : TEXCOORD3;
#endif

    float3 worldPos : TEXCOORD4;

    SHADOW_COORDS(5)

#if defined(VERTEXLIGHT_ON)
	float3 vertexLightColor : TEXCOORD6;
#endif
};

float GetMetallic(VertexOutput o)
{
#if defined(_METALLIC_MAP)
	return tex2D(_MetallicMap, o.uv.xy).r;
#else
    return _Metallic;
#endif
}

float GetSmoothness(VertexOutput o)
{
    float smoothness = 1;
#if defined(_SMOOTHNESS_ALBEDO)
		smoothness = tex2D(_MainTex, o.uv.xy).a;
#elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
		smoothness = tex2D(_MetallicMap, o.uv.xy).a;
#endif
    return smoothness * _Smoothness;
}

float3 GetEmission(VertexOutput o)
{
#if defined(FORWARD_BASE_PASS)
    #if defined(_EMISSION_MAP)
		return tex2D(_EmissionMap, o.uv.xy) * _Emission;
    #else
		return _Emission;
    #endif
#else
    return 0;
#endif
}

void ComputeVertexLightColor(inout VertexOutput o)
{
#if defined(VERTEXLIGHT_ON)
    o.vertexLightColor = Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb,
		unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, o.worldPos, o.normal
	);
#endif
}

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign)
{
    return cross(normal, tangent.xyz) *	(binormalSign * unity_WorldTransformParams.w);
}

VertexOutput MyVertexProgram(VertexInput v)
{
    VertexOutput o;

    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.normal = UnityObjectToWorldNormal(v.normal);

#if defined(BINORMAL_PER_FRAGMENT)
	o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
#else
    o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
    o.binormal = CreateBinormal(o.normal, o.tangent, v.tangent.w);
#endif

    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);

    TRANSFER_SHADOW(o);

    ComputeVertexLightColor(o);

    return o;
}

float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax)
{
#if UNITY_SPECCUBE_BOX_PROJECTION
    UNITY_BRANCH
    if (cubemapPosition.w > 0)
    {
        float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
        float scalar = min(min(factors.x, factors.y), factors.z);
        direction = direction * scalar + (position - cubemapPosition);
    }
#endif
    return direction;
}

UnityLight CreateLight(VertexOutput o)
{
    UnityLight light;

#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
    light.dir = normalize(_WorldSpaceLightPos0.xyz - o.worldPos);
#else
    light.dir = _WorldSpaceLightPos0.xyz;
#endif

    UNITY_LIGHT_ATTENUATION(attenuation, o, o.worldPos);

    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(o.normal, light.dir);
    return light;
}

UnityIndirect CreateIndirectLight(VertexOutput o, float3 viewDir)
{
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = o.vertexLightColor;
#endif

#if defined(FORWARD_BASE_PASS)
	indirectLight.diffuse += max(0, ShadeSH9(float4(o.normal, 1)));
    float3 reflectionDir = reflect(-viewDir, o.normal);
    Unity_GlossyEnvironmentData envData;
	envData.roughness = 1 - GetSmoothness(o);

	envData.reflUVW = BoxProjection(
			reflectionDir, o.worldPos,
			unity_SpecCube0_ProbePosition,
			unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
	float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData);

    envData.reflUVW = BoxProjection(
			reflectionDir, o.worldPos,
			unity_SpecCube1_ProbePosition,
			unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);

    #if UNITY_SPECCUBE_BLENDING
        float interpolator = unity_SpecCube0_BoxMin.w;
	    UNITY_BRANCH
	    if (interpolator < 0.99999)
        {
	        float3 probe1 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0), unity_SpecCube0_HDR, envData);
	        indirectLight.specular = lerp(probe1, probe0, interpolator);
        }
        else 
        {
            indirectLight.specular = probe0;
        }
    #else
        indirectLight.specular = probe0;
    #endif
#endif

    return indirectLight;
}

void InitializeFragmentNormal(inout VertexOutput o)
{
    float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, o.uv.xy), _BumpScale);
    float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, o.uv.zw), _DetailBumpScale);
    float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);

#if defined(BINORMAL_PER_FRAGMENT)
		float3 binormal = CreateBinormal(o.normal, o.tangent.xyz, o.tangent.w);
#else
    float3 binormal = o.binormal;
#endif

    o.normal = normalize(
		tangentSpaceNormal.x * o.tangent +
		tangentSpaceNormal.y * binormal +
		tangentSpaceNormal.z * o.normal
	);
}

float4 MyFragmentProgram(VertexOutput o) : SV_TARGET
{
    InitializeFragmentNormal(o);
    
    float3 viewDir = normalize(_WorldSpaceCameraPos - o.worldPos);

    float3 albedo = tex2D(_MainTex, o.uv.xy).rgb * _Tint.rgb;
    albedo *= tex2D(_DetailTex, o.uv.zw) * unity_ColorSpaceDouble;

    float3 specularTint;
    float oneMinusReflectivity;
    albedo = DiffuseAndSpecularFromMetallic(albedo, GetMetallic(o), specularTint, oneMinusReflectivity);

    float4 color = UNITY_BRDF_PBS(albedo, specularTint, oneMinusReflectivity, GetSmoothness(o), o.normal, viewDir, CreateLight(o), CreateIndirectLight(o, viewDir));
    color.rgb += GetEmission(o);
    return color;
}

#endif