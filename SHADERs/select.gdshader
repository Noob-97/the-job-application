shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_disabled, specular_disabled;

// === BILLBOARDING ===
uniform vec3 billboard;

void vertex() {
    vec3 billboard_offset = VERTEX - billboard;
    VERTEX.xz = normalize(INV_VIEW_MATRIX[0].xz) * billboard_offset.x + normalize(INV_VIEW_MATRIX[2].xz) * billboard_offset.z;
    VERTEX.y = billboard_offset.y;
}

// === GLOW / OUTLINE ===
uniform sampler2D sprite_texture : source_color, filter_linear;

uniform vec4 line_color : source_color = vec4(1.0,1.0,1.0,1.0); // Glow color
uniform float glowSize : hint_range(0.0, 300) = 15.0;
uniform int glowDensity : hint_range(0, 30) = 3;
uniform int glowRadialCoverage : hint_range(0, 32) = 4;
uniform float glowAngle : hint_range(0.0, 6.28) = 1.57;
uniform float glowSharpness : hint_range(0.0, 5.0) = 1.0;
uniform float alphaThreshold : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    vec4 col = texture(sprite_texture, UV);

    ALBEDO = col.rgb;
    ALPHA = col.a;

    vec2 pixel_size = 1.0 / vec2(textureSize(sprite_texture, 0));
    float alph = 0.0;

    for (int i = 0; i < glowRadialCoverage; i++) {
        for (int j = 0; j < glowDensity; j++) {
            float radians360 = 6.283185;
            float angle = (radians360 / float(glowRadialCoverage)) * float(i + 1) + glowAngle;
            float dist = glowSize * float(j + 1) / float(glowDensity);
            vec2 pixel_coor = vec2(sin(angle), cos(angle));
            vec4 tex = texture(sprite_texture, UV + pixel_coor * pixel_size * dist);

            float distFrom = float(glowDensity - j) / float(glowDensity);
            float sharpness = mix(0.0, 1.0, pow(distFrom, glowSharpness));
            alph += (tex.a * line_color.a) * sharpness;
        }
    }

    if (ALPHA < alphaThreshold) {
        ALBEDO = line_color.rgb;
        ALPHA = alph;
    }
}
