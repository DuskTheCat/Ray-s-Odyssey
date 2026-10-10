shader_type canvas_item;
render_mode blend_mix, unshaded;

// Fire properties
uniform vec2 fire_scale = vec2(1.0, 1.0);
uniform vec2 fire_speed_direction = vec2(0.0, 1.0);
uniform float intensity_multiplier : hint_range(0.0, 10.0) = 1.0;

// Glow & Toon controls
uniform float glow_intensity : hint_range(0.0, 10.0) = 2.0;
uniform bool enable_toon = true;
uniform int toon_levels : hint_range(1, 10) = 3;
uniform float toon_cutoff : hint_range(0.0, 1.0) = 0.1;

// Desired color to completely replace the fire gradient texture
uniform vec4 desired_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);

// Fire texture maps
uniform sampler2D fire_noise : source_color, repeat_enable;
uniform sampler2D fire_height_gradient : source_color;
uniform sampler2D fire_shape_gradient : source_color;
uniform sampler2D flame_height_gradient : source_color;

void fragment() {
	// Scale UV coordinates based on fire_scale
	vec2 scaled_uv = (UV - vec2(0.0)) * fire_scale + vec2(0.0);

	// Animate fire movement using TIME and speed direction
	vec3 time_offset = vec3(TIME) * vec3(fire_speed_direction, 0.0);
	vec2 animated_uv = time_offset.xy + scaled_uv;

	// Sample noise texture to create fire flickering effect
	vec4 noise_tex = texture(fire_noise, animated_uv);
	float noise_value = noise_tex.r;

	// Sample fire height gradient to control fire elevation
	vec4 height_tex = texture(fire_height_gradient, UV);
	float height_value = height_tex.r;

	// Combine noise and height for flame dynamics
	float combined_value = noise_value + height_value;

	// Sample fire shape gradient to define fire boundaries
	vec4 shape_tex = texture(fire_shape_gradient, UV);
	float shape_value = shape_tex.r;

	// Apply shape influence to fire dynamics
	float shaped_fire = combined_value * shape_value;

	// Sample flame height gradient to modify fire height
	vec4 flame_height_tex = texture(flame_height_gradient, UV);
	float flame_height_value = flame_height_tex.r;

	// Final fire intensity calculation scaled by the uniform
	float fire_intensity = (shaped_fire - flame_height_value) * intensity_multiplier;

	// Clamp fire intensity between 0 and 1
	fire_intensity = clamp(fire_intensity, 0.0, 1.0);

	// --- TOON SHADING LOGIC ---
	if (enable_toon) {
		// Cut off anything below the threshold to keep sharp flame edges
		if (fire_intensity < toon_cutoff) {
			fire_intensity = 0.0;
		} else {
			// Quantize/band the continuous intensity into discrete steps
			float float_levels = float(toon_levels);
			fire_intensity = floor(fire_intensity * float_levels) / float_levels;
		}
	}

	// Apply the desired color, fire intensity, and glow multiplier
	vec3 final_rgb = desired_color.rgb * fire_intensity * glow_intensity;
	float final_alpha = desired_color.a * fire_intensity;

	COLOR.rgb = final_rgb * COLOR.rgb;
	COLOR.a = final_alpha * COLOR.a;
}