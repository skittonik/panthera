#version 140

in mediump vec2 var_texcoord0;
in mediump vec4 var_color0;

uniform lowp sampler2D texture_sampler;

uniform fs_uniforms
{
    lowp vec4 tint;
    lowp vec4 flash;
};

out vec4 out_fragColor;

void main()
{
    lowp vec4 color_pm = vec4(var_color0.xyz * var_color0.w, var_color0.w);
    lowp vec4 tex = texture(texture_sampler, var_texcoord0.xy) * tint * color_pm;
    // flash.x = 1.0 → full white silhouette, 0.0 → normal
    tex.rgb = mix(tex.rgb, vec3(tex.a), flash.x);
    if (tex.a < 0.01) discard;
    out_fragColor = tex;
}
