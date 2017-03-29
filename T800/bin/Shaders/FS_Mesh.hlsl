 
cbuffer ConstantBuffer{
    float4x4 WVP;
	float4x4 World;  
	float4	 LightPos;
	float4 	 LightColor;
	float4   CameraPosition;
	float4	 Ambient;
}

#define PHONG 1
#define BLINN 2

#define SPECULAR_MODEL BLINN


#if   SPECULAR_MODEL == PHONG
#define USING_PHONG
#elif SPECULAR_MODEL == BLINN
#define USING_BLINN
#endif


#define AMBIENT
#define DIFFUSE
#define SPECULAR
#define FRESNEL 
/*

#ifdef DIFFUSE_MAP
#undef DIFFUSE_MAP
#endif

#ifdef SPECULAR_MAP
#undef SPECULAR_MAP
#endif

#ifdef GLOSS_MAP
#undef GLOSS_MAP
#endif 

#ifdef NORMAL_MAP
#undef NORMAL_MAP
#endif

*/

Texture2D TextureRGB : register(t0);

#ifdef SPECULAR_MAP
Texture2D TextureSpecular : register(t1);
#endif

#ifdef GLOSS_MAP
Texture2D TextureGloss : register(t2);
#endif

#ifdef NORMAL_MAP
Texture2D TextureNormal : register(t3);
#endif

SamplerState SS;

struct VS_OUTPUT{
    float4 hposition : SV_POSITION;
	
#ifdef USE_NORMALS
	float4 hnormal   : NORMAL;
#endif

#ifdef USE_TANGENTS
	float4 htangent   : TANGENT;
#endif

#ifdef USE_BINORMALS
	float4 hbinormal : BINORMAL;
#endif

#ifdef USE_TEXCOORD0
    float2 texture0  : TEXCOORD;
#endif
	
	float4 wPos		: TEXCOORD1;
};

float4 FS( VS_OUTPUT input ) : SV_TARGET  {
    float4  color = float4(0.5,0.5,0.5,1.0);
	float4  Final = float4(0.0,0.0,0.0,1.0);
#ifdef USE_TEXCOORD0
	#ifdef NO_LIGHT
		color = TextureRGB.Sample( SS, input.texture0 );	
	#else
		#ifdef DIFFUSE_MAP
		color = TextureRGB.Sample( SS, input.texture0 );	
		#endif
		
		#ifdef SPECULAR_MAP
		float4 specularmap = TextureSpecular.Sample( SS, input.texture0 );	
		#endif
		
		#ifdef USE_NORMALS

		float4 Ambiental = color*Ambient;
		
		float4  Lambert  = LightColor;
		float4  Specular = LightColor;
		float4  Fresnel	 = LightColor;
		float3	LightDir = normalize(LightPos-input.wPos).xyz;
		float3  EyeDir   = normalize(CameraPosition-input.wPos).xyz;
		float3	normal   = normalize(input.hnormal).xyz;  
		float   att		 = 1.0;
		
		#ifdef NORMAL_MAP	
			float3 normalTex = TextureNormal.Sample( SS, input.texture0 ).xyz;
			normalTex 		 = 	normalTex*float3(2.0,2.0,2.0) - float3(1.0,1.0,1.0);
			normalTex		 = normalize(normalTex);
			normalTex.g 	 = -normalTex.g;
			float3 tangent	 = normalize(input.htangent).xyz;
			float3 binormal	 = normalize(input.hbinormal).xyz;
			float3x3	TBN  =  float3x3(tangent,binormal,normal);
			normal			 = mul(normalTex,TBN);
			normal			 = normalize(normal);
		#endif
		
		#ifdef DIFFUSE
			att		 	     = dot(normal,LightDir)*0.5 + 0.5;
			att				 = pow( att , 2.0 );	
			att				 = clamp( att , 0.0 , 1.0 );
			Lambert			*= color*att;
		#endif
		
		#ifdef SPECULAR
			float  specular  = 0.0;
			float specIntesivity = 0.8;
			float shinness = 8.0;

			#ifdef GLOSS_MAP
				shinness = TextureGloss.Sample( SS, input.texture0 ).r + shinness;
			#endif
			
		#ifdef USING_PHONG
			float3 	ReflectedLight = reflect(-LightDir,normal);
			//specular = max ( dot(ReflectedLight,EyeDir), 0.0);	
			specular = dot(ReflectedLight,EyeDir)*0.5 + 0.5;	
			specular = pow( specular ,shinness);		
		#elif defined(USING_BLINN)
			float3 ReflectedLight = normalize(EyeDir+LightDir); 
			specular = max ( dot(ReflectedLight,normal)*0.5 + 0.5, 0.0);	
			specular = pow( specular ,shinness);	
		#endif

			specular *= att;
			specular *= specIntesivity;
			Specular *= specular;
			
			#ifdef SPECULAR_MAP
				Specular.xyz *= specularmap.xyz;
			#endif		
		#endif
		
		
	#ifdef FRESNEL
		float  FresnelAtt	= dot(normal,EyeDir);
		float  FresnelIntensity = 1.0f;
		#ifdef SPECULAR_MAP
			float4 FresnelCol = float4(specularmap.xyz,1.0);
		#else
			float4 FresnelCol = float4(1.0,1.0,1.0,1.0);	
		#endif
		FresnelAtt			= abs(FresnelAtt);
		FresnelAtt 		= 1.0 - FresnelAtt;
		FresnelAtt 		= clamp( FresnelAtt , 0.0 , 1.0 );
		FresnelAtt			= pow( FresnelAtt , 4.0 );	
		FresnelAtt 		= clamp(FresnelAtt , 0.0 , 1.0 );
		Fresnel 		= FresnelCol*FresnelIntensity*FresnelAtt; 
	#endif
		
		#ifdef AMBIENT
			Final += Ambiental;
		#endif
		
		#ifdef DIFFUSE
			Final += Lambert;
		#endif
		
		#ifdef SPECULAR
			Final += Specular;
		#endif
		
		#ifdef SPECULAR
			Final += Specular;
		#endif
		
		#ifdef FRESNEL
			Final += Fresnel;
		#endif
		
		color = Final;
		#endif
	#endif
#endif		
	
    return color;
}