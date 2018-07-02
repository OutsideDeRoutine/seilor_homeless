/*
* Waves formulas from:
* "Seascape" by Alexander Alekseev aka TDM - 2014
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* From: https://www.shadertoy.com/view/Ms2SD1
*/
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

			float hash(float p)
			{
				float h = dot(p, float2(127.1, 311.7));
				return frac(sin(h)*43758.5453123);
			}

			float noise(in float2 p) {
				float2 i = floor(p);
				float2 f = frac(p);
				float2 u = f * f*(3.0 - 2.0*f);
				return -1.0 + 2.0*lerp(lerp(hash(i + float2(0.0, 0.0)),
					hash(i + float2(1.0, 0.0)), u.x),
					lerp(hash(i + float2(0.0, 1.0)),
					hash(i + float2(1.0, 1.0)), u.x), u.y);
			}

			//WAVE
			float sea_octave(float2 pos, float choppy) {
				pos += noise(pos);
				float2 wv = 1.0 - abs(sin(pos));
				float2 swv = abs(cos(pos));
				wv = lerp(wv, swv, wv);
				return pow(1.0 - pow(wv.x * wv.y , 0.65), choppy);
			}

			float3 waveMe(float4 p) {
				float x = p.x;
				float z = p.z;
				float freq = _WaveLength;
				float amp = _Amplitude;
				float choppy = _Steep;
				float2 uv = mul(unity_ObjectToWorld, p).xz; uv.x *= 0.75;

				float d, h = 0.0;
				d = sea_octave((uv + (1.0 + _Time * _Speed))*freq, choppy);
				d += sea_octave((uv - (1.0 + _Time * _Speed))*freq, choppy);
				h += d * amp;
				uv *= _Direction; freq *= 1.9; amp *= 0.22;

				return float3(x, p.y + h, z);
			}


			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(waveMe( v.vertex));
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
