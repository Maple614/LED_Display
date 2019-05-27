Shader "Custom/LED_Display"
{
	Properties
	{
		_BaseColor("Base Color", Color) = (0.0, 0.0, 0.0, 1.0)
		_BlendPower("Blend Power", Range(0.0, 1.0)) = 1.0

		_LEDTex("LED Texture", 2D) = "white" {}

		
		_MainTex ("Base map(RGBA)", 2D) = "white" {}
		_MainTex2 ("Base map2(RGBA)", 2D) = "white" {}

		_MainTex2_BlendPower("Map2 Blend", Range(0.0, 1.0)) = 1.0

		_LineBrightness("Line Brightness", Range(0.0, 1.0)) = 0.3
		_LineSpeed("Line Speed", Float) = 4
		_LineSpacing("Line Spacing", Float) = 4
		_LineSpacing("Line Spaceing2", Float) = 1

		_Near("Near", float) = 0.1
		_Far("Far", float) = 100.0
	}
		SubShader
		{
			Tags { "Queue" = "Geometry"}
			Blend Off
			Lighting Off
			Fog{ Mode Off}
			ZWrite On
			//Cull On

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				uniform float4 _BaseColor;
				uniform float _BlendPower;

				uniform sampler2D _LEDTex;
				
				uniform sampler2D _MainTex;
				uniform float4 _MainTex_TexelSize;

				uniform sampler2D _MainTex2;
				uniform float4 _MainTex2_TexelSize;

				uniform float _MainTex2_BlendPower;

				uniform float _LineBrightness;
				uniform float _LineSpeed;
				uniform float _LineSpacing;
				uniform float _LineSpacing2;

				uniform float _Near;
				uniform float _Far;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float2 celluv : TEXCOORD2;
				float depth : TEXCOORD3;
			};

			float4 _MainTex_ST;
			float4 _MainTex2_ST;
			float4 _CellTex3;
			float4 _LEDTex_ST;

			float4 col;
			float4 col_mt2;

			static const float2 _Texby1pt = float2(_MainTex_TexelSize.x, _MainTex_TexelSize.y);
			static const float2 _CellSizeXY = 1.0 / _LEDTex_ST.xy;
			
			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MV, v.vertex);
				o.depth = o.pos.z;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv2 = TRANSFORM_TEX(v.texcoord, _MainTex2);
				o.celluv = TRANSFORM_TEX(v.texcoord, _LEDTex);
				return o;
			}
			
			fixed4 frag (v2f i) : COLOR
			{
				//Pixelate for MainTex
				float2 steppedUV = i.uv.xy + _CellSizeXY * 0.5;
				steppedUV /= _CellSizeXY.xy;
				steppedUV = round(steppedUV);
				steppedUV *= _CellSizeXY.xy;
				col = tex2D(_MainTex, steppedUV);

				//Pixelate for MainTex2
				steppedUV = i.uv2.xy + _CellSizeXY * 0.5;
				steppedUV /= _CellSizeXY.xy;
				steppedUV = round(steppedUV);
				steppedUV *= _CellSizeXY.xy;
				col_mt2 = tex2D(_MainTex2, steppedUV);

				_MainTex2_BlendPower = sin(_Time.x);

				//Blend Texture Main and Main2
				col.rgb = lerp(col.rgb, col_mt2.rgb, _MainTex2_BlendPower);

				//Blend Base color and Texture
				col.rgb = lerp(_BaseColor.rgb, col.rgb, _BlendPower);

				//create LED flame
				float4 LED_col = tex2D(_LEDTex, i.celluv);

				//calc far distance
				float farPower = saturate((-i.depth - _Near) / (_Far - _Near));
				col.rgb = lerp(col.rgb, col.rgb*LED_col.rgb, (1 - farPower));


				//draw scanline uv standard
				float scanLineColor = sin(_Time.y * _LineSpeed + i.uv.y * _LineSpacing);
	
				//draw scanline uv standard
				float scanLineColor2 = sin(_Time.y * _LineSpeed*0.5 + i.uv.y * _LineSpacing*0.1);

				//draw side scanline uv standard
				float scanLineColor3 = sin(_Time.y * _LineSpeed*0.25 + i.uv.y * _LineSpacing2);

				//add scanline
				//col += (clamp(scanLineColor, 0, 1.0) + clamp(scanLineColor2, 0, 1.0) + clamp(scanLineColor3, 0, 1.0)) * (_LineBrightness * (1 - farPower)) * _BlendPower;

				return saturate(col);

			}
			ENDCG
		}
	}

	FallBack "Diffuse"
}
