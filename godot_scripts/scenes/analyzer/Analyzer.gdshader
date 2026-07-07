shader_type canvas_item;

const float segment_count = 40.0;
const float columns_count = 256.0; // Sincronizado dinamicamente com as 256 colunas de tempo

uniform sampler2D sonogram_tex : filter_nearest;
uniform vec3 paper_color = vec3(0.92, 0.89, 0.83); // Cor base do papel amarelado

void fragment() {
    vec2 uv = UV;
    
    // Cria o quadriculado pixelado/grade baseado no tempo (X) e segmentos (Y)
    vec2 pos = vec2(
        floor(uv.x * columns_count) / columns_count, 
        floor(uv.y * segment_count) / segment_count
    );
    
    // Lê a intensidade de frequência capturada no script para essa exata coordenada de tempo
    float fft = texture(sonogram_tex, pos).r;

	vec3 color = vec3(1.0, 0.45, 0.0);
       
    // Condição para acender os blocos
    float mask = fft > 0.05 ? fft : 0.0; // Mudado para 0.0 para que o fundo fique limpo nas áreas sem som
    
    // Renderiza o efeito individual de cada lâmpada/LED dentro da grade
    vec2 dist = fract((uv - pos) * vec2(columns_count, segment_count)) - 0.5;
    float led = smoothstep(0.5, 0.35, abs(dist.x)) * smoothstep(0.5, 0.35, abs(dist.y));
    
    // --- MUDANÇA PRINCIPAL AQUI ---
    // Cria as linhas do caderno (o quadriculado de fundo)
    float grid_lines = smoothstep(0.42, 0.46, abs(dist.x)) + smoothstep(0.42, 0.46, abs(dist.y));
    vec3 grid_color = vec3(0.75, 0.78, 0.85); // Tom azulado clássico de caderno quadriculado
    
    // Aplica a cor do grid sobre a cor do papel
    vec3 background = mix(paper_color, grid_color, clamp(grid_lines, 0.0, 0.15));
    
    // Se houver som (mask * led), desenha a tinta colorida, senão mantém o papel quadriculado
    vec3 final_rgb = mix(background, color, mask * led);
    
    COLOR = vec4(final_rgb, 1.0);
}