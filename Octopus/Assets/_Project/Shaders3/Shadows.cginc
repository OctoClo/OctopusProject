#if !defined(SHADOWS_INCLUDED)
#define SHADOWS_INCLUDED

#include "UnityCG.cginc"

struct VertexInput
{
    float4 position : POSITION;
    float3 normal : NORMAL;
};

#if defined(SHADOWS_CUBE)
    struct VertexOutput
    {
		float4 position : SV_POSITION;
		float3 lightVec : TEXCOORD0;
	};

	VertexOutput MyShadowVertexProgram (VertexInput v)
    {
        VertexOutput o;
		o.position = UnityObjectToClipPos(v.position);
		o.lightVec = mul(unity_ObjectToWorld, v.position).xyz - _LightPositionRange.xyz;
        return o;
    }

    float4 MyShadowFragmentProgram(VertexOutput o) : SV_TARGET
    {
		float depth = length(o.lightVec) + unity_LightShadowBias.x;
		depth *= _LightPositionRange.w;
		return UnityEncodeCubeShadowDepth(depth);
	}
#else
    float4 MyShadowVertexProgram(VertexInput v) : SV_POSITION
    {
        float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
        return UnityApplyLinearShadowBias(position);
    }

    half4 MyShadowFragmentProgram() : SV_TARGET
    {
        return 0;
    }
#endif

#endif