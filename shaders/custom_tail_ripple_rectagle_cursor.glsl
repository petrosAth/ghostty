// --- COMBINED SHADER: Cursor Tail + Ripple Rectangle ---

// --- 📜 CONFIGURATION

// --- Tail Config (from cursor_tail.glsl) ---
vec4 TRAIL_COLOR = iCurrentCursorColor; // [cite: 1]
const float TAIL_DURATION = 0.09; // in seconds [cite: 2]
const float MAX_TRAIL_LENGTH = 0.2; // [cite: 2]
const float THRESHOLD_MIN_DISTANCE = 1.5; // [cite: 3]
const float TAIL_BLUR = 2.0; // blur size in pixels (for antialiasing) [cite: 4]

// --- Ripple Config (from ripple_rectangle_cursor.glsl) ---
const float RIPPLE_DURATION = 0.15; // How long the ripple animates (seconds) [cite: 65]
const float MAX_SIZE = 0.05; // [cite: 66]
const float RING_THICKNESS = 0.02; // [cite: 67]
const float CURSOR_WIDTH_CHANGE_THRESHOLD = 0.5; // [cite: 68]
vec4 RIPPLE_COLOR = vec4(0.35, 0.36, 0.44, 1.0); // [cite: 69]
const float RIPPLE_BLUR = 1.0; // Blur level in pixels [cite: 70]
const float ANIMATION_START_OFFSET = 0.0; // [cite: 70]

// --- 🎢 EASING FUNCTIONS

// --- CONSTANTS for easing functions (from cursor_tail.glsl) ---
const float PI = 3.14159265359; // [cite: 5]
const float C1_BACK = 1.70158; // [cite: 5]
const float C2_BACK = C1_BACK * 1.525; // [cite: 5]
const float C3_BACK = C1_BACK + 1.0; // [cite: 5]
const float C4_ELASTIC = (2.0 * PI) / 3.0; // [cite: 6]
const float C5_ELASTIC = (2.0 * PI) / 4.5; // [cite: 6]
const float SPRING_STIFFNESS = 9.0; // [cite: 7]
const float SPRING_DAMPING = 0.9; // [cite: 7]

// --- Easing Function for Tail (from cursor_tail.glsl) ---
// This shader was configured to use EaseOutCirc
float ease(float x) {
    return sqrt(1.0 - pow(x - 1.0, 2.0)); // [cite: 16]
}

// --- Easing Function Library (from ripple_rectangle_cursor.glsl) ---
float easeOutQuad(float t) {
    return 1.0 - (1.0 - t) * (1.0 - t); // [cite: 71]
}
float easeInOutQuad(float t) {
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0; // [cite: 72, 73]
}
float easeOutCubic(float t) {
    return 1.0 - pow(1.0 - t, 3.0); // [cite: 74]
}
float easeOutQuart(float t) {
    return 1.0 - pow(1.0 - t, 4.0); // [cite: 75]
}
float easeOutQuint(float t) {
    return 1.0 - pow(1.0 - t, 5.0); // [cite: 76]
}
float easeOutExpo(float t) {
    return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t); // [cite: 77]
}
float easeOutCirc(float t) {
    return sqrt(1.0 - pow(t - 1.0, 2.0)); // [cite: 78]
}
float easeOutSine(float t) {
    return sin((t * 3.1415916) / 2.0); // [cite: 79]
}
float easeOutElastic(float t) {
    const float c4 = (2.0 * 3.1415916) / 3.0; // [cite: 80]
    return t == 0.0 ? 0.0 : t == 1.0 ? 1.0 : pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0; // [cite: 80, 81, 82]
}
float easeOutBounce(float t) {
    const float n1 = 7.5625; // [cite: 83]
    const float d1 = 2.75; // [cite: 83]
    if (t < 1.0 / d1) {
        return n1 * t * t; // [cite: 84]
    } else if (t < 2.0 / d1) {
        return n1 * (t -= 1.5 / d1) * t + 0.75; // [cite: 85]
    } else if (t < 2.5 / d1) {
        return n1 * (t -= 2.25 / d1) * t + 0.9375; // [cite: 86]
    } else {
        return n1 * (t -= 2.625 / d1) * t + 0.984375; // [cite: 87]
    }
}
float easeOutBack(float t) {
    const float c1 = 1.70158; // [cite: 88]
    const float c3 = c1 + 1.0; // [cite: 88]
    return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0); // [cite: 89]
}
// Pulse fade functions (from ripple_rectangle_cursor.glsl)
float easeOutPulse(float t) {
    return t * (2.0 - t); // [cite: 90]
}
float exponentialDecayPulse(float t) {
    return exp(-3.0 * t) * sin(t * 3.1415916); // [cite: 91]
}

// --- 🛠️ HELPER FUNCTIONS

// Normalizes coordinates (common to both files)
vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y; // [cite: 37, 92]
}

// SDF for a rectangle (common to both files)
float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b; // [cite: 25, 93]
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0); // [cite: 26, 93]
}

// Based on Inigo Quilez's 2D distance functions article (from cursor_tail.glsl)
float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a; // [cite: 27]
    vec2 w = p - a; // [cite: 27]
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0); // [cite: 28]
    float segd = dot(p - proj, p - proj); // [cite: 28]
    d = min(d, segd); // [cite: 28]

    float c0 = step(0.0, p.y - a.y); // [cite: 29]
    float c1 = 1.0 - step(0.0, p.y - b.y); // [cite: 29]
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x); // [cite: 30]
    float allCond = c0 * c1 * c2; // [cite: 30]
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2); // [cite: 31]
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond)); // [cite: 31]
    s *= flip; // [cite: 32]
    return d; // [cite: 32]
}

// SDF for a parallelogram (from cursor_tail.glsl)
float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0; // [cite: 33]
    float d = dot(p - v0, p - v0); // [cite: 33]

    d = seg(p, v0, v3, s, d); // [cite: 34]
    d = seg(p, v1, v0, s, d); // [cite: 34]
    d = seg(p, v2, v1, s, d); // [cite: 35]
    d = seg(p, v3, v2, s, d); // [cite: 35]

    return s * sqrt(d); // [cite: 36]
}

// Antialiasing helper (from cursor_tail.glsl)
float antialising(float distance) {
	return 1. - smoothstep(0., normalize(vec2(TAIL_BLUR, TAIL_BLUR), 0.).x, distance); // [cite: 38]
}

// (from cursor_tail.glsl)
float determineIfTopRightIsLeading(vec2 a, vec2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y); // [cite: 39]
    float condition2 = step(a.x, b.x) * step(b.y, a.y); // [cite: 40]
    return 1.0 - max(condition1, condition2); // [cite: 41]
}

// (from cursor_tail.glsl)
vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.)); // [cite: 42]
}

// --- 🖼️ MAIN IMAGE

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy); //
    #endif

    // --- COMMON SETUP ---
    vec2 vu = normalize(fragCoord, 1.); // [cite: 44, 95]
    vec2 offsetFactor = vec2(-.5, 0.5); // [cite: 44, 95]

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.)); // [cite: 45, 96]
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.)); // [cite: 45, 96]
    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor); // [cite: 45, 96]
    vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor); // [cite: 46]

    vec4 newColor = vec4(fragColor); // [cite: 47]

    // --- 1. CURSOR TAIL LOGIC (from cursor_tail.glsl) ---
    vec2 delta = centerCP - centerCC; // [cite: 46]
    float lineLength = length(delta); // [cite: 46]
    float sdfCurrentCursor = getSdfRectangle(vu, centerCC, currentCursor.zw * 0.5); // [cite: 47]

    float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE; // [cite: 48]
    float progress = clamp((iTime - iTimeCursorChange) / TAIL_DURATION, 0.0, 1.0); // [cite: 48]

    if (lineLength > minDist) { // [cite: 48]
        float head_eased = 0.0; // [cite: 49]
        float tail_eased = 0.0; // [cite: 49]
        float tail_delay_factor = MAX_TRAIL_LENGTH / lineLength; // [cite: 50]
        float isLongMove = step(MAX_TRAIL_LENGTH, lineLength); // [cite: 50]
        float head_eased_short = ease(progress); // [cite: 50]
        float tail_eased_short = ease(smoothstep(tail_delay_factor, 1.0, progress)); // [cite: 50]
        float head_eased_long = 1.0; // [cite: 51]
        float tail_eased_long = ease(progress); // [cite: 51]
        head_eased = mix(head_eased_long, head_eased_short, isLongMove); // [cite: 51]
        tail_eased = mix(tail_eased_long, tail_eased_short, isLongMove); // [cite: 51]

        // detect straight moves
        vec2 delta_abs = abs(centerCC - centerCP); // [cite: 52]
        float threshold = 0.001; // [cite: 52]
        float isHorizontal = step(delta_abs.y, threshold); // [cite: 52]
        float isVertical = step(delta_abs.x, threshold); // [cite: 52]
        float isStraightMove = max(isHorizontal, isVertical); // [cite: 53]

        // -- Making the parallelogram sdf (diagonal move) --
        vec2 head_pos_tl = mix(previousCursor.xy, currentCursor.xy, head_eased); // [cite: 54]
        vec2 tail_pos_tl = mix(previousCursor.xy, currentCursor.xy, tail_eased); // [cite: 54]
        float isTopRightLeading = determineIfTopRightIsLeading(currentCursor.xy, previousCursor.xy); // [cite: 55]
        float isBottomLeftLeading = 1.0 - isTopRightLeading; // [cite: 55]
        vec2 v0 = vec2(head_pos_tl.x + currentCursor.z * isTopRightLeading, head_pos_tl.y - currentCursor.w); // [cite: 56]
        vec2 v1 = vec2(head_pos_tl.x + currentCursor.z * isBottomLeftLeading, head_pos_tl.y); // [cite: 56]
        vec2 v2 = vec2(tail_pos_tl.x + currentCursor.z * isBottomLeftLeading, tail_pos_tl.y); // [cite: 57]
        vec2 v3 = vec2(tail_pos_tl.x + currentCursor.z * isTopRightLeading, tail_pos_tl.y - previousCursor.w); // [cite: 58]
        float sdfTrail_diag = getSdfParallelogram(vu, v0, v1, v2, v3); // [cite: 58]

        // -- Making the rectangle sdf (straight move) --
        vec2 head_center = mix(centerCP, centerCC, head_eased); // [cite: 59]
        vec2 tail_center = mix(centerCP, centerCC, tail_eased); // [cite: 59]
        vec2 min_center = min(head_center, tail_center); // [cite: 60]
        vec2 max_center = max(head_center, tail_center); // [cite: 60]
        vec2 box_size = (max_center - min_center) + currentCursor.zw; // [cite: 61]
        vec2 box_center = (min_center + max_center) * 0.5; // [cite: 61]
        float sdfTrail_rect = getSdfRectangle(vu, box_center, box_size * 0.5); // [cite: 61]

        // -- FINAL SELECTING AND DRAWING --
        float sdfTrail = mix(sdfTrail_diag, sdfTrail_rect, isStraightMove); // [cite: 62]
        vec4 trail = TRAIL_COLOR; // [cite: 62]
        float trailAlpha = antialising(sdfTrail); // [cite: 63]
        newColor = mix(newColor, trail, trailAlpha); // [cite: 63]

        // punch hole
        newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.)); //
    }

    // --- 2. RIPPLE EFFECT LOGIC (from ripple_rectangle_cursor.glsl) ---
    float cellWidth = max(currentCursor.z, previousCursor.z); // [cite: 97]

    // check for significant width change
    float widthChange = abs(currentCursor.z - previousCursor.z); // [cite: 98]
    float widthThresholdNorm = cellWidth * CURSOR_WIDTH_CHANGE_THRESHOLD; // [cite: 98]
    float isModeChange = step(widthThresholdNorm, widthChange); // [cite: 99]

    // ANIMATION
    float rippleProgress = (iTime - iTimeCursorChange) / RIPPLE_DURATION + ANIMATION_START_OFFSET; // [cite: 100]
    float isAnimating = 1.0 - step(1.0, rippleProgress); // [cite: 101]

    if (isModeChange > 0.0 && isAnimating > 0.0) { // [cite: 102]
        // Apply easing to progress
        float easedProgress = easeOutCirc(rippleProgress); // [cite: 104]

        // RIPPLE CALCULATION
        float rippleExpansion = easedProgress * MAX_SIZE; // [cite: 105]
        float fade = 1.0 - easeOutPulse(rippleProgress); // [cite: 107]

        vec2 halfSizeCC = vec2(currentCursor.z, currentCursor.w) * 0.5 + vec2(rippleExpansion); // [cite: 109]
        float sdfRectRing = abs(getSdfRectangle(vu, centerCC, halfSizeCC)) - RING_THICKNESS * 0.5; // [cite: 110]

        // Antialias
        float antiAliasSize = normalize(vec2(RIPPLE_BLUR, RIPPLE_BLUR), 0.0).x; // [cite: 111]
        float ripple = (1.0 - smoothstep(-antiAliasSize, antiAliasSize, sdfRectRing)) * fade; // [cite: 112]

        // Apply ripple effect *to the result of the tail shader*
        newColor = mix(newColor, RIPPLE_COLOR, ripple * RIPPLE_COLOR.a); // [cite: 113]
    }

    // --- FINAL OUTPUT ---
    fragColor = newColor; //
}
