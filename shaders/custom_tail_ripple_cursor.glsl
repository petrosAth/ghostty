// --- COMBINED SHADER: Cursor Tail + Circular Ripple ---

// --- 📜 CONFIGURATION

// --- Tail Config (from cursor_tail.glsl) ---
vec4 TRAIL_COLOR = iCurrentCursorColor; // [cite: 186]
const float TAIL_DURATION = 0.09; // in seconds [cite: 187]
const float MAX_TRAIL_LENGTH = 0.2; // [cite: 187]
const float THRESHOLD_MIN_DISTANCE = 1.5; // [cite: 187]
const float TAIL_BLUR = 2.0; // blur size in pixels [cite: 188]

// --- Ripple Config (from ripple_cursor.glsl) ---
const float RIPPLE_DURATION = 0.15; // How long the ripple animates (seconds) [cite: 90]
const float MAX_RADIUS = 0.05; // Max radius in normalized coords [cite: 90]
const float RING_THICKNESS = 0.02; // Ring width in normalized coords [cite: 91]
const float CURSOR_WIDTH_CHANGE_THRESHOLD = 0.5; // [cite: 92]
vec4 RIPPLE_COLOR = vec4(0.35, 0.36, 0.44, 1.0); // [cite: 93]
const float RIPPLE_BLUR = 3.0; // Blur level in pixels [cite: 94]
const float ANIMATION_START_OFFSET = 0.0; // [cite: 94]

// --- 🎢 EASING FUNCTIONS

// --- CONSTANTS for easing functions (from cursor_tail.glsl) ---
const float PI = 3.14159265359; // [cite: 189]
const float C1_BACK = 1.70158; // [cite: 190]
const float C2_BACK = C1_BACK * 1.525; // [cite: 190]
const float C3_BACK = C1_BACK + 1.0; // [cite: 190]
const float C4_ELASTIC = (2.0 * PI) / 3.0; // [cite: 191]
const float C5_ELASTIC = (2.0 * PI) / 4.5; // [cite: 191]
const float SPRING_STIFFNESS = 9.0; // [cite: 192]
const float SPRING_DAMPING = 0.9; // [cite: 192]

// --- Easing Function for Tail (from cursor_tail.glsl) ---
float ease(float x) {
    return sqrt(1.0 - pow(x - 1.0, 2.0)); // [cite: 201]
}

// --- Easing Function Library (from ripple_cursor.glsl) ---
float easeOutQuad(float t) { return 1.0 - (1.0 - t) * (1.0 - t); } // [cite: 96]
float easeInOutQuad(float t) { return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0; } // [cite: 97-98]
float easeOutCubic(float t) { return 1.0 - pow(1.0 - t, 3.0); } // [cite: 99]
float easeOutQuart(float t) { return 1.0 - pow(1.0 - t, 4.0); } // [cite: 100]
float easeOutQuint(float t) { return 1.0 - pow(1.0 - t, 5.0); } // [cite: 101]
float easeOutExpo(float t) { return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t); } // [cite: 102]
float easeOutCirc(float t) { return sqrt(1.0 - pow(t - 1.0, 2.0)); } // [cite: 103]
float easeOutSine(float t) { return sin((t * 3.1415916) / 2.0); } // [cite: 104]
float easeOutElastic(float t) { const float c4 = (2.0 * 3.1415916) / 3.0; return t == 0.0 ? 0.0 : t == 1.0 ? 1.0 : pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0; } // [cite: 105-107]
float easeOutBounce(float t) { const float n1 = 7.5625; const float d1 = 2.75; if (t < 1.0 / d1) { return n1 * t * t; } else if (t < 2.0 / d1) { return n1 * (t -= 1.5 / d1) * t + 0.75; } else if (t < 2.5 / d1) { return n1 * (t -= 2.25 / d1) * t + 0.9375; } else { return n1 * (t -= 2.625 / d1) * t + 0.984375; } } // [cite: 108-112]
float easeOutBack(float t) { const float c1 = 1.70158; const float c3 = c1 + 1.0; return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0); } // [cite: 113-114]
float easeOutPulse(float t) { return t * (2.0 - t); } // [cite: 115]
float exponentialDecayPulse(float t) { return exp(-3.0 * t) * sin(t * 3.1415916); } // [cite: 116]

// --- 🛠️ HELPER FUNCTIONS

// Normalizes coordinates (common to both files)
vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y; // [cite: 117, 222]
}

// SDF for a rectangle (from cursor_tail.glsl)
float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b; // [cite: 211]
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); // [cite: 211]
}

// (from cursor_tail.glsl)
float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a; // [cite: 212]
    vec2 w = p - a; // [cite: 212]
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0); // [cite: 213]
    float segd = dot(p - proj, p - proj); // [cite: 213]
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y); // [cite: 214]
    float c1 = 1.0 - step(0.0, p.y - b.y); // [cite: 214]
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x); // [cite: 215]
    float allCond = c0 * c1 * c2; // [cite: 215]
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2); // [cite: 216]
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond)); // [cite: 216]
    s *= flip; // [cite: 217]
    return d; // [cite: 217]
}

// (from cursor_tail.glsl)
float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0; // [cite: 218]
    float d = dot(p - v0, p - v0); // [cite: 218]

    d = seg(p, v0, v3, s, d); // [cite: 219]
    d = seg(p, v1, v0, s, d); // [cite: 219]
    d = seg(p, v2, v1, s, d); // [cite: 220]
    d = seg(p, v3, v2, s, d); // [cite: 220]

    return s * sqrt(d); // [cite: 221]
}

// Antialiasing helper (from cursor_tail.glsl, renamed)
float tail_antialiasing(float distance) {
	return 1. - smoothstep(0., normalize(vec2(TAIL_BLUR, TAIL_BLUR), 0.).x, distance); //
}

// (from cursor_tail.glsl)
float determineIfTopRightIsLeading(vec2 a, vec2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y); // [cite: 224]
    float condition2 = step(a.x, b.x) * step(b.y, a.y); // [cite: 225]
    return 1.0 - max(condition1, condition2); // [cite: 226]
}

// (from cursor_tail.glsl)
vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.)); // [cite: 227]
}

// --- 🖼️ MAIN IMAGE

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy); // [cite: 118, 228]
    #endif

    // --- COMMON SETUP ---
    vec2 vu = normalize(fragCoord, 1.); // [cite: 119, 229]
    vec2 offsetFactor = vec2(-.5, 0.5); // [cite: 119, 229]

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.)); // [cite: 120, 230]
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.)); // [cite: 120, 230]
    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor); // [cite: 120, 230]
    vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor); // [cite: 231]

    vec4 newColor = vec4(fragColor); // Start with original texture [cite: 232]

    // --- 1. RIPPLE EFFECT LOGIC (from ripple_cursor.glsl) ---
    float cellWidth = max(currentCursor.z, previousCursor.z); // [cite: 121]
    float widthChange = abs(currentCursor.z - previousCursor.z); // [cite: 122]
    float widthThresholdNorm = cellWidth * CURSOR_WIDTH_CHANGE_THRESHOLD; // [cite: 122]
    float isModeChange = step(widthThresholdNorm, widthChange); // [cite: 123]

    float rippleProgress = (iTime - iTimeCursorChange) / RIPPLE_DURATION + ANIMATION_START_OFFSET; // [cite: 124]
    float isAnimating = 1.0 - step(1.0, rippleProgress); // [cite: 125]

    if (isModeChange > 0.0 && isAnimating > 0.0) { // [cite: 125]
        float easedProgress = easeOutCirc(rippleProgress); // [cite: 128]
        float rippleRadius = easedProgress * MAX_RADIUS; // [cite: 129]
        float fade = 1.0 - easeOutPulse(rippleProgress); // [cite: 131]

        float dist = distance(vu, centerCC); // [cite: 132]
        float sdfRing = abs(dist - rippleRadius) - RING_THICKNESS * 0.5; // [cite: 133]

        float antiAliasSize = normalize(vec2(RIPPLE_BLUR, RIPPLE_BLUR), 0.0).x; // [cite: 134]
        float ripple = (1.0 - smoothstep(-antiAliasSize, antiAliasSize, sdfRing)) * fade; // [cite: 135]

        // Apply ripple effect to newColor
        newColor = mix(newColor, RIPPLE_COLOR, ripple * RIPPLE_COLOR.a); // [cite: 136]
    }

    // --- 2. CURSOR TAIL LOGIC (from cursor_tail.glsl) ---
    vec2 delta = centerCP - centerCC; // [cite: 231]
    float lineLength = length(delta); // [cite: 231]
    float sdfCurrentCursor = getSdfRectangle(vu, centerCC, currentCursor.zw * 0.5); // [cite: 232]
    float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE; // [cite: 233]
    float tail_progress = clamp((iTime - iTimeCursorChange) / TAIL_DURATION, 0.0, 1.0); // [cite: 233]

    if (lineLength > minDist) { // [cite: 233]
        float head_eased = 0.0; // [cite: 234]
        float tail_eased = 0.0; // [cite: 234]
        float tail_delay_factor = MAX_TRAIL_LENGTH / lineLength; // [cite: 234]
        float isLongMove = step(MAX_TRAIL_LENGTH, lineLength); // [cite: 235]
        float head_eased_short = ease(tail_progress); // [cite: 235]
        float tail_eased_short = ease(smoothstep(tail_delay_factor, 1.0, tail_progress)); // [cite: 235]
        float head_eased_long = 1.0; // [cite: 236]
        float tail_eased_long = ease(tail_progress); // [cite: 236]
        head_eased = mix(head_eased_long, head_eased_short, isLongMove); // [cite: 236]
        tail_eased = mix(tail_eased_long, tail_eased_short, isLongMove); // [cite: 236]

        vec2 delta_abs = abs(centerCC - centerCP); // [cite: 237]
        float threshold = 0.001; // [cite: 237]
        float isHorizontal = step(delta_abs.y, threshold); // [cite: 238]
        float isVertical = step(delta_abs.x, threshold); // [cite: 238]
        float isStraightMove = max(isHorizontal, isVertical); // [cite: 238]

        vec2 head_pos_tl = mix(previousCursor.xy, currentCursor.xy, head_eased); // [cite: 239]
        vec2 tail_pos_tl = mix(previousCursor.xy, currentCursor.xy, tail_eased); // [cite: 239]
        float isTopRightLeading = determineIfTopRightIsLeading(currentCursor.xy, previousCursor.xy); // [cite: 240]
        float isBottomLeftLeading = 1.0 - isTopRightLeading; // [cite: 240]
        vec2 v0 = vec2(head_pos_tl.x + currentCursor.z * isTopRightLeading, head_pos_tl.y - currentCursor.w); // [cite: 241]
        vec2 v1 = vec2(head_pos_tl.x + currentCursor.z * isBottomLeftLeading, head_pos_tl.y); // [cite: 241]
        vec2 v2 = vec2(tail_pos_tl.x + currentCursor.z * isBottomLeftLeading, tail_pos_tl.y); // [cite: 242]
        vec2 v3 = vec2(tail_pos_tl.x + currentCursor.z * isTopRightLeading, tail_pos_tl.y - previousCursor.w); // [cite: 242]
        float sdfTrail_diag = getSdfParallelogram(vu, v0, v1, v2, v3); // [cite: 243]

        vec2 head_center = mix(centerCP, centerCC, head_eased); // [cite: 244]
        vec2 tail_center = mix(centerCP, centerCC, tail_eased); // [cite: 244]
        vec2 min_center = min(head_center, tail_center); // [cite: 245]
        vec2 max_center = max(head_center, tail_center); // [cite: 245]
        vec2 box_size = (max_center - min_center) + currentCursor.zw; // [cite: 245]
        vec2 box_center = (min_center + max_center) * 0.5; // [cite: 246]
        float sdfTrail_rect = getSdfRectangle(vu, box_center, box_size * 0.5); // [cite: 246]

        float sdfTrail = mix(sdfTrail_diag, sdfTrail_rect, isStraightMove); // [cite: 247]
        vec4 trail = TRAIL_COLOR; // [cite: 247]
        float trailAlpha = tail_antialiasing(sdfTrail); // [cite: 248]

        // Apply tail effect *on top of* the ripple
        newColor = mix(newColor, trail, trailAlpha); // [cite: 248]

        // Punch hole through all effects back to original fragColor
        newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.)); //
    }

    // --- FINAL OUTPUT ---
    fragColor = newColor; //
}
