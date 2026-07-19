// --- COMBINED SHADER: Cursor Warp + Circular Ripple ---

// --- 📜 CONFIGURATION

// --- Warp Config (from cursor_warp.glsl) ---
vec4 TRAIL_COLOR = iCurrentCursorColor; // [cite: 114]
const float WARP_DURATION = 0.2; // [cite: 115]
const float TRAIL_SIZE = 0.8; // [cite: 115]
const float THRESHOLD_MIN_DISTANCE = 1.5; // [cite: 116]
const float WARP_BLUR = 1.0; // [cite: 118]
const float TRAIL_THICKNESS = 1.0; // [cite: 119]
const float TRAIL_THICKNESS_X = 0.9; // [cite: 120]
const float FADE_ENABLED = 0.0; // [cite: 120]
const float FADE_EXPONENT = 5.0; // [cite: 121]

// --- Ripple Config (from ripple_cursor.glsl) ---
const float RIPPLE_DURATION = 0.15; // [cite: 203]
const float MAX_RADIUS = 0.05; // [cite: 203]
const float RING_THICKNESS = 0.02; // [cite: 204]
const float CURSOR_WIDTH_CHANGE_THRESHOLD = 0.5; // [cite: 205]
vec4 RIPPLE_COLOR = vec4(0.35, 0.36, 0.44, 1.0); // [cite: 207]
const float RIPPLE_BLUR = 3.0; // [cite: 208]
const float ANIMATION_START_OFFSET = 0.0; // [cite: 208]

// --- 🎢 EASING FUNCTIONS

// --- CONSTANTS for easing functions (from cursor_warp.glsl) ---
const float PI = 3.14159265359; // [cite: 122]
const float C1_BACK = 1.70158; // [cite: 122]
const float C2_BACK = C1_BACK * 1.525; //
const float C3_BACK = C1_BACK + 1.0; // [cite: 123]
const float C4_ELASTIC = (2.0 * PI) / 3.0; // [cite: 123]
const float C5_ELASTIC = (2.0 * PI) / 4.5; //
const float SPRING_STIFFNESS = 9.0; // [cite: 124]
const float SPRING_DAMPING = 0.9; // [cite: 124]

// --- Easing Function for Warp (from cursor_warp.glsl) ---
// This is called by the warp code [cite: 188]
float ease(float x) {
    return sqrt(1.0 - pow(x - 1.0, 2.0)); // [cite: 133]
}

// --- Easing Function Library (from ripple_cursor.glsl) ---
// These are called by the ripple code [cite: 241, 244]
float easeOutQuad(float t) {
    return 1.0 - (1.0 - t) * (1.0 - t); // [cite: 209]
}
float easeInOutQuad(float t) {
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0; // [cite: 210-211]
}
float easeOutCubic(float t) {
    return 1.0 - pow(1.0 - t, 3.0); // [cite: 212]
}
float easeOutQuart(float t) {
    return 1.0 - pow(1.0 - t, 4.0); // [cite: 213]
}
float easeOutQuint(float t) {
    return 1.0 - pow(1.0 - t, 5.0); // [cite: 214]
}
float easeOutExpo(float t) {
    return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t); // [cite: 215]
}
float easeOutCirc(float t) {
    return sqrt(1.0 - pow(t - 1.0, 2.0)); // [cite: 216]
}
float easeOutSine(float t) {
    return sin((t * 3.1415916) / 2.0); // [cite: 217]
}
float easeOutElastic(float t) {
    const float c4 = (2.0 * 3.1415916) / 3.0; // [cite: 218]
    return t == 0.0 ? 0.0 : t == 1.0 ? 1.0 : pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0; // [cite: 218-220]
}
float easeOutBounce(float t) {
    const float n1 = 7.5625; // [cite: 221]
    const float d1 = 2.75; // [cite: 221]
    if (t < 1.0 / d1) {
        return n1 * t * t; // [cite: 222]
    } else if (t < 2.0 / d1) {
        return n1 * (t -= 1.5 / d1) * t + 0.75; // [cite: 223]
    } else if (t < 2.5 / d1) {
        return n1 * (t -= 2.25 / d1) * t + 0.9375; // [cite: 224]
    } else {
        return n1 * (t -= 2.625 / d1) * t + 0.984375; // [cite: 225]
    }
}
float easeOutBack(float t) {
    const float c1 = 1.70158; // [cite: 226]
    const float c3 = c1 + 1.0; // [cite: 226]
    return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0); // [cite: 227]
}
float easeOutPulse(float t) {
    return t * (2.0 - t); // [cite: 228]
}
float exponentialDecayPulse(float t) {
    return exp(-3.0 * t) * sin(t * 3.1415916); // [cite: 229]
}

// --- 🛠️ HELPER FUNCTIONS

// (from cursor_warp.glsl)
float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b; // [cite: 143]
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); // [cite: 143]
}

// (from cursor_warp.glsl)
float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a; // [cite: 144]
    vec2 w = p - a; // [cite: 144]
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0); // [cite: 145]
    float segd = dot(p - proj, p - proj); // [cite: 145]
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y); // [cite: 146]
    float c1 = 1.0 - step(0.0, p.y - b.y); // [cite: 146]
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x); // [cite: 147]
    float allCond = c0 * c1 * c2; // [cite: 147]
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2); // [cite: 148]
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond)); // [cite: 148]
    s *= flip; //
    return d; // [cite: 149]
}

// (from cursor_warp.glsl)
float getSdfConvexQuad(in vec2 p, in vec2 v1, in vec2 v2, in vec2 v3, in vec2 v4) {
    float s = 1.0; // [cite: 150]
    float d = dot(p - v1, p - v1); // [cite: 150]

    d = seg(p, v1, v2, s, d); // [cite: 151]
    d = seg(p, v2, v3, s, d); // [cite: 151]
    d = seg(p, v3, v4, s, d); // [cite: 152]
    d = seg(p, v4, v1, s, d); // [cite: 152]

    return s * sqrt(d); // [cite: 153]
}

// (Common to both files, de-duplicated)
vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y; //
}

// (from cursor_warp.glsl)
float antialising(float distance, float blurAmount) {
  return 1. - smoothstep(0., normalize(vec2(blurAmount, blurAmount), 0.).x, distance); // [cite: 155]
}

// (from cursor_warp.glsl)
float getDurationFromDot(float dot_val, float DURATION_LEAD, float DURATION_SIDE, float DURATION_TRAIL) {
    float isLead = step(0.5, dot_val); // [cite: 156]
    float isSide = step(-0.5, dot_val) * (1.0 - isLead); // [cite: 156]

    float duration = mix(DURATION_TRAIL, DURATION_SIDE, isSide); // [cite: 157]
    duration = mix(duration, DURATION_LEAD, isLead); // [cite: 158]
    return duration; // [cite: 158]
}

// --- 🖼️ MAIN IMAGE

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy); // [cite: 159, 231]
    #endif

    // --- COMMON SETUP ---
    vec2 vu = normalize(fragCoord, 1.); // [cite: 160, 232]
    vec2 offsetFactor = vec2(-.5, 0.5); // [cite: 160, 232]

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.)); // [cite: 161, 233]
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.)); // [cite: 161, 233]
    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor); // [cite: 162, 233]
    vec2 halfSizeCC = currentCursor.zw * 0.5; // [cite: 162]
    vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor); // [cite: 162]
    vec2 halfSizeCP = previousCursor.zw * 0.5; // [cite: 162]

    vec4 newColor = vec4(fragColor); // [cite: 164]
    float baseProgress = iTime - iTimeCursorChange; // [cite: 164]

    // --- 1. RIPPLE EFFECT LOGIC (from ripple_cursor.glsl) ---
    float cellWidth = max(currentCursor.z, previousCursor.z); // [cite: 234]
    float widthChange = abs(currentCursor.z - previousCursor.z); // [cite: 235]
    float widthThresholdNorm = cellWidth * CURSOR_WIDTH_CHANGE_THRESHOLD; // [cite: 235]
    float isModeChange = step(widthThresholdNorm, widthChange); // [cite: 236]

    float rippleProgress = (iTime - iTimeCursorChange) / RIPPLE_DURATION + ANIMATION_START_OFFSET; // [cite: 237]
    float isAnimating = 1.0 - step(1.0, rippleProgress); // [cite: 238]

    if (isModeChange > 0.0 && isAnimating > 0.0) { // [cite: 239]
        float easedProgress = easeOutCirc(rippleProgress); // [cite: 241]
        float rippleRadius = easedProgress * MAX_RADIUS; // [cite: 242]
        float fade = 1.0 - easeOutPulse(rippleProgress); // [cite: 244]

        float dist = distance(vu, centerCC); // [cite: 245]
        float sdfRing = abs(dist - rippleRadius) - RING_THICKNESS * 0.5; // [cite: 245]

        float antiAliasSize = normalize(vec2(RIPPLE_BLUR, RIPPLE_BLUR), 0.0).x; // [cite: 247]
        float ripple = (1.0 - smoothstep(-antiAliasSize, antiAliasSize, sdfRing)) * fade; // [cite: 248]

        // Apply ripple effect TO NEWCOLOR
        newColor = mix(newColor, RIPPLE_COLOR, ripple * RIPPLE_COLOR.a); // [cite: 249]
    }

    // --- 2. WARP TRAIL LOGIC (from cursor_warp.glsl) ---
    float sdfCurrentCursor = getSdfRectangle(vu, centerCC, halfSizeCC); // [cite: 163]
    float lineLength = distance(centerCC, centerCP); // [cite: 163]
    float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE; // [cite: 163]

    if (lineLength > minDist && baseProgress < WARP_DURATION - 0.001) { // [cite: 165]
        // Y (Height) with TRAIL_THICKNESS
        float cc_half_height = currentCursor.w * 0.5; // [cite: 165]
        float cc_center_y = currentCursor.y - cc_half_height; // [cite: 166]
        float cc_new_half_height = cc_half_height * TRAIL_THICKNESS; //
        float cc_new_top_y = cc_center_y + cc_new_half_height; // [cite: 166]
        float cc_new_bottom_y = cc_center_y - cc_new_half_height; // [cite: 167]

        // X (Width) with TRAIL_THICKNESS
        float cc_half_width = currentCursor.z * 0.5; // [cite: 167]
        float cc_center_x = currentCursor.x + cc_half_width; // [cite: 168]
        float cc_new_half_width = cc_half_width * TRAIL_THICKNESS_X; //
        float cc_new_left_x = cc_center_x - cc_new_half_width; // [cite: 168]
        float cc_new_right_x = cc_center_x + cc_new_half_width; // [cite: 169]

        vec2 cc_tl = vec2(cc_new_left_x, cc_new_top_y); //
        vec2 cc_tr = vec2(cc_new_right_x, cc_new_top_y); // [cite: 169]
        vec2 cc_bl = vec2(cc_new_left_x, cc_new_bottom_y); // [cite: 170]
        vec2 cc_br = vec2(cc_new_right_x, cc_new_bottom_y); // [cite: 170]

        // same thing for previous cursor
        float cp_half_height = previousCursor.w * 0.5; // [cite: 171]
        float cp_center_y = previousCursor.y - cp_half_height; // [cite: 171]
        float cp_new_half_height = cp_half_height * TRAIL_THICKNESS; //
        float cp_new_top_y = cp_center_y + cp_new_half_height; // [cite: 172]
        float cp_new_bottom_y = cp_center_y - cp_new_half_height; // [cite: 173]

        float cp_half_width = previousCursor.z * 0.5; //
        float cp_center_x = previousCursor.x + cp_half_width; // [cite: 173]
        float cp_new_half_width = cp_half_width * TRAIL_THICKNESS_X; //
        float cp_new_left_x = cp_center_x - cp_new_half_width; // [cite: 174]
        float cp_new_right_x = cp_center_x + cp_new_half_width; // [cite: 174]
        vec2 cp_tl = vec2(cp_new_left_x, cp_new_top_y); // [cite: 175]
        vec2 cp_tr = vec2(cp_new_right_x, cp_new_top_y); //
        vec2 cp_bl = vec2(cp_new_left_x, cp_new_bottom_y); //
        vec2 cp_br = vec2(cp_new_right_x, cp_new_bottom_y); // [cite: 175]

        // calculating durations for every corner
        const float DURATION_TRAIL = WARP_DURATION; // [cite: 176]
        const float DURATION_LEAD = WARP_DURATION * (1.0 - TRAIL_SIZE); // [cite: 177]
        const float DURATION_SIDE = (DURATION_LEAD + DURATION_TRAIL) / 2.0; // [cite: 177]
        vec2 moveVec = centerCC - centerCP; // [cite: 178]
        vec2 s = sign(moveVec); // [cite: 178]

        float dot_tl = dot(vec2(-1., 1.), s); // [cite: 179]
        float dot_tr = dot(vec2( 1., 1.), s); // [cite: 179]
        float dot_bl = dot(vec2(-1.,-1.), s); // [cite: 180]
        float dot_br = dot(vec2( 1.,-1.), s); // [cite: 180]

        float dur_tl = getDurationFromDot(dot_tl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL); // [cite: 181]
        float dur_tr = getDurationFromDot(dot_tr, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL); // [cite: 181]
        float dur_bl = getDurationFromDot(dot_bl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL); // [cite: 182]
        float dur_br = getDurationFromDot(dot_br, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL); // [cite: 182]

        float isMovingRight = step(0.5, s.x); // [cite: 183]
        float isMovingLeft  = step(0.5, -s.x); // [cite: 183]

        float dot_right_edge = (dot_tr + dot_br) * 0.5; // [cite: 184]
        float dur_right_rail = getDurationFromDot(dot_right_edge, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL); // [cite: 184]
        float dot_left_edge = (dot_tl + dot_bl) * 0.5; // [cite: 185]
        float dur_left_rail = getDurationFromDot(dot_left_edge, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL); // [cite: 185]

        float final_dur_tl = mix(dur_tl, dur_left_rail, isMovingLeft); //
        float final_dur_bl = mix(dur_bl, dur_left_rail, isMovingLeft); // [cite: 186]
        float final_dur_tr = mix(dur_tr, dur_right_rail, isMovingRight); // [cite: 186]
        float final_dur_br = mix(dur_br, dur_right_rail, isMovingRight); // [cite: 187]

        float prog_tl = ease(clamp(baseProgress / final_dur_tl, 0.0, 1.0)); // [cite: 188]
        float prog_tr = ease(clamp(baseProgress / final_dur_tr, 0.0, 1.0)); // [cite: 188]
        float prog_bl = ease(clamp(baseProgress / final_dur_bl, 0.0, 1.0)); // [cite: 189]
        float prog_br = ease(clamp(baseProgress / final_dur_br, 0.0, 1.0)); // [cite: 189]

        vec2 v_tl = mix(cp_tl, cc_tl, prog_tl); // [cite: 190]
        vec2 v_tr = mix(cp_tr, cc_tr, prog_tr); // [cite: 190]
        vec2 v_br = mix(cp_br, cc_br, prog_br); //
        vec2 v_bl = mix(cp_bl, cc_bl, prog_bl); // [cite: 191]

        float sdfTrail = getSdfConvexQuad(vu, v_tl, v_tr, v_br, v_bl); // [cite: 191]

        vec2 fragVec = vu - centerCP; // [cite: 193]
        float fadeProgress = clamp(dot(fragVec, moveVec) / (dot(moveVec, moveVec) + 1e-6), 0.0, 1.0); // [cite: 194]
        vec4 trail = TRAIL_COLOR; // [cite: 194]

        float effectiveBlur = WARP_BLUR; // [cite: 195]
        if (WARP_BLUR < 2.5) { //
          float isDiagonal = abs(s.x) * abs(s.y); //
          effectiveBlur = mix(0.0, WARP_BLUR, isDiagonal); // [cite: 196] (FIXED from original)
        }
        float shapeAlpha = antialising(sdfTrail, effectiveBlur); // [cite: 197]

        if (FADE_ENABLED > 0.5) { // [cite: 198]
            float easedProgress = pow(fadeProgress, FADE_EXPONENT); // [cite: 199]
            trail.a *= easedProgress; //
        }

        float finalAlpha = trail.a * shapeAlpha; // [cite: 200]
        newColor = mix(newColor, vec4(trail.rgb, newColor.a), finalAlpha); // [cite: 201]

        // punch hole on the trail
        newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.)); //
    }

    // --- FINAL OUTPUT ---
    fragColor = newColor; //
}
