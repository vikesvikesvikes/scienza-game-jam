shader_type canvas_item;

const float segment_count = 50.0;
const float columns_count = 512.0; // Sincronizado dinamicamente com as 256 colunas de tempo

uniform sampler2D sonogram_tex : filter_nearest;
uniform vec3 paper_color = vec3(0.92, 0.89, 0.83); // Cor base do papel amarelado

void fragment() {
    vec2 uv = UV;
    
    // Aumentamos a amostragem vertical para suavizar a linha
    float high_res_segments = 256.0; 
    vec2 pos = vec2(
        floor(uv.x * columns_count) / columns_count, 
        floor(uv.y * high_res_segments) / high_res_segments
    );
    
    // Lê a textura gerada pelo script
    float fft = texture(sonogram_tex, pos).r;
    vec3 color = vec3(1.0, 0.45, 0.0); // Laranja Forte
       
    // Se houver qualquer registro de som (> 0.01), ativa com força máxima (1.0)
    // Isso garante que a linha seja sempre opaca e forte, ignorando a oscilação de volume
    float mask = fft > 0.25 ? 1.0 : 0.0; 
    
    // Linhas do caderno (fundo)
    vec2 dist = fract((uv - pos) * vec2(columns_count, high_res_segments)) - 0.5;
    float grid_lines = smoothstep(0.44, 0.48, abs(dist.x)) + smoothstep(0.44, 0.48, abs(dist.y));
    vec3 grid_color = vec3(0.75, 0.78, 0.85); 
    
    vec3 background = mix(paper_color, grid_color, clamp(grid_lines, 0.0, 0.12));
    
    // Renderiza a linha laranja pura se houver som na coordenada, sem degradê de LED
    vec3 final_rgb = mix(background, color, mask);
    COLOR = vec4(final_rgb, 1.0);
}