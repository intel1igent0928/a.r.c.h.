## Pixel-art post-processing shader для Voxel Builder.
## Применяется на SubViewportContainer — пиксилирует весь экран.
## 
## Параметры:
##   pixel_size  — размер одного "пикселя" (4.0 = экран 480p → пиксельный вид)
##   outline_str — сила чёрного контура (0.0 = нет, 1.0 = максимум)
##   vignette    — затемнение краёв экрана (атмосфера dungeon)
shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float pixel_size    : hint_range(1.0, 8.0, 0.5) = 4.0;
uniform float outline_str   : hint_range(0.0, 1.0, 0.05) = 0.5;
uniform float vignette      : hint_range(0.0, 1.5, 0.05) = 0.8;
uniform float saturation    : hint_range(0.0, 2.0, 0.05) = 1.0;
uniform float contrast      : hint_range(0.5, 2.0, 0.05) = 1.25;
uniform float color_depth   : hint_range(2.0, 32.0, 1.0) = 8.0;

// Конвертируем RGB в YUV для изменения насыщенности
vec3 adjust_saturation(vec3 color, float sat) {
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	return mix(vec3(gray), color, sat);
}

void fragment() {
	// 1. Пиксилизация — квантование UV по сетке
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 pixel_grid  = screen_size / pixel_size;
	vec2 quantized_uv = floor(UV * pixel_grid) / pixel_grid;
	
	vec3 col = texture(SCREEN_TEXTURE, quantized_uv).rgb;
	
	// 1.5. Постеризация (ретро-палитра с малым количеством цветов)
	col = floor(col * color_depth + 0.5) / color_depth;
	
	// 2. Outline detection (Sobel) — комиксный контур
	if (outline_str > 0.01) {
		float px = pixel_size / screen_size.x;
		float py = pixel_size / screen_size.y;
		
		vec3 s00 = texture(SCREEN_TEXTURE, quantized_uv + vec2(-px, -py)).rgb;
		vec3 s10 = texture(SCREEN_TEXTURE, quantized_uv + vec2(  0, -py)).rgb;
		vec3 s20 = texture(SCREEN_TEXTURE, quantized_uv + vec2( px, -py)).rgb;
		vec3 s01 = texture(SCREEN_TEXTURE, quantized_uv + vec2(-px,   0)).rgb;
		vec3 s21 = texture(SCREEN_TEXTURE, quantized_uv + vec2( px,   0)).rgb;
		vec3 s02 = texture(SCREEN_TEXTURE, quantized_uv + vec2(-px,  py)).rgb;
		vec3 s12 = texture(SCREEN_TEXTURE, quantized_uv + vec2(  0,  py)).rgb;
		vec3 s22 = texture(SCREEN_TEXTURE, quantized_uv + vec2( px,  py)).rgb;
		
		// Для контура также применяем постеризацию, чтобы он был жёстче
		s00 = floor(s00 * color_depth + 0.5) / color_depth;
		s10 = floor(s10 * color_depth + 0.5) / color_depth;
		s20 = floor(s20 * color_depth + 0.5) / color_depth;
		s01 = floor(s01 * color_depth + 0.5) / color_depth;
		s21 = floor(s21 * color_depth + 0.5) / color_depth;
		s02 = floor(s02 * color_depth + 0.5) / color_depth;
		s12 = floor(s12 * color_depth + 0.5) / color_depth;
		s22 = floor(s22 * color_depth + 0.5) / color_depth;
		
		vec3 gx = -s00 - 2.0*s01 - s02 + s20 + 2.0*s21 + s22;
		vec3 gy = -s00 - 2.0*s10 - s20 + s02 + 2.0*s12 + s22;
		float edge = length(gx) + length(gy);
		// Жёсткий ступенчатый контур
		edge = step(0.3, edge);
		
		col = mix(col, vec3(0.0), edge * outline_str);
	}
	
	// 3. Контраст
	col = ((col - 0.5) * contrast) + 0.5;
	col = clamp(col, 0.0, 1.0);
	
	// 4. Насыщенность
	col = adjust_saturation(col, saturation);
	
	// 5. Виньетка (тёмные края — атмосфера подземелья)
	if (vignette > 0.01) {
		vec2 uv_c  = UV * 2.0 - 1.0;
		float vig  = 1.0 - dot(uv_c, uv_c) * vignette;
		vig = clamp(vig, 0.0, 1.0);
		col *= vig;
	}
	
	// 6. Лёгкая тёплая тонировка (dungeon amber)
	col.r *= 1.04;
	col.b *= 0.88;
	
	COLOR = vec4(col, 1.0);
}
