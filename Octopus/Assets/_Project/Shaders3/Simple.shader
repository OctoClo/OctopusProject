Shader "Custom/Simple"
{
	Properties
	{
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Texture", 2D) = "white" {}
	}

		SubShader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "UnityCG.cginc"

			struct VertexData
			{
				float4 position : POSITION;
				float2 uv : TEXCOORD0;
			};
			
			struct VertexOutput
			{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			float4 _Tint;
			sampler2D _MainTex;
			float4 _MainTex_ST;

			VertexOutput MyVertexProgram(VertexData v)
			{
				VertexOutput o;
				o.position = UnityObjectToClipPos(v.position);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			float4 MyFragmentProgram(VertexOutput o) : SV_TARGET
			{
				return tex2D(_MainTex, o.uv) * _Tint;
			}

			ENDCG
		}
	}
}

