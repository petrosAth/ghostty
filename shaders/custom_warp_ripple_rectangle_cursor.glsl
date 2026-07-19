// --- COMBINED SHADER: Cursor Warp + Ripple Rectangle ---

// --- 📜 CONFIGURATION

// --- Warp Trail Config ---
vec4 TRAIL_COLOR = iCurrentCursorColor; // can change to eg: vec4(0.2, 0.6, 1.0, 0.5);
const float WARP_DURATION = 0.2; // total animation time
const float TRAIL_SIZE = 0.8; // 0.0 = all corners move together.
// 1.0 = max smear (leading corners jump instantly)
const float THRESHOLD_MIN_DISTANCE = 1.5;
// min distance to show trail (units of cursor height)
const float WARP_BLUR = 1.0;
// blur size in pixels (for antialiasing)
const float TRAIL_THICKNESS = 1.0;
// 1.0 = full cursor height, 0.0 = zero height, >1.0 = funky aah
const float TRAIL_THICKNESS_X = 0.9;
const float FADE_ENABLED = 0.0; // 1.0 to enable fade gradient along the trail, 0.0 to disable
const float FADE_EXPONENT = 5.0;
// exponent for fade gradient along the trail

// --- Ripple Effect Config ---
const float RIPPLE_DURATION = 0.15; // How long the ripple animates (seconds)
const float MAX_SIZE = 0.05;
// Max radius in normalized coords (0.5 = 1/4 screen height)
const float RING_THICKNESS = 0.02;
// Ring width in normalized coords
const float CURSOR_WIDTH_CHANGE_THRESHOLD = 0.5;
// Triggers ripple if cursor width changes by this fraction
vec4 RIPPLE_COLOR = vec4(0.35, 0.36, 0.44, 1.0);
// change to iCurrentCursorColor for your cursor's color
const float RIPPLE_BLUR = 1.0; // Blur level in pixels
const float ANIMATION_START_OFFSET = 0.0; // Start the ripple slightly progressed (0.0 - 1.0)

// --- 🎢 EASING FUNCTIONS

// --- CONSTANTS for easing functions ---
const float PI = 3.14159265359;
const float C1_BACK = 1.70158;
const float C2_BACK = C1_BACK * 1.525;
const float C3_BACK = C1_BACK + 1.0;
const float C4_ELASTIC = (2.0 * PI) / 3.0;
const float C5_ELASTIC = (2.0 * PI) / 4.5;
const float SPRING_STIFFNESS = 9.0;
const float SPRING_DAMPING = 0.9;

// --- Easing Functions Library ---

// EaseOutQuad
float easeOutQuad(float t) {
    return 1.0 - (1.0 - t) * (1.0 - t);
}

// EaseInOutQuad
float easeInOutQuad(float t) {
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}

// EaseOutCubic
float easeOutCubic(float t) {
    return 1.0 - pow(1.0 - t, 3.0);
}

// EaseOutQuart
float easeOutQuart(float t) {
    return 1.0 - pow(1.0 - t, 4.0);
}

// EaseOutQuint
float easeOutQuint(float t) {
    return 1.0 - pow(1.0 - t, 5.0);
}

// EaseOutSine
float easeOutSine(float t) {
    return sin((t * 3.1415916) / 2.0);
}

// EaseOutExpo
float easeOutExpo(float t) {
    return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t);
}

// EaseOutCirc
float easeOutCirc(float t) {
    return sqrt(1.0 - pow(t - 1.0, 2.0));
}

// EaseOutBack
float easeOutBack(float t) {
    const float c1 = 1.70158;
    const float c3 = c1 + 1.0;
    return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0);
}

// EaseOutElastic
float easeOutElastic(float t) {
    const float c4 = (2.0 * 3.1415916) / 3.0;
    return t == 0.0 ? 0.0 : t == 1.0 ? 1.0 : pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0;
}

// EaseOutBounce
float easeOutBounce(float t) {
    const float n1 = 7.5625;
    const float d1 = 2.75;
    if (t < 1.0 / d1) {
        return n1 * t * t;
    } else if (t < 2.0 / d1) {
        return n1 * (t -= 1.5 / d1) * t + 0.75;
    } else if (t < 2.5 / d1) {
        return n1 * (t -= 2.25 / d1) * t + 0.9375;
    } else {
        return n1 * (t -= 2.625 / d1) * t + 0.984375;
    }
}

// Pulse fade functions
float easeOutPulse(float t) {
    return t * (2.0 - t);
}
float exponentialDecayPulse(float t) {
    return exp(-3.0 * t) * sin(t * 3.1415916);
}

// *** THIS IS THE FIX ***
// Define the `ease` function required by the warp code
// to use the `easeOutCirc` function[cite: 69].
float ease(float x) {
    return easeOutCirc(x);
}

// --- 🛠️ HELPER FUNCTIONS

// SDF for a rectangle
float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching
float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

// SDF for a convex quadrilateral
float getSdfConvexQuad(in vec2 p, in vec2 v1, in vec2 v2, in vec2 v3, in vec2 v4) {
    float s = 1.0;
    float d = dot(p - v1, p - v1);

    d = seg(p, v1, v2, s, d);
    d = seg(p, v2, v3, s, d);
    d = seg(p, v3, v4, s, d);
    d = seg(p, v4, v1, s, d);

    return s * sqrt(d);
}

// Normalizes coordinates
vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

// Antialiasing helper
float antialising(float distance, float blurAmount) {
  return 1. - smoothstep(0., normalize(vec2(blurAmount, blurAmount), 0.).x, distance);
}

// Determines animation duration based on a corner's alignment with the move direction(dot product)
// dot_val will be in [-2, 2]
// > 0.5 (1 or 2) = Leading
// > -0.5 (0)     = Side
// <= -0.5 (-1 or -2) = Trailing
float getDurationFromDot(float dot_val, float DURATION_LEAD, float DURATION_SIDE, float DURATION_TRAIL) {
    float isLead = step(0.5, dot_val);
    float isSide = step(-0.5, dot_val) * (1.0 - isLead);

    // Start with trailing duration
    float duration = mix(DURATION_TRAIL, DURATION_SIDE, isSide);
    // Mix in leading duration
    duration = mix(duration, DURATION_LEAD, isLead);
    return duration;
}

// --- 🖼️ MAIN IMAGE

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    // normalization & setup(-1, 1 coords)
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));
    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
    vec2 halfSizeCC = currentCursor.zw * 0.5;
    vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);
    vec2 halfSizeCP = previousCursor.zw * 0.5;

    vec4 newColor = vec4(fragColor);

    // --- 1. WARP TRAIL LOGIC ---
    float sdfCurrentCursor = getSdfRectangle(vu, centerCC, halfSizeCC);
    float lineLength = distance(centerCC, centerCP);
    float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE;
    float baseProgress = iTime - iTimeCursorChange;

    if (lineLength > minDist && baseProgress < WARP_DURATION - 0.001) {
        // defining corners of cursors

        // Y (Height) with TRAIL_THICKNESS
        float cc_half_height = currentCursor.w * 0.5;
        float cc_center_y = currentCursor.y - cc_half_height;
        float cc_new_half_height = cc_half_height * TRAIL_THICKNESS;
        float cc_new_top_y = cc_center_y + cc_new_half_height;
        float cc_new_bottom_y = cc_center_y - cc_new_half_height;

        // X (Width) with TRAIL_THICKNESS
        float cc_half_width = currentCursor.z * 0.5;
        float cc_center_x = currentCursor.x + cc_half_width;
        float cc_new_half_width = cc_half_width * TRAIL_THICKNESS_X;
        float cc_new_left_x = cc_center_x - cc_new_half_width;
        float cc_new_right_x = cc_center_x + cc_new_half_width;

        vec2 cc_tl = vec2(cc_new_left_x, cc_new_top_y);
        vec2 cc_tr = vec2(cc_new_right_x, cc_new_top_y);
        vec2 cc_bl = vec2(cc_new_left_x, cc_new_bottom_y);
        vec2 cc_br = vec2(cc_new_right_x, cc_new_bottom_y);
        // same thing for previous cursor
        float cp_half_height = previousCursor.w * 0.5;
        float cp_center_y = previousCursor.y - cp_half_height;
        float cp_new_half_height = cp_half_height * TRAIL_THICKNESS;
        float cp_new_top_y = cp_center_y + cp_new_half_height;
        float cp_new_bottom_y = cp_center_y - cp_new_half_height;

        float cp_half_width = previousCursor.z * 0.5;
        float cp_center_x = previousCursor.x + cp_half_width;
        float cp_new_half_width = cp_half_width * TRAIL_THICKNESS_X;
        float cp_new_left_x = cp_center_x - cp_new_half_width;
        float cp_new_right_x = cp_center_x + cp_new_half_width;
        vec2 cp_tl = vec2(cp_new_left_x, cp_new_top_y);
        vec2 cp_tr = vec2(cp_new_right_x, cp_new_top_y);
        vec2 cp_bl = vec2(cp_new_left_x, cp_new_bottom_y);
        vec2 cp_br = vec2(cp_new_right_x, cp_new_bottom_y);
        // calculating durations for every corner
        const float DURATION_TRAIL = WARP_DURATION;
        const float DURATION_LEAD = WARP_DURATION * (1.0 - TRAIL_SIZE);
        const float DURATION_SIDE = (DURATION_LEAD + DURATION_TRAIL) / 2.0;
        vec2 moveVec = centerCC - centerCP;
        vec2 s = sign(moveVec);
        // dot products for each corner, determining alignment with movement direction
        float dot_tl = dot(vec2(-1., 1.), s);
        float dot_tr = dot(vec2( 1., 1.), s);
        float dot_bl = dot(vec2(-1.,-1.), s);
        float dot_br = dot(vec2( 1.,-1.), s);
        // assign durations based on dot products
        float dur_tl = getDurationFromDot(dot_tl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_tr = getDurationFromDot(dot_tr, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_bl = getDurationFromDot(dot_bl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_br = getDurationFromDot(dot_br, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

        // check direction of horizontal movement
        float isMovingRight = step(0.5, s.x);
        float isMovingLeft  = step(0.5, -s.x);

        // calculate vertical-rail durations
        float dot_right_edge = (dot_tr + dot_br) * 0.5;
        float dur_right_rail = getDurationFromDot(dot_right_edge, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

        float dot_left_edge = (dot_tl + dot_bl) * 0.5;
        float dur_left_rail = getDurationFromDot(dot_left_edge, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

        float final_dur_tl = mix(dur_tl, dur_left_rail, isMovingLeft);
        float final_dur_bl = mix(dur_bl, dur_left_rail, isMovingLeft);
        float final_dur_tr = mix(dur_tr, dur_right_rail, isMovingRight);
        float final_dur_br = mix(dur_br, dur_right_rail, isMovingRight);

        // calculate progress for each corner based on the duration and time since cursor change
        // *** THIS NOW WORKS because `ease` is defined ***
        float prog_tl = ease(clamp(baseProgress / final_dur_tl, 0.0, 1.0));
        float prog_tr = ease(clamp(baseProgress / final_dur_tr, 0.0, 1.0));
        float prog_bl = ease(clamp(baseProgress / final_dur_bl, 0.0, 1.0));
        float prog_br = ease(clamp(baseProgress / final_dur_br, 0.0, 1.0));

        // get the trial corner positions based on progress
        vec2 v_tl = mix(cp_tl, cc_tl, prog_tl);
        vec2 v_tr = mix(cp_tr, cc_tr, prog_tr);
        vec2 v_br = mix(cp_br, cc_br, prog_br);
        vec2 v_bl = mix(cp_bl, cc_bl, prog_bl);
        // DRAWING THE TRAIL
        float sdfTrail = getSdfConvexQuad(vu, v_tl, v_tr, v_br, v_bl);
        // --- FADE GRADIENT CALCULATION ---
        vec2 fragVec = vu - centerCP;
        // project fragment onto movement vector, normalize to [0, 1]
        // 0.0 at tail, 1.0 at head
        // tiny epsilon to avoid division by zero if moveVec is (0,0)
        float fadeProgress = clamp(dot(fragVec, moveVec) / (dot(moveVec, moveVec) + 1e-6), 0.0, 1.0);
        vec4 trail = TRAIL_COLOR;

        float effectiveBlur = WARP_BLUR;
        if (WARP_BLUR < 2.5) {
          // no antialising on horizontal/vertical movement, fixes 'pulse' like thing on end cursor
          float isDiagonal = abs(s.x) * abs(s.y);
          // 1.0 if diagonal, 0.0 if H/V
          effectiveBlur = mix(0.0, WARP_BLUR, isDiagonal);
        }
        float shapeAlpha = antialising(sdfTrail, effectiveBlur);
        // shape mask

        if (FADE_ENABLED > 0.5) {
            // apply fade gradient along the trail
            float easedProgress = pow(fadeProgress, FADE_EXPONENT);
            trail.a *= easedProgress;
        }

        float finalAlpha = trail.a * shapeAlpha;
        // newColor.a to preserve the background alpha.
        newColor = mix(newColor, vec4(trail.rgb, newColor.a), finalAlpha);
        // punch hole on the trail, so current cursor is drawn on top
        newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.));
    }

    // --- 2. RIPPLE EFFECT LOGIC ---
    float cellWidth = max(currentCursor.z, previousCursor.z);
    // width of the 'block' cursor

    // check for significant width change
    float widthChange = abs(currentCursor.z - previousCursor.z);
    float widthThresholdNorm = cellWidth * CURSOR_WIDTH_CHANGE_THRESHOLD;
    float isModeChange = step(widthThresholdNorm, widthChange);

    // ANIMATION
    float rippleProgress = (iTime - iTimeCursorChange) / RIPPLE_DURATION + ANIMATION_START_OFFSET;
    // don't clamp yet;
    // we need to know if it's > 1.0 (finished)
     float isAnimating = 1.0 - step(1.0, rippleProgress);
     // progress < 1.0 ? 1.0: 0.0

     if (isModeChange > 0.0 && isAnimating > 0.0) {
        // Apply easing to progress
        // This correctly calls the function defined above
        float easedProgress = easeOutCirc(rippleProgress);

        // RIPPLE CALCULATION
        float rippleExpansion = easedProgress * MAX_SIZE;
        float fade = 1.0 - easeOutPulse(rippleProgress);

        vec2 rippleHalfSize = vec2(currentCursor.z, currentCursor.w) * 0.5 + vec2(rippleExpansion);
        float sdfRectRing = abs(getSdfRectangle(vu, centerCC, rippleHalfSize)) - RING_THICKNESS * 0.5;
        // Antialias (1-pixel width in normalized coords)
        float antiAliasSize = normalize(vec2(RIPPLE_BLUR, RIPPLE_BLUR), 0.0).x;
        float ripple = (1.0 - smoothstep(-antiAliasSize, antiAliasSize, sdfRectRing)) * fade;
        // Apply ripple effect
        newColor = mix(newColor, RIPPLE_COLOR, ripple * RIPPLE_COLOR.a);
     }

    // --- FINAL OUTPUT ---
    fragColor = newColor;
}
