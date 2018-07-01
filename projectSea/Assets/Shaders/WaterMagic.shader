// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/WaterMagic" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_WaveLength ("Wavelength", Float) = 1
		_Amplitude ("Amplitude", Float) = 1
		_Speed ("Speed", Float) = 1
		_Steep("Steep", Float) = 1
		_Direction("Direction", Vector) = (1,1,1,1)
	}
	SubShader {
		Tags{ "RenderType" = "Opaque" }
		LOD 100
		
		Pass{
		//WAVE MAKER
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			float4 _Color;
			float _Amplitude;
			float _WaveLength;
			float _Steep;
			float _Speed;
			float4 _Direction;
			
			//GERSTNER WAVE FORMULA (BROKEN)
			float3 waveMe(float3 pos) {
				float w = 2 * 3.14159265359 / _WaveLength;
				float o = _Speed * w;
				
				float x = pos.x + (_Steep*_Amplitude*dot(_Direction,pos.x)*cos(w*dot(_Direction, (pos.x, pos.y))+o*_Time));
				float y = pos.y + (_Steep*_Amplitude*dot(_Direction, pos.y)*cos(w*dot(_Direction, (pos.x, pos.y)) + o * _Time));
				float z = _Amplitude *sin(w*dot(_Direction, (pos.x,pos.y)) + o * _Time);

				return float3(x, y, pos.z);
			}

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(waveMe(mul(unity_ObjectToWorld, v.vertex).xyz));
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = _Color;
				return col;
			}
		ENDCG
		}
		
	}
	FallBack "Diffuse"
}
