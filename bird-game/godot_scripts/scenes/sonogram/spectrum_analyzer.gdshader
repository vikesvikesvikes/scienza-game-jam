shader_type canvas_item;

// Número de bandas de frequência (deve bater com VU_COUNT no script GDScript)
const int VU_COUNT = 30;

// Array de energia por banda (0.0 – 1.0, escalado pelo script)
uniform float freq_data[30];

// Cores do gradiente (grave → médio → agudo)
uniform vec4 color_low  : source_color = vec4(0.05, 0.25, 0.70, 1.0);
uniform vec4 color_mid  : source_color = vec4(0.10, 0.85, 0.50, 1.0);
uniform vec4 color_high : source_color = vec4(0.90, 0.95, 0.20, 1.0);

// Opacidade geral do efeito
uniform float opacity : hint_range(0.0, 1.0) = 0.85;

// Suavidade da borda superior de cada barra
uniform float edge_softness : hint_range(0.001, 0.1) = 0.02;

void fragment() {
	// Qual banda de frequência este pixel representa
	int band = clamp(int(UV.x * float(VU_COUNT)), 0, VU_COUNT - 1);
	float bar_height = freq_data[band];

	// UV.y = 0 no topo, 1 na base; invertemos para que as barras cresçam de baixo
	float pixel_y = 1.0 - UV.y;

	// Recorte suave na borda superior da barra
	float alpha = smoothstep(bar_height, bar_height - edge_softness, pixel_y);

	// GLSL não permite 'return' em fragment() — usamos if/else
	if (alpha < 0.001) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		// Gradiente de cor: t vai de 0 (base) a 1 (topo da barra)
		float t = pixel_y / max(bar_height, 0.001);

		vec4 col;
		if (t < 0.5) {
			col = mix(color_low, color_mid, t * 2.0);
		} else {
			col = mix(color_mid, color_high, (t - 0.5) * 2.0);
		}

		// Brilho extra no topo da barra (peak highlight)
		float peak_glow = smoothstep(0.8, 1.0, t) * 0.6;
		col.rgb += vec3(peak_glow);

		// Linha de pico acima da barra (efeito clássico de VU meter)
		float peak_line = smoothstep(0.015, 0.0, abs(pixel_y - bar_height - 0.01));
		col.rgb = mix(col.rgb, vec3(1.0), peak_line * 0.9);

		COLOR = vec4(col.rgb, alpha * opacity);
	}
}
