shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, wireframe;


uniform vec4 wireframe_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);

uniform float shake_power = 0.02;
uniform float shake_rate : hint_range(0.0, 1.0) = 0.5;
uniform float shake_speed = 5.0;
uniform float shake_block_size = 25.0;

uniform bool spin_enabled = false;
uniform float spin_speed = 1.0;
uniform int spin_axis : hint_enum("X,Y,Z") = 1;

uniform bool wobble_enabled = false;
uniform float wobble_amount = 0.03;
uniform float wobble_speed = 2.0;


varying float g_enable;


float n1(float x) {
    return fract(sin(x * 91.32) * 43758.5453);
}

mat3 rotationX(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(
        vec3(1.0, 0.0, 0.0),
        vec3(0.0,    c,    s),
        vec3(0.0,   -s,    c)
    );
}

mat3 rotationY(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(
        vec3(   c, 0.0,  -s),
        vec3( 0.0, 1.0, 0.0),
        vec3(   s, 0.0,   c)
    );
}

mat3 rotationZ(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat3(
        vec3(   c,   s, 0.0),
        vec3(  -s,   c, 0.0),
        vec3( 0.0, 0.0, 1.0)
    );
}

void vertex() {
    float t = mod(TIME, 5.0);

    // Spin
    if (spin_enabled) {
        float tspin = TIME * spin_speed;

        mat3 rot = rotationX(tspin) * float(spin_axis == 0) +
                   rotationY(tspin) * float(spin_axis == 1) +
                   rotationZ(tspin) * float(spin_axis == 2);

        VERTEX = rot * VERTEX;
    }

    // Wobble
    if (wobble_enabled) {
        float wob = sin(TIME * wobble_speed) * wobble_amount * 0.05;
        VERTEX += vec3(0.0, wob, 0.0);
    }

    // Shake
    float flicker = n1(floor(t * shake_speed));
    g_enable = float(flicker < shake_rate);

    float block = floor(VERTEX.y * shake_block_size) / shake_block_size;
    float shift = (n1(block + t) - 0.5) * shake_power * g_enable;
    VERTEX.x += shift * 0.25;
}

void fragment() {
    float t = mod(TIME, 5.0);
    float block = floor(UV.y * shake_block_size) / shake_block_size;
    float shift = (n1(block + t) - 0.5) * shake_power * g_enable;

    vec3 col = wireframe_color.rgb;
    ALBEDO = mix(col, col * 1.1, g_enable);
}
