//
//  SSTransitionFilter.m
//  SlideShow
//
//  Created by Arda Ozupek on 25.03.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSTransitionFilter.h"

NSString *const kSSTransitionFilterFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform float progress;
 uniform int type;
 uniform float ratio;
 
 vec4 getFromColor(vec2 uv) {
     return texture2D(inputImageTexture, uv);
 }
 
 vec4 getToColor(vec2 uv) {
     return texture2D(inputImageTexture2, uv);
 }
 
 vec4 directional(vec2 uv) {
     vec2 direction = vec2(0.0, 1.0);
     vec2 p = uv + progress * sign(direction);
     vec2 f = fract(p);
     return mix(
                getToColor(f),
                getFromColor(f),
                step(0.0, p.y) * step(p.y, 1.0) * step(0.0, p.x) * step(p.x, 1.0)
                );
 }
 
 vec2 simpleZoom_zoom(vec2 uv, float amount) {
     return 0.5 + ((uv - 0.5) * (1.0-amount));
 }
 
 vec4 simpleZoom (vec2 uv) {
     float zoom_quickness = 0.8;
     float nQuick = clamp(zoom_quickness,0.2,1.0);
     return mix(
                getFromColor(simpleZoom_zoom(uv, smoothstep(0.0, nQuick, progress))),
                getToColor(uv),
                smoothstep(nQuick-0.2, 1.0, progress)
                );
 }
 
 vec4 windowSlice (vec2 p) {
     float count = 10.0;
     float smoothness = 0.5;
     float pr = smoothstep(-smoothness, 0.0, p.x - progress * (1.0 + smoothness));
     float s = step(pr, fract(count * p.x));
     return mix(getFromColor(p), getToColor(p), s);
 }
 
 vec4 directionalWrap (vec2 uv) {
     vec2 direction = vec2(-1.0, 1.0);
     const float smoothness = 0.5;
     const vec2 center = vec2(0.5, 0.5);
     vec2 v = normalize(direction);
     v /= abs(v.x) + abs(v.y);
     float d = v.x * center.x + v.y * center.y;
     float m = 1.0 - smoothstep(-smoothness, 0.0, v.x * uv.x + v.y * uv.y - (d - 0.5 + progress * (1.0 + smoothness)));
     return mix(getFromColor((uv - 0.5) * (1.0 - m) + 0.5), getToColor((uv - 0.5) * m + 0.5), m);
 }
 
 vec4 morph(vec2 p) {
     float strength = 0.1;
     
     vec4 ca = getFromColor(p);
     vec4 cb = getToColor(p);
     
     vec2 oa = (((ca.rg+ca.b)*0.5)*2.0-1.0);
     vec2 ob = (((cb.rg+cb.b)*0.5)*2.0-1.0);
     vec2 oc = mix(oa,ob,0.5)*strength;
     
     float w0 = progress;
     float w1 = 1.0-w0;
     return mix(getFromColor(p+oc*w0), getToColor(p-oc*w1), progress);
 }
 
 vec4 linearBlur(vec2 uv) {
     float intensity = 0.1;
     const int passes = 6;
     
     vec4 c1 = vec4(0.0);
     vec4 c2 = vec4(0.0);
     
     float disp = intensity*(0.5-distance(0.5, progress));
     for (int xi=0; xi<passes; xi++)
     {
         float x = float(xi) / float(passes) - 0.5;
         for (int yi=0; yi<passes; yi++)
         {
             float y = float(yi) / float(passes) - 0.5;
             vec2 v = vec2(x,y);
             float d = disp;
             c1 += getFromColor( uv + d*v);
             c2 += getToColor( uv + d*v);
         }
     }
     c1 /= float(passes*passes);
     c2 /= float(passes*passes);
     return mix(c1, c2, progress);
 }
 
 vec4 waterDrop(vec2 p) {
     float amplitude = 30.0;
     float speed = 30.0;
     
     vec2 dir = p - vec2(.5);
     float dist = length(dir);
     
     if (dist > progress) {
         return mix(getFromColor( p), getToColor( p), progress);
     } else {
         vec2 offset = dir * sin(dist * amplitude - progress * speed);
         return mix(getFromColor( p + offset), getToColor( p), progress);
     }
 }
 
 float butterflyWave_compute(vec2 p, float progress, vec2 center) {
     float PI = 3.14159265358979323846264;
     float amplitude = 1.0;
     float waves = 30.0;
     vec2 o = p*sin(progress * amplitude)-center;
     // horizontal vector
     vec2 h = vec2(1., 0.);
     // butterfly polar function (don't ask me why this one :))
     float theta = acos(dot(o, h)) * waves;
     return (exp(cos(theta)) - 2.*cos(4.*theta) + pow(sin((2.*theta - PI) / 24.), 5.)) / 10.;
 }
 vec4 butterflyWave(vec2 uv) {
     float colorSeparation = 0.3;
     vec2 p = uv.xy / vec2(1.0).xy;
     float inv = 1. - progress;
     vec2 dir = p - vec2(.5);
     float dist = length(dir);
     float disp = butterflyWave_compute(p, progress, vec2(0.5, 0.5)) ;
     vec4 texTo = getToColor(p + inv*disp);
     vec4 texFrom = vec4(
                         getFromColor(p + progress*disp*(1.0 - colorSeparation)).r,
                         getFromColor(p + progress*disp).g,
                         getFromColor(p + progress*disp*(1.0 + colorSeparation)).b,
                         1.0);
     return texTo*progress + texFrom*inv;
 }
 
 vec4 windowBlinds (vec2 uv) {
     float t = progress;
     
     if (mod(floor(uv.y*100.*progress),2.)==0.)
         t*=2.-.5;
     
     return mix(
                getFromColor(uv),
                getToColor(uv),
                mix(t, progress, smoothstep(0.8, 1.0, progress))
                );
 }
 
 float heart_inHeart (vec2 p, vec2 center, float size) {
     if (size==0.0) return 0.0;
     p.y = 1. - p.y;
     vec2 o = (p-center)/(1.6*size);
     float a = o.x*o.x+o.y*o.y-0.3;
     return step(a*a*a, o.x*o.x*o.y*o.y*o.y);
 }
 vec4 heart (vec2 uv) {
     return mix(
                getFromColor(uv),
                getToColor(uv),
                heart_inHeart(uv, vec2(0.5, 0.4), progress)
                );
 }
 
 float crosshatch_rand(vec2 co) {
     return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
 }
 vec4 crosshatch(vec2 p) {
     vec2 center = vec2(0.5);
     float threshold = 3.0;
     float fadeEdge = 0.1;
     float dist = distance(center, p) / threshold;
     float r = progress - min(crosshatch_rand(vec2(p.y, 0.0)), crosshatch_rand(vec2(0.0, p.x)));
     return mix(getFromColor(p), getToColor(p), mix(0.0, mix(step(dist, r), 1.0, smoothstep(1.0-fadeEdge, 1.0, progress)), smoothstep(0.0, fadeEdge, progress)));
 }
 
 float crossZoom_Linear_ease(in float begin, in float change, in float duration, in float time) {
     return change * time / duration + begin;
 }
 
 float crossZoom_Exponential_easeInOut(in float begin, in float change, in float duration, in float time) {
     if (time == 0.0)
         return begin;
     else if (time == duration)
         return begin + change;
     time = time / (duration / 2.0);
     if (time < 1.0)
         return change / 2.0 * pow(2.0, 10.0 * (time - 1.0)) + begin;
     return change / 2.0 * (-pow(2.0, -10.0 * (time - 1.0)) + 2.0) + begin;
 }
 
 float crossZoom_Sinusoidal_easeInOut(in float begin, in float change, in float duration, in float time) {
     const float PI = 3.141592653589793;
     return -change / 2.0 * (cos(PI * time / duration) - 1.0) + begin;
 }
 
 float crossZoom_rand (vec2 co) {
     return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
 }
 
 vec3 crossZoom_crossFade(in vec2 uv, in float dissolve) {
     return mix(getFromColor(uv).rgb, getToColor(uv).rgb, dissolve);
 }
 
 vec4 crossZoom(vec2 uv) {
     float ustrength = 0.4;
     vec2 texCoord = uv.xy / vec2(1.0).xy;
     
     // Linear interpolate center across center half of the image
     vec2 center = vec2(crossZoom_Linear_ease(0.25, 0.5, 1.0, progress), 0.5);
     float dissolve = crossZoom_Exponential_easeInOut(0.0, 1.0, 1.0, progress);
     
     // Mirrored sinusoidal loop. 0->strength then strength->0
     float strength = crossZoom_Sinusoidal_easeInOut(0.0, ustrength, 0.5, progress);
     
     vec3 color = vec3(0.0);
     float total = 0.0;
     vec2 toCenter = center - texCoord;
     
     /* randomize the lookup values to hide the fixed number of samples */
     float offset = crossZoom_rand(uv);
     
     for (float t = 0.0; t <= 40.0; t++) {
         float percent = (t + offset) / 40.0;
         float weight = 4.0 * (percent - percent * percent);
         color += crossZoom_crossFade(texCoord + toCenter * percent * strength, dissolve) * weight;
         total += weight;
     }
     return vec4(color / total, 1.0);
 }
 
 vec2 dreamy_offset(float progress, float x, float theta) {
     float phase = progress*progress + progress + theta;
     float shifty = 0.03*progress*cos(10.0*(progress+x));
     return vec2(0, shifty);
 }
 vec4 dreamy(vec2 p) {
     return mix(getFromColor(p + dreamy_offset(progress, p.x, 0.0)), getToColor(p + dreamy_offset(1.0-progress, p.x, 3.14)), progress);
 }
 
 const float MIN_AMOUNT = -0.16;
 const float MAX_AMOUNT = 1.5;
 float IPC_amount = progress * (MAX_AMOUNT - MIN_AMOUNT) + MIN_AMOUNT;
 const float IPC_PI = 3.141592653589793;
 float IPC_cylinderAngle = 2.0 * IPC_PI * IPC_amount;
 const float IPC_cylinderRadius = 1.0 / IPC_PI / 2.0;
 vec3 IPC_hitPoint(float hitAngle, float yc, vec3 point, mat3 rrotation)
{
    float hitPoint = hitAngle / (2.0 * IPC_PI);
    point.y = hitPoint;
    return rrotation * point;
}
 vec4 IPC_antiAlias(vec4 color1, vec4 color2, float distanc)
{
    const float scale = 512.0;
    const float sharpness = 3.0;
    distanc *= scale;
    if (distanc < 0.0) return color2;
    if (distanc > 2.0) return color1;
    float dd = pow(1.0 - distanc / 2.0, sharpness);
    return ((color2 - color1) * dd) + color1;
}
 float IPC_distanceToEdge(vec3 point)
{
    float dx = abs(point.x > 0.5 ? 1.0 - point.x : point.x);
    float dy = abs(point.y > 0.5 ? 1.0 - point.y : point.y);
    if (point.x < 0.0) dx = -point.x;
    if (point.x > 1.0) dx = point.x - 1.0;
    if (point.y < 0.0) dy = -point.y;
    if (point.y > 1.0) dy = point.y - 1.0;
    if ((point.x < 0.0 || point.x > 1.0) && (point.y < 0.0 || point.y > 1.0)) return sqrt(dx * dx + dy * dy);
    return min(dx, dy);
}
 vec4 IPC_seeThrough(float yc, vec2 p, mat3 rotation, mat3 rrotation)
{
    float hitAngle = IPC_PI - (acos(yc / IPC_cylinderRadius) - IPC_cylinderAngle);
    vec3 point = IPC_hitPoint(hitAngle, yc, rotation * vec3(p, 1.0), rrotation);
    if (yc <= 0.0 && (point.x < 0.0 || point.y < 0.0 || point.x > 1.0 || point.y > 1.0))
    {
        return getToColor(p);
    }
    
    if (yc > 0.0) return getFromColor(p);
    
    vec4 color = getFromColor(point.xy);
    vec4 tcolor = vec4(0.0);
    
    return IPC_antiAlias(color, tcolor, IPC_distanceToEdge(point));
}
 vec4 IPC_seeThroughWithShadow(float yc, vec2 p, vec3 point, mat3 rotation, mat3 rrotation)
{
    float shadow = IPC_distanceToEdge(point) * 30.0;
    shadow = (1.0 - shadow) / 3.0;
    
    if (shadow < 0.0) shadow = 0.0; else shadow *= IPC_amount;
    
    vec4 shadowColor = IPC_seeThrough(yc, p, rotation, rrotation);
    shadowColor.r -= shadow;
    shadowColor.g -= shadow;
    shadowColor.b -= shadow;
    
    return shadowColor;
}
 vec4 IPC_backside(float yc, vec3 point)
{
    vec4 color = getFromColor(point.xy);
    float gray = (color.r + color.b + color.g) / 15.0;
    gray += (8.0 / 10.0) * (pow(1.0 - abs(yc / IPC_cylinderRadius), 2.0 / 10.0) / 2.0 + (5.0 / 10.0));
    color.rgb = vec3(gray);
    return color;
}
 vec4 IPC_behindSurface(vec2 p, float yc, vec3 point, mat3 rrotation)
{
    float shado = (1.0 - ((-IPC_cylinderRadius - yc) / IPC_amount * 7.0)) / 6.0;
    shado *= 1.0 - abs(point.x - 0.5);
    
    yc = (-IPC_cylinderRadius - IPC_cylinderRadius - yc);
    
    float hitAngle = (acos(yc / IPC_cylinderRadius) + IPC_cylinderAngle) - IPC_PI;
    point = IPC_hitPoint(hitAngle, yc, point, rrotation);
    
    if (yc < 0.0 && point.x >= 0.0 && point.y >= 0.0 && point.x <= 1.0 && point.y <= 1.0 && (hitAngle < IPC_PI || IPC_amount > 0.5))
    {
        shado = 1.0 - (sqrt(pow(point.x - 0.5, 2.0) + pow(point.y - 0.5, 2.0)) / (71.0 / 100.0));
        shado *= pow(-yc / IPC_cylinderRadius, 3.0);
        shado *= 0.5;
    }
    else
    {
        shado = 0.0;
    }
    return vec4(getToColor(p).rgb - shado, 1.0);
}
 vec4 pageCurl(vec2 p) {
     float cylinderCenter = IPC_amount;
     
     
     const float angle = 100.0 * IPC_PI / 180.0;
     float c = cos(-angle);
     float s = sin(-angle);
     
     mat3 rotation = mat3( c, s, 0,
                          -s, c, 0,
                          -0.801, 0.8900, 1
                          );
     c = cos(angle);
     s = sin(angle);
     
     mat3 rrotation = mat3(  c, s, 0,
                           -s, c, 0,
                           0.98500, 0.985, 1
                           );
     
     vec3 point = rotation * vec3(p, 1.0);
     
     float yc = point.y - cylinderCenter;
     
     if (yc < -IPC_cylinderRadius)
     {
         // Behind surface
         return IPC_behindSurface(p,yc, point, rrotation);
     }
     
     if (yc > IPC_cylinderRadius)
     {
         // Flat surface
         return getFromColor(p);
     }
     
     float hitAngle = (acos(yc / IPC_cylinderRadius) + IPC_cylinderAngle) - IPC_PI;
     
     float hitAngleMod = mod(hitAngle, 2.0 * IPC_PI);
     if ((hitAngleMod > IPC_PI && IPC_amount < 0.5) || (hitAngleMod > IPC_PI/2.0 && IPC_amount < 0.0))
     {
         return IPC_seeThrough(yc, p, rotation, rrotation);
     }
     
     point = IPC_hitPoint(hitAngle, yc, point, rrotation);
     
     if (point.x < 0.0 || point.y < 0.0 || point.x > 1.0 || point.y > 1.0)
     {
         return IPC_seeThroughWithShadow(yc, p, point, rotation, rrotation);
     }
     
     vec4 color = IPC_backside(yc, point);
     
     vec4 otherColor;
     if (yc < 0.0)
     {
         float shado = 1.0 - (sqrt(pow(point.x - 0.5, 2.0) + pow(point.y - 0.5, 2.0)) / 0.71);
         shado *= pow(-yc / IPC_cylinderRadius, 3.0);
         shado *= 0.5;
         otherColor = vec4(0.0, 0.0, 0.0, shado);
     }
     else
     {
         otherColor = getFromColor(p);
     }
     
     color = IPC_antiAlias(color, otherColor, IPC_cylinderRadius - abs(yc));
     
     vec4 cl = IPC_seeThroughWithShadow(yc, p, point, rotation, rrotation);
     float dist = IPC_distanceToEdge(point);
     
     return IPC_antiAlias(color, cl, dist);
 }
 
 float SV_zoom = 0.88;
 const vec4 SV_black = vec4(0.0, 0.0, 0.0, 1.0);
 const vec2 SV_c00 = vec2(0.0, 0.0); // the four corner points
 const vec2 SV_c01 = vec2(0.0, 1.0);
 const vec2 SV_c11 = vec2(1.0, 1.0);
 const vec2 SV_c10 = vec2(1.0, 0.0);
 int SV_in_corner(vec2 p, vec2 corner, vec2 radius) {
     vec2 axis = (SV_c11 - corner) - corner;
     p = p - (corner + axis * radius);
     p *= axis / radius;
     if ((p.x > 0.0 && p.y > -1.0) || (p.y > 0.0 && p.x > -1.0) || dot(p, p) < 1.0) {
         return 1;
     }
     return 0;
     //return (p.x > 0.0 && p.y > -1.0) || (p.y > 0.0 && p.x > -1.0) || dot(p, p) < 1.0;
 }
 int SV_test_rounded_mask(vec2 p, vec2 corner_size) {
     if (SV_in_corner(p, SV_c00, corner_size) == 0 ||
         SV_in_corner(p, SV_c01, corner_size) == 0 ||
         SV_in_corner(p, SV_c10, corner_size) == 0 ||
         SV_in_corner(p, SV_c11, corner_size) == 0) {
         return 0;
     }
     
     return 1;
//
//     if (SV_in_corner(p, SV_c00, corner_size) != 0 &&
//         SV_in_corner(p, SV_c01, corner_size) != 0 &&
//         SV_in_corner(p, SV_c10, corner_size) != 0 &&
//         SV_in_corner(p, SV_c11, corner_size) != 0) {
//         return 1;
//     }
//     return 0;
//     return
//     SV_in_corner(p, SV_c00, corner_size) &&
//     SV_in_corner(p, SV_c01, corner_size) &&
//     SV_in_corner(p, SV_c10, corner_size) &&
//     SV_in_corner(p, SV_c11, corner_size);
 }
 vec4 screen(vec4 a, vec4 b) {
     return 1.0 - (1.0 - a) * (1.0 -b);
 }
 vec4 unscreen(vec4 c) {
     return 1.0 - sqrt(1.0 - c);
 }
 vec4 SV_sample_with_corners_from(vec2 p, vec2 corner_size) {
     p = (p - 0.5) / SV_zoom + 0.5;
     if (SV_test_rounded_mask(p, corner_size) == 0) {
         return SV_black;
     }
     return unscreen(getFromColor(p));
 }
 vec4 SV_sample_with_corners_to(vec2 p, vec2 corner_size) {
     p = (p - 0.5) / SV_zoom + 0.5;
     if (SV_test_rounded_mask(p, corner_size) == 0) {
         return SV_black;
     }
     return unscreen(getToColor(p));
 }
 vec4 SV_simple_sample_with_corners_from(vec2 p, vec2 corner_size, float zoom_amt) {
     p = (p - 0.5) / (1.0 - zoom_amt + SV_zoom * zoom_amt) + 0.5;
     if (SV_test_rounded_mask(p, corner_size) == 0) {
         return SV_black;
     }
     return getFromColor(p);
 }
 vec4 SV_simple_sample_with_corners_to(vec2 p, vec2 corner_size, float zoom_amt) {
     p = (p - 0.5) / (1.0 - zoom_amt + SV_zoom * zoom_amt) + 0.5;
     if (SV_test_rounded_mask(p, corner_size) == 0) {
         return SV_black;
     }
     return getToColor(p);
 }
 mat3 rotate2d(float angle, float ratio) {
     float s = sin(angle);
     float c = cos(angle);
     return mat3(
                 c, s ,0.0,
                 -s, c, 0.0,
                 0.0, 0.0, 1.0);
 }
 mat3 translate2d(float x, float y) {
     return mat3(
                 1.0, 0.0, 0,
                 0.0, 1.0, 0,
                 -x, -y, 1.0);
 }
 mat3 scale2d(float x, float y) {
     return mat3(
                 x, 0.0, 0,
                 0.0, y, 0,
                 0, 0, 1.0);
 }
 vec4 SV_get_cross_rotated(vec3 p3, float angle, vec2 corner_size, float ratio) {
     angle = angle * angle; // easing
     angle /= 2.4; // works out to be a good number of radians
     
     mat3 center_and_scale = translate2d(-0.5, -0.5) * scale2d(1.0, ratio);
     mat3 unscale_and_uncenter = scale2d(1.0, 1.0/ratio) * translate2d(0.5,0.5);
     mat3 slide_left = translate2d(-2.0,0.0);
     mat3 slide_right = translate2d(2.0,0.0);
     mat3 rotate = rotate2d(angle, ratio);
     
     mat3 op_a = center_and_scale * slide_right * rotate * slide_left * unscale_and_uncenter;
     mat3 op_b = center_and_scale * slide_left * rotate * slide_right * unscale_and_uncenter;
     
     vec4 a = SV_sample_with_corners_from((op_a * p3).xy, corner_size);
     vec4 b = SV_sample_with_corners_from((op_b * p3).xy, corner_size);
     
     return screen(a, b);
 }
 vec4 SV_get_cross_masked(vec3 p3, float angle, vec2 corner_size, float ratio) {
     angle = 1.0 - angle;
     angle = angle * angle; // easing
     angle /= 2.4;
     
     vec4 img;
     
     mat3 center_and_scale = translate2d(-0.5, -0.5) * scale2d(1.0, ratio);
     mat3 unscale_and_uncenter = scale2d(1.0 / SV_zoom, 1.0 / (SV_zoom * ratio)) * translate2d(0.5,0.5);
     mat3 slide_left = translate2d(-2.0,0.0);
     mat3 slide_right = translate2d(2.0,0.0);
     mat3 rotate = rotate2d(angle, ratio);
     
     mat3 op_a = center_and_scale * slide_right * rotate * slide_left * unscale_and_uncenter;
     mat3 op_b = center_and_scale * slide_left * rotate * slide_right * unscale_and_uncenter;
     
     int mask_a = SV_test_rounded_mask((op_a * p3).xy, corner_size);
     int mask_b = SV_test_rounded_mask((op_b * p3).xy, corner_size);
     
     if (mask_a != 0 || mask_b != 0) {
         img = SV_sample_with_corners_to(p3.xy, corner_size);
         return screen(mask_a == 1 ? img : SV_black, mask_b == 1 ? img : SV_black);
     } else {
         return SV_black;
     }
 }
 vec4 stereoViewer(vec2 uv) {
     float corner_radius = 0.22;
     float a;
     vec2 p=uv.xy/vec2(1.0).xy;
     vec3 p3 = vec3(p.xy, 1.0); // for 2D matrix transforms
     
     float ratio = 1.0;
     
     // corner is warped to represent to size after mapping to 1.0, 1.0
     vec2 corner_size = vec2(corner_radius / ratio, corner_radius);
     
     if (progress <= 0.0) {
         // 0.0: start with the base frame always
         return getFromColor(p);
     } else if (progress < 0.1) {
         // 0.0-0.1: zoom out and add rounded corners
         a = progress / 0.1;
         return  SV_simple_sample_with_corners_from(p, corner_size * a, a);
     } else if (progress < 0.48) {
         // 0.1-0.48: Split original image apart
         a = (progress - 0.1)/0.38;
         return SV_get_cross_rotated(p3, a, corner_size, ratio);
     } else if (progress < 0.9) {
         // 0.48-0.52: SV_black
         // 0.52 - 0.9: unmask new image
         return SV_get_cross_masked(p3, (progress - 0.52)/0.38, corner_size, ratio);
     } else if (progress < 1.0) {
         // zoom out and add rounded corners
         a = (1.0 - progress) / 0.1;
         return SV_simple_sample_with_corners_to(p, corner_size * a, a);
     } else {
         // 1.0 end with base frame
         return getToColor(p);
     }
 }
 
 vec4 kaleidoscope(vec2 uv) {
     float speed = 1.0;
     float angle = 1.0;
     float power = 1.5;
     
     vec2 p = uv.xy / vec2(1.0).xy;
     vec2 q = p;
     float t = pow(progress, power)*speed;
     p = p -0.5;
     for (int i = 0; i < 7; i++) {
         p = vec2(sin(t)*p.x + cos(t)*p.y, sin(t)*p.y - cos(t)*p.x);
         t += angle;
         p = abs(mod(p, 2.0) - 1.0);
     }
     abs(mod(p, 1.0));
     return mix(
                mix(getFromColor(q), getToColor(q), progress),
                mix(getFromColor(p), getToColor(p), progress), 1.0 - 2.0*abs(progress - 0.5));
 }
 
 highp float gd_random(vec2 co)
{
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt= dot(co.xy ,vec2(a,b));
    highp float sn= mod(dt,3.14);
    return fract(sin(sn) * c);
}
 float gd_voronoi( in vec2 x ) {
     vec2 p = floor( x );
     vec2 f = fract( x );
     float res = 8.0;
     for( float j=-1.; j<=1.; j++ )
         for( float i=-1.; i<=1.; i++ ) {
             vec2  b = vec2( i, j );
             vec2  r = b - f + gd_random( p + b );
             float d = dot( r, r );
             res = min( res, d );
         }
     return sqrt( res );
 }
 
 vec2 gd_displace(vec4 tex, vec2 texCoord, float dotDepth, float textureDepth, float strength) {
     float b = gd_voronoi(.003 * texCoord + 2.0);
     float g = gd_voronoi(0.2 * texCoord);
     float r = gd_voronoi(texCoord - 1.0);
     vec4 dt = tex * 1.0;
     vec4 dis = dt * dotDepth + 1.0 - tex * textureDepth;
     
     dis.x = dis.x - 1.0 + textureDepth*dotDepth;
     dis.y = dis.y - 1.0 + textureDepth*dotDepth;
     dis.x *= strength;
     dis.y *= strength;
     vec2 res_uv = texCoord ;
     res_uv.x = res_uv.x + dis.x - 0.0;
     res_uv.y = res_uv.y + dis.y;
     return res_uv;
 }
 
 float gd_ease1(float t) {
     return t == 0.0 || t == 1.0
     ? t
     : t < 0.5
     ? +0.5 * pow(2.0, (20.0 * t) - 10.0)
     : -0.5 * pow(2.0, 10.0 - (t * 20.0)) + 1.0;
 }
 float gd_ease2(float t) {
     return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t);
 }
 
 vec4 glitchdisplace(vec2 uv) {
     vec2 p = uv.xy / vec2(1.0).xy;
     vec4 color1 = getFromColor(p);
     vec4 color2 = getToColor(p);
     vec2 disp = gd_displace(color1, p, 0.33, 0.7, 1.0-gd_ease1(progress));
     vec2 disp2 = gd_displace(color2, p, 0.33, 0.5, gd_ease2(progress));
     vec4 dColor1 = getToColor(disp);
     vec4 dColor2 = getFromColor(disp2);
     float val = gd_ease1(progress);
     vec3 gray = vec3(dot(min(dColor2, dColor1).rgb, vec3(0.299, 0.587, 0.114)));
     dColor2 = vec4(gray, 1.0);
     dColor2 *= 2.0;
     color1 = mix(color1, dColor2, smoothstep(0.0, 0.5, progress));
     color2 = mix(color2, dColor1, smoothstep(1.0, 0.5, progress));
     return mix(color1, color2, val);
 }
 
 vec4 dreamyzoom(vec2 uv) {
     highp float DEG2RAD = 0.03926990816987241548078304229099;
     float rotation = 6.0;
     float scale = 1.2;
     
     // Massage parameters
     float phase = progress < 0.5 ? progress * 2.0 : (progress - 0.5) * 2.0;
     float angleOffset = progress < 0.5 ? mix(0.0, rotation * DEG2RAD, phase) : mix(-rotation * DEG2RAD, 0.0, phase);
     float newScale = progress < 0.5 ? mix(1.0, scale, phase) : mix(scale, 1.0, phase);
     
     vec2 center = vec2(0, 0);
     
     // Calculate the source point
     vec2 assumedCenter = vec2(0.5, 0.5);
     vec2 p = (uv.xy - vec2(0.5, 0.5)) / newScale * vec2(ratio, 1.0);
     
     // This can probably be optimized (with distance())
     float angle = atan(p.y, p.x) + angleOffset;
     float dist = distance(center, p);
     p.x = cos(angle) * dist / ratio + 0.5;
     p.y = sin(angle) * dist + 0.5;
     vec4 c = progress < 0.5 ? getFromColor(p) : getToColor(p);
     
     // Finally, apply the color
     return c + (progress < 0.5 ? mix(0.0, 1.0, phase) : mix(1.0, 0.0, phase));
 }
 
 vec4 ripple (vec2 uv) {
     float amplitude = 100.0;
     float speed = 50.0;
     vec2 dir = uv - vec2(.5);
     float dist = length(dir);
     vec2 offset = dir * (sin(progress * dist * amplitude - progress * speed) + .5) / 30.;
     return mix(
                getFromColor(uv + offset),
                getToColor(uv),
                smoothstep(0.2, 1.0, progress)
                );
 }
 
 vec4 burn (vec2 uv) {
     vec3 color = vec3(0.9, 0.4, 0.2);
     return mix(
                getFromColor(uv) + vec4(progress*color, 1.0),
                getToColor(uv) + vec4((1.0-progress)*color, 1.0),
                progress
                );
 }
 
 vec4 circle (vec2 uv) {
     vec2 center = vec2(0.5, 0.5);
     vec3 backColor = vec3(0.1, 0.1, 0.1);
     
     float distance = length(uv - center);
     float radius = sqrt(8.0) * abs(progress - 0.5);
     
     if (distance > radius) {
         return vec4(backColor, 1.0);
     }
     else {
         if (progress < 0.5) return getFromColor(uv);
         else return getToColor(uv);
     }
 }
 
 vec4 colorPhase (vec2 uv) {
     vec4 fromStep = vec4(0.0, 0.2, 0.4, 0.0);
     vec4 toStep = vec4(0.6, 0.8, 1.0, 1.0);
     vec4 a = getFromColor(uv);
     vec4 b = getToColor(uv);
     return mix(a, b, smoothstep(fromStep, toStep, vec4(progress)));
 }
 
 vec4 crosswrap(vec2 p) {
     float x = progress;
     x=smoothstep(.0,1.0,(x*2.0+p.x-1.0));
     return mix(getFromColor((p-.5)*(1.-x)+.5), getToColor((p-.5)*x+.5), x);
 }

 int dw_inBounds (vec2 p) {
     if (p.x >= 0.0 && p.x <= 1.0 &&
         p.y >= 0.0 && p.y <= 1.0) {
         return 1;
     }
     return 0;
 }
 
 vec2 dw_project (vec2 p) {
     return p * vec2(1.0, -1.2) + vec2(0.0, -0.02);
 }
 
 vec4 dw_bgColor (vec2 p, vec2 pto) {
     const vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
     float reflection = 0.4;
     vec4 c = black;
     pto = dw_project(pto);
     if (dw_inBounds(pto) == 1) {
         c += mix(black, getToColor(pto), reflection * mix(1.0, 0.0, pto.y));
     }
     return c;
 }
 
 vec4 doorway (vec2 p) {
     float perspective = 0.4;
     float depth = 3.0;
     vec2 pfr = vec2(-1.0);
     vec2 pto = vec2(-1.0);
     float middleSlit = 2.0 * abs(p.x-0.5) - progress;
     if (middleSlit > 0.0) {
         pfr = p + (p.x > 0.5 ? -1.0 : 1.0) * vec2(0.5*progress, 0.0);
         float d = 1.0/(1.0+perspective*progress*(1.0-middleSlit));
         pfr.y -= d/2.;
         pfr.y *= d;
         pfr.y += d/2.;
     }
     float size = mix(1.0, depth, 1.-progress);
     pto = (p + vec2(-0.5, -0.5)) * vec2(size, size) + vec2(0.5, 0.5);
     if (dw_inBounds(pfr) == 1) {
         return getFromColor(pfr);
     }
     else if (dw_inBounds(pto) == 1) {
         return getToColor(pto);
     }
     else {
         return dw_bgColor(p, pto);
     }
 }

 vec4 flyeye(vec2 p) {
     float size = 0.04;
     float zoom = 50.0;
     float colorSeparation = 0.3;
     
     float inv = 1. - progress;
     vec2 disp = size*vec2(cos(zoom*p.x), sin(zoom*p.y));
     vec4 texTo = getToColor(p + inv*disp);
     vec4 texFrom = vec4(
                         getFromColor(p + progress*disp*(1.0 - colorSeparation)).r,
                         getFromColor(p + progress*disp).g,
                         getFromColor(p + progress*disp*(1.0 + colorSeparation)).b,
                         1.0);
     return texTo*progress + texFrom*inv;
 }
 
 vec4 rsfade (vec2 uv) {
     float PI = 3.14159265359;
     vec2 center = vec2(0.5, 0.5);
     float rotations = 1.0;
     float scale = 8.0;
     vec4 backColor = vec4(0.15, 0.15, 0.15, 1.0);
     
     vec2 difference = uv - center;
     vec2 dir = normalize(difference);
     float dist = length(difference);
     
     float angle = 2.0 * PI * rotations * progress;
     
     float c = cos(angle);
     float s = sin(angle);
     
     float currentScale = mix(scale, 1.0, 2.0 * abs(progress - 0.5));
     
     vec2 rotatedDir = vec2(dir.x  * c - dir.y * s, dir.x * s + dir.y * c);
     vec2 rotatedUv = center + rotatedDir * dist / currentScale;
     
     if (rotatedUv.x < 0.0 || rotatedUv.x > 1.0 ||
         rotatedUv.y < 0.0 || rotatedUv.y > 1.0)
         return backColor;
     
     return mix(getFromColor(rotatedUv), getToColor(rotatedUv), progress);
 }
 
 float wind_rand (vec2 co) {
     return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
 }
 
 vec4 wind (vec2 uv) {
     float size = 0.2;
     float r = wind_rand(vec2(0, uv.y));
     float m = smoothstep(0.0, -size, uv.x*(1.0-size) + size*r - (progress * (1.0 + size)));
     return mix(
                getFromColor(uv),
                getToColor(uv),
                m
                );
 }

 
 void main()
 {
     vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
     if (type == 0) {       // kSSTransitionTypeDirectional
         color = directional(textureCoordinate);
     }
     else if (type == 1) {  // kSSTransitionTypeWindowSlice
         color = windowSlice(textureCoordinate);
     }
     else if (type == 2) {  // kSSTransitionTypeSimpleZoom
         color = simpleZoom(textureCoordinate);
     }
     else if (type == 3) {  // kSSTransitionTypeLinearBlur
         color = linearBlur(textureCoordinate);
     }
     else if (type == 4) {  // kSSTransitionTypeWaterDrop
         color = waterDrop(textureCoordinate);
     }
     else if (type == 5) {  // kSSTransitionTypeInvertedPageCurl
         color = pageCurl(textureCoordinate);
     }
     else if (type == 6) {  // kSSTransitionTypeStereoViewer
         color = stereoViewer(textureCoordinate);
     }
     else if (type == 7) {  // kSSTransitionTypeDirectionalWrap
         color = directionalWrap(textureCoordinate);
     }
     else if (type == 8) {  // kSSTransitionTypeMorph
         color = morph(textureCoordinate);
     }
     else if (type == 9) { // kSSTransitionTypeCrossZoom
         color = crossZoom(textureCoordinate);
     }
     else if (type == 10) { // kSSTransitionTypeDreamy
         color = dreamy(textureCoordinate);
     }
     else if (type == 11) { // kSSTransitionTypeCrosshatch
         color = crosshatch(textureCoordinate);
     }
     else if (type == 12) {  // kSSTransitionTypeButterflyWave
         color = butterflyWave(textureCoordinate);
     }
     else if (type == 13) { // kSSTransitionTypeKaleidoscope
         color = kaleidoscope(textureCoordinate);
     }
     else if (type == 14) { // kSSTransitionTypeWindowBlinds
         color = windowBlinds(textureCoordinate);
     }
     else if (type == 15) { // kSSTransitionTypeGlitchDisplace
         color = glitchdisplace(textureCoordinate);
     }
     else if (type == 16) { // kSSTransitionTypeDreamyZoom
         color = dreamyzoom(textureCoordinate);
     }
     else if (type == 17) { // kSSTransitionTypeRipple
         color = ripple(textureCoordinate);
     }
     else if (type == 18) { // kSSTransitionTypeBurn
         color = burn(textureCoordinate);
     }
     else if (type == 19) { // kSSTransitionTypeCircle
         color = circle(textureCoordinate);
     }
     else if (type == 20) { // kSSTransitionTypeColorPhase
         color = colorPhase(textureCoordinate);
     }
     else if (type == 21) { // kSSTransitionTypeCrosswrap
         color = crosswrap(textureCoordinate);
     }
     else if (type == 22) { // kSSTransitionTypeDoorway
         color = doorway(textureCoordinate);
     }
     else if (type == 23) { // kSSTransitionTypeFlyeye
         color = flyeye(textureCoordinate);
     }
     else if (type == 24) { // kSSTransitionTypeHeart
         color = heart(textureCoordinate);
     }
     else if (type == 25) { // kSSTransitionTypeRotateScaleFade
         color = rsfade(textureCoordinate);
     }
     else if (type == 26) { // kSSTransitionTypeWind
         color = wind(textureCoordinate);
     }
     
     gl_FragColor = color;
 }
);

@interface SSTransitionFilter()
{
    GLint progressUniform;
    GLint typeUniform;
    GLint ratioUniform;
}
@end

@implementation SSTransitionFilter

#pragma mark - Life Cycle
-(id)init {
    self = [super initWithFragmentShaderFromString:kSSTransitionFilterFragmentShaderString];
    if (self) {
        progressUniform = [filterProgram uniformIndex:@"progress"];
        self.progress = 0.0f;
        
        typeUniform = [filterProgram uniformIndex:@"type"];
        self.type = kSSTransitionTypeHeart;
        
        ratioUniform = [filterProgram uniformIndex:@"ratio"];
        self.ratio = 1.0f;
    }
    return self;
}


#pragma mark - Setter
-(void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self setFloat:_progress forUniform:progressUniform program:filterProgram];
}

-(void)setType:(SSTransitionType)type {
    _type = type;
    [self setInteger:_type forUniformName:@"type"];
}

-(void)setRatio:(CGFloat)ratio {
    _ratio = ratio;
    [self setFloat:_ratio forUniformName:@"ratio"];
}

@end
