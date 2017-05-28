#version 410 core                                                              
#define M_PI 3.1415926535897932384626433832795
	                                                                               
uniform sampler2D tex;  
uniform int effect_mode;                                                       
	                                                                               
out vec4 color;                                                                
	                                                                               
in VS_OUT                                                                      
{                                                                              
	vec2 texcoord;                                                             
} fs_in;                                                                       
	                                                                               
void main(void)                                                                
{
	vec2 offset[9];      
	offset[0] = vec2(-1.0, -1.0);
	offset[1] = vec2(0.0, -1.0);
	offset[2] = vec2(1.0, -1.0);

	offset[3] = vec2(-1.0, 0.0);
	offset[4] = vec2(0.0, 0.0);
	offset[5] = vec2(1.0, 0.0);

	offset[6] = vec2(-1.0, 1.0);
	offset[7] = vec2(0.0, 1.0);
	offset[8] = vec2(1.0, 1.0);     
	if(effect_mode == 0){
		vec4 texture_color_Left = texture(tex, fs_in.texcoord - 0.005);		
		vec4 texture_color_Right = texture(tex, fs_in.texcoord + 0.005);		
		vec4 texture_color = vec4(texture_color_Left.x * 0.299 + texture_color_Left.y * 0.587 + texture_color_Left.z * 0.114, texture_color_Right.y, texture_color_Right.z, 1.0f); 
		color = texture_color;		
	}else if(effect_mode == 1){
		float pixels = 600.0;
		float dx = 15.0 * (1.0 / pixels);
		float dy = 15.0 * (1.0 / pixels);
		vec2 coord = vec2(dx * floor(fs_in.texcoord.x / dx), 
						  dy * floor(fs_in.texcoord.y / dy));
		color = texture(tex, coord);
	}else if(effect_mode == 2){
		/*float x = fs_in.texcoord.x;
		float y = fs_in.texcoord.y;
		float d = atan(sqrt(x*x + y*y), sqrt(10.0 - x*x - y*y)) / M_PI;
		float phi = atan(y, x);
		vec2 coord = vec2(d * cos(phi) + 0.5, d * sin(phi) + 0.5);*/
		
		float maxF = sin(0.5 * 178.0 * (M_PI / 180.0));
		vec2 xy = 2.0 * fs_in.texcoord.xy - 1.0;
		float d = length(xy);
		if(d < (2.0 - maxF)){
			float z = sqrt(1.0 - d*d);
			float r = atan(d, z) / M_PI;
			float phi = atan(xy.y, xy.x);
			float x = r * cos(phi) + 0.5;
			float y = r * sin(phi) + 0.5;
			vec2 coord = vec2(x, y);
			color = texture(tex, coord);
		}else{
			color = texture(tex, fs_in.texcoord.xy);
		}
		
		
	}else if(effect_mode == 3){
		float kernal[9] = float[](
			-1, -1, -1,
			-1, 9, -1,
			-1, -1, -1
		);
		int i = 0;
		vec4 sum = vec4(0.0);
		for(i = 0; i < 9; i++){
			vec2 tmp_coord;
			//tmp_coord.x = (fs_in.texcoord.x)
			vec4 tmp = texture(tex, fs_in.texcoord.xy + offset[i] / 600);
			sum += tmp * kernal[i];
		}
		color = vec4(sum.rgb, 1.0);
	}else if(effect_mode == 4){
		float kernal[9] = float[](
			-1, -1, -1,
			-1, 8, -1,
			-1, -1, -1
		);
		vec4 sum = vec4(0.0);
		int i = 0;
		for(i = 0; i < 9; i++){
			vec4 tmp = texture(tex, fs_in.texcoord.xy + offset[i] / 600);
			float grayscale = tmp.r * 0.299 + tmp.g * 0.587 + 
							  tmp.b * 0.114;
			vec4 gray = vec4(grayscale, grayscale, grayscale, 1.0);
			sum += gray * kernal[i];	
		}
		color = vec4(sum.rgb, 1.0);
	}else if(effect_mode == 5){
		float sigma_e = 2.0f;
		float sigma_r = 2.8f;
		float phi = 3.4f;
		float tau = 0.99f;
		float twoSigmaESquared = 2.0 * sigma_e * sigma_e;		
		float twoSigmaRSquared = 2.0 * sigma_r * sigma_r;		
		int halfWidth = int(ceil( 2.0 * sigma_r ));
		vec2 img_size = vec2(1024,768);
		int nbins = 8;
		///DoG
		vec2 sum = vec2(0.0);
		vec2 norm = vec2(0.0);
		int kernel_count = 0;
		for ( int i = -halfWidth; i <= halfWidth; ++i ) {
		for ( int j = -halfWidth; j <= halfWidth; ++j ) {
				float d = length(vec2(i,j));
				vec2 kernel = vec2( exp( -d * d / twoSigmaESquared ),
									exp( -d * d / twoSigmaRSquared ));
				vec4 c = texture(tex, fs_in.texcoord + vec2(i,j) / img_size);
				vec2 L = vec2(0.299 * c.r + 0.587 * c.g + 0.114 * c.b);
													
				norm += 2.0 * kernel;
				sum += kernel * L;
			}
		}
		sum /= norm;
		float H = 100.0 * (sum.x - tau * sum.y);
		float edge = ( H > 0.0 )? 1.0 : 2.0 * smoothstep(-2.0, 2.0, phi * H );
		vec4 DoG_color = vec4(edge,edge,edge,1.0 );
		
		///quantization
		vec4 texture_color = texture(tex,fs_in.texcoord);
		float r = floor(texture_color.r * float(nbins)) / float(nbins);
		float g = floor(texture_color.g * float(nbins)) / float(nbins);
		float b = floor(texture_color.b * float(nbins)) / float(nbins); 
		vec4 quantization_color = vec4(r,g,b,texture_color.a);
		
		///blur
		color = vec4(0);	
		int n = 0;
		int half_size = 3;
		for ( int i = -half_size; i <= half_size; ++i ) {       
			for ( int j = -half_size; j <= half_size; ++j ) {
				vec4 c = texture(tex, fs_in.texcoord + vec2(i,j)/img_size);
				color+= c;
				n++;
			}
		}
		vec4 blur_color = color / n;
		color = (blur_color + quantization_color) / 2.0 * DoG_color;
	}else{
		color = texture(tex, fs_in.texcoord);
	}                                                                
		
}                           