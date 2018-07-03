// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*
* Waves formulas from:
* "Seascape" by Alexander Alekseev aka TDM - 2014
* License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
* From: https://www.shadertoy.com/view/Ms2SD1
*/
Shader "Custom/WaterMagic" {
	Properties {
		_Color ("SeaColor", Color) = (1,1,1,1)
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
			#include "UnityLightingCommon.cginc" // for _LightColor0

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			struct v2f
			{
				float3 worldPos : TEXCOORD0;
				half3 tspace0 : TEXCOORD1;
				half3 tspace1 : TEXCOORD2;
				half3 tspace2 : TEXCOORD3;
				float2 uv : TEXCOORD4;
				float4 pos : SV_POSITION;
				fixed4 diff : COLOR0; // diffuse lighting color
			};

			float4 _Color;
			float4 _BaseColor;
			float _Amplitude;
			float _WaveLength;
			float _Steep;
			float _Speed;
			float4 _Direction;
			float3 _Position;
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

			//https://docs.unity3d.com/es/current/Manual/SL-VertexFragmentShaderExamples.html

			v2f vert(float4 vertex : POSITION, float3 normal : NORMAL, float4 tangent : TANGENT, float2 uv : TEXCOORD0)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(waveMe(vertex));
				o.worldPos = mul(unity_ObjectToWorld, vertex).xyz;
				half3 wNormal = UnityObjectToWorldNormal(normal);
				half3 wTangent = UnityObjectToWorldDir(tangent.xyz);
				half tangentSign = tangent.w * unity_WorldTransformParams.w;
				half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
				o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
				o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
				o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);
				o.uv = uv;
				half nl = max(0, dot(wNormal, _WorldSpaceLightPos0.xyz));
				o.diff = nl * _LightColor0;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{

				half3 worldNormal;
				worldNormal.x = i.tspace0;
				worldNormal.y = i.tspace1;
				worldNormal.z = i.tspace2;
				half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				half3 worldRefl = reflect(-worldViewDir, worldNormal);
				half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, -worldRefl);
				half3 skyColor = DecodeHDR(skyData, unity_SpecCube0_HDR);
				fixed4 c = 0;
				c.rgb = skyColor;
				c.rgb *= _Color;
				c.rgb *= i.diff;;
				return c;
			}
		ENDCG
		}
		
	}
	FallBack "Diffuse"
}
