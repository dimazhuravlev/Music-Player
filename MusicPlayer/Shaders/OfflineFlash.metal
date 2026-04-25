// OfflineFlash.metal
// coverProgress 0→1: фон + 7 цветных блобов, волна, белый боковой ореол (две полосы снизу вверх / при exit сверху вниз); exit — затемнение.
// Расстояния — через uvAspectDelta(size): круги/кляксы визуально круглые на экране, без вытяжения по Y в UV.
// Цветные: 7 шт.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Смещение в координатах, где по X и Y одинаковый масштаб в пикселях (круг в UV на портрете выглядел бы вытянутым по Y).
static float2 uvAspectDelta(float2 uv, float2 center, float2 viewSize) {
    float ax = viewSize.x / max(viewSize.y, 1.0f);
    return float2((uv.x - center.x) * ax, uv.y - center.y);
}

static float blobFalloff(float2 uv, float2 center, float radius, float2 viewSize) {
    float d = length(uvAspectDelta(uv, center, viewSize));
    // Выше показатель — уже «корпус» блоба, меньше размытый ореол (только цветные слои; фон — bgSplatFalloff).
    return exp(-pow(d / max(radius, 1e-4f), 3.92f));
}

/// Фоновая «клякса»: радиус зависит от угла — неровный размытый контур, не идеальный круг.
static float bgSplatFalloff(float2 uv, float2 center, float baseR, float phase, float2 viewSize) {
    float2 dxy = uvAspectDelta(uv, center, viewSize);
    float d = length(dxy);
    float ang = atan2(dxy.y, dxy.x);
    float wobble = 0.14f * sin(ang * 5.0f + phase * 2.7f)
                 + 0.095f * sin(ang * 9.0f - phase * 1.55f)
                 + 0.058f * sin(ang * 14.0f + phase * 0.85f)
                 + 0.034f * sin(ang * 19.0f - phase * 2.05f);
    float rEff = baseR * (1.0f + wobble);
    rEff = max(rEff, 0.09f);
    float k = 3.05f;
    return exp(-pow(d / rEff, k));
}

/// Локальная фаза 0…1 после микрозадержки старта: к c=1 все блобы уже уехали.
static float staggerPhase(float c, float delay) {
    delay = clamp(delay, 0.0f, 0.92f);
    return clamp((c - delay) / max(1e-4f, 1.0f - delay), 0.0f, 1.0f);
}

/// Псевдослучай 0…1 от целочисленной сетки (стабильный «зерно» по пикселям).
static float hash01(float2 p) {
    return fract(sin(dot(p, float2(127.1f, 311.7f))) * 43758.5453123f);
}

/// Мелкое зерно по экранным координатам; t слегка двигает паттерн.
/// Одна крупная сетка даёт полный размах 0…1 (заметное зерно); вторая мельче — ломает полосы от floor.
static float surfaceGrain(float2 screenPx, float t) {
    const float scale = 1.85f;
    float2 q = screenPx * scale + float2(t * 19.0f, t * 27.0f);
    float2 cell = floor(q);
    float coarse = hash01(cell);
    float fine = hash01(floor(q * 2.65f + float2(11.0f, 5.0f)));
    return coarse * 0.78f + fine * 0.22f;
}

static float3 blobColorAt(int k,
    float3 c0, float3 c1, float3 c2, float3 c3, float3 c4, float3 c5, float3 c6
) {
    if (k <= 0) return c0;
    if (k == 1) return c1;
    if (k == 2) return c2;
    if (k == 3) return c3;
    if (k == 4) return c4;
    if (k == 5) return c5;
    return c6;
}

[[ stitchable ]] half4 offlineFlash(
    float2 position,
    half4  currentColor,
    float2 size,
    float  coverProgress,
    float  exitProgress,
    float  waveProgress,
    float  waveProgressB,
    float  reversed,
    float  cs0,
    float  cs1,
    float  cs2,
    float  cs3,
    float  cs4,
    float  cs5,
    float  cs6,
    float  br0,
    float  br1,
    float  br2,
    float  br3,
    float  br4,
    float  br5,
    float  br6,
    float  coloredBlobsOpacity,
    float  redirectCoverProgress
) {
    (void)waveProgress;
    (void)waveProgressB;
    (void)redirectCoverProgress;
    float2 uv = position / size;
    if (reversed > 0.5f) {
        uv.y = 1.0f - uv.y;
    }

    float c = clamp(coverProgress, 0.0f, 1.0f);
    float e = clamp(exitProgress,  0.0f, 1.0f);
    float exitFade = 1.0f - e;
    // Семь цветных блобов (не фоновый): чуть приглушаем относительно переданного `coloredBlobsOpacity`.
    const float colorBlobsOpacityScale = 0.85f;
    float colorBlobOp = clamp(coloredBlobsOpacity * colorBlobsOpacityScale, 0.0f, 1.0f);

    const float kStep = 0.58f;
    // Общая дистанция «поезда»; разброс speed + stagger даёт разную скорость и порядок старта.
    const float moveSpan = 5.05f;

    float3 cBg   = float3(163.0f / 255.0f, 50.0f / 255.0f, 1.0f);
    // Семь разных оттенков (раньше пары делили один цвет — визуально «2–3 блоба»).
    float3 cBlob0 = float3(87.0f / 255.0f, 0.0f, 181.0f / 255.0f);   // #5700B5
    float3 cBlob1 = float3(120.0f / 255.0f, 40.0f / 255.0f, 210.0f / 255.0f); // сине-фиолетовый
    float3 cBlob2 = float3(167.0f / 255.0f, 0.0f, 186.0f / 255.0f);   // #A700BA
    float3 cBlob3 = float3(210.0f / 255.0f, 30.0f / 255.0f, 160.0f / 255.0f); // розово-маджента
    float3 cBlob4 = float3(233.0f / 255.0f, 0.0f, 31.0f / 255.0f);    // #E9001F
    float3 cBlob5 = float3(255.0f / 255.0f, 70.0f / 255.0f, 95.0f / 255.0f);  // коралл
    float3 cBlob6 = float3(1.0f, 106.0f / 255.0f, 0.0f);             // #FF6A00
    float3 white = float3(1.0f, 1.0f, 1.0f);

    // Без чёрной подложки: незакрытые пиксели — alpha 0 (виден экран под оверлеем).
    float3 col = float3(0.0f, 0.0f, 0.0f);
    float flashMask = 0.0f;

    float driftX = 0.02f * sin(c * 6.2831853f * 0.5f);

    // Фоновый блоб: центр при c=0 глубоко под кадром (y≫1), иначе виден «обрезанный» край у нижней кромки.
    float cBgPh = staggerPhase(c, 0.015f);
    float bgMove = cBgPh * moveSpan;
    float bgAnchorY = 2.58f;
    float2 bgCenter = float2(0.50f + driftX * 0.3f, bgAnchorY - bgMove * 0.88f);
    // Крупный базовый радиус: когда центр у середины кадра, клякса перекрывает весь экран; фаза слегка крутит неровности.
    float bgR = 1.22f;
    float splatPhase = c * 5.5f + cBgPh * 1.8f;

    float bgMask = bgSplatFalloff(uv, bgCenter, bgR, splatPhase, size);
    // Гаусс почти никогда не даёт bgMask==1 — без буста alpha оверлея <1 и просвечивает UI. Нижний фон: непрозрачное перекрытие в «теле» блоба.
    // Важно: при смене `bgAnchorY` / `bgR` / stagger подправь `offlineFlashRedirectCoverProgress` в MusicApp (редирект под оверлеем).
    float bgSolid = smoothstep(0.05f, 0.38f, bgMask);
    col = mix(col, cBg, bgSolid);
    flashMask = max(flashMask, bgSolid);

    struct B {
        float2 base;
        float  opacity;
        float  speed;
        float  driftX;
        float  delay;
    };

    float colorSlot[7] = { cs0, cs1, cs2, cs3, cs4, cs5, cs6 };
    float blobR[7] = { br0, br1, br2, br3, br4, br5, br6 };

    // base.y: шаг ~0.22; минимум ~1.52 — при max r из Swift и c=0 масса гаусса ещё под экраном (нет резкого края у y=1).
    // bi.speed — множитель вертикальной скорости только у цветных слоёв (фоновый блоб выше, не в B). Диапазон ~0.82…1.18.
    B b0 = { float2(0.10f, 1.52f), 1.00f, 0.86f, -0.006f, 0.00f };
    B b1 = { float2(0.90f, 1.74f), 1.00f, 1.14f,  0.007f, 0.008f };
    B b2 = { float2(0.50f, 1.96f), 1.00f, 0.92f,  0.004f, 0.016f };
    B b3 = { float2(0.23f, 2.18f), 1.00f, 1.18f, -0.005f, 0.024f };
    B b4 = { float2(0.77f, 2.40f), 1.00f, 0.82f,  0.006f, 0.032f };
    B b5 = { float2(0.36f, 2.62f), 1.00f, 1.10f, -0.004f, 0.040f };
    B b6 = { float2(0.64f, 2.84f), 1.00f, 1.00f,  0.005f, 0.048f };

    B blobs[7] = { b0, b1, b2, b3, b4, b5, b6 };

    for (int i = 0; i < 7; i++) {
        B bi = blobs[i];
        int pk = clamp(int(floor(colorSlot[i] + 0.5f)), 0, 6);
        float3 biCol = blobColorAt(pk, cBlob0, cBlob1, cBlob2, cBlob3, cBlob4, cBlob5, cBlob6);
        float ci = staggerPhase(c, bi.delay);
        float move = ci * moveSpan;
        float y = bi.base.y - move * kStep * bi.speed;
        float x = bi.base.x + c * bi.driftX + driftX;
        float m = blobFalloff(uv, float2(x, y), blobR[i], size);
        float layerA = m * bi.opacity * colorBlobOp;
        col = mix(col, biCol, layerA);
        flashMask = max(flashMask, layerA);
    }

    // Белая волна: широкая размытая вспышка. Вход — снизу вверх; выход — сверху вниз; uy0 — неперевёрнутый Y.
    // Меньше waveSpeedMult — медленнее проход волны по c (полный ход позже, чем при 2.0).
    const float waveDelay = 0.30f;
    const float waveMid = 0.5f;
    const float waveSpeedMult = 1.65f;
    float cProg = c;
    float waveSpan = 2.0f * max(waveMid - waveDelay, 0.01f);
    float waveT = clamp((cProg - waveDelay) * waveSpeedMult / waveSpan, 0.0f, 1.0f);
    float waveY = (reversed > 0.5f)
        ? mix(-0.52f, 1.88f, waveT)
        : mix(1.88f, -0.52f, waveT);
    const float arcDepth = 0.11f;
    float arcSign = (reversed > 0.5f) ? -1.0f : 1.0f;
    float uy0 = (reversed > 0.5f) ? (1.0f - uv.y) : uv.y;
    float xn = uv.x - 0.50f;
    float yLine = waveY + arcSign * arcDepth * xn * xn;
    float d = abs(uy0 - yLine);
    const float sigmaCore = 0.095f;
    const float sigmaHalo = 0.24f;
    float gCore = exp(-(d / sigmaCore) * (d / sigmaCore) * 0.82f);
    float gHalo = exp(-(d / sigmaHalo) * (d / sigmaHalo) * 1.05f);
    float gOuter = exp(-(d / (sigmaHalo * 1.22f)) * (d / (sigmaHalo * 1.22f)) * 0.7f);
    float band = min(1.0f, gCore * 0.62f + gHalo * 0.42f + gOuter * 0.28f);
    float waveOp = 0.52f;
    float waveGate = smoothstep(waveDelay, waveDelay + 0.12f, cProg);
    float waveA = band * waveOp * waveGate;
    col = mix(col, white, waveA);
    flashMask = max(flashMask, waveA);

    // Белый ореол только по левой и правой стороне: две «змейки» синхронно; вход — снизу вверх, выход (reversed) — сверху вниз.
    // Фаза по вертикали — в 2× быстрее cover (fill = min(1, 2c)). Широкое размытие у кромки (core+halo+outer).
    float pxR = uv.x;
    float pyR = (reversed > 0.5f) ? (1.0f - uv.y) : uv.y;
    // Ореол в 2× быстрее по фазе cover (полный ход при c ≈ 0.5).
    float fill = min(1.0f, c * 2.0f);
    const float rimHeadW = 0.092f;
    float snakeV;
    if (reversed > 0.5f) {
        snakeV = 1.0f - smoothstep(fill - rimHeadW, fill + rimHeadW * 0.55f, pyR);
    } else {
        snakeV = smoothstep(1.0f - fill - rimHeadW, 1.0f - fill + rimHeadW * 0.55f, pyR);
    }
    // Полоса у края: большие σ — мягче размытие вглубь экрана (шире ореол).
    const float rimWCore = 0.034f;
    const float rimWHalo = 0.082f;
    const float rimWOuter = 0.128f;
    float dL = pxR;
    float dR = 1.0f - pxR;
    float gLC = exp(-(dL / rimWCore) * (dL / rimWCore) * 0.78f);
    float gLH = exp(-(dL / rimWHalo) * (dL / rimWHalo) * 0.34f);
    float gLO = exp(-(dL / rimWOuter) * (dL / rimWOuter) * 0.22f);
    float gL = min(1.0f, gLC * 0.52f + gLH * 0.48f + gLO * 0.38f);
    float gRC = exp(-(dR / rimWCore) * (dR / rimWCore) * 0.78f);
    float gRH = exp(-(dR / rimWHalo) * (dR / rimWHalo) * 0.34f);
    float gRO = exp(-(dR / rimWOuter) * (dR / rimWOuter) * 0.22f);
    float gR = min(1.0f, gRC * 0.52f + gRH * 0.48f + gRO * 0.38f);
    float rimGeo = max(gL, gR) * snakeV;
    float rimFadeIn = smoothstep(0.0f, 0.22f, c);
    float rimFadeOut = 1.0f - smoothstep(0.66f, 1.0f, c);
    float rimOpacity = rimFadeIn * rimFadeOut;
    const float rimOp = 0.40f;
    float rimA = rimGeo * rimOpacity * rimOp;
    col = mix(col, white, rimA);
    flashMask = max(flashMask, rimA);

    flashMask = clamp(flashMask, 0.0f, 1.0f);

    // Светлое зерно: только осветление (bipolar давал тёмные «ямки» и выглядел мутным).
    float grain01 = surfaceGrain(position, c);
    const float grainStrength = 0.09f;
    float3 grainTint = float3(1.0f, 0.99f, 0.965f);
    float g = pow(grain01, 1.2f);
    col = col + grainTint * g * grainStrength * flashMask;
    col = clamp(col, 0.0f, 1.0f);

    // col — как при композите на чёрном; premul rgb = col·exitFade, alpha = flashMask·exitFade (без второго умножения rgb на flashMask).
    float aOut = exitFade * flashMask;
    return half4(half3(col) * half(exitFade), half(aOut));
}

/// Зерно с мультипликативной модуляцией (`grainMulLo`/`grainMulHi`): паттерн читается даже на ярком сплошном fill.
[[ stitchable ]] half4 grainOverlay(
    float2 position,
    half4 currentColor,
    float2 size,
    float coverProgress
) {
    (void)size;
    float c = clamp(coverProgress, 0.0f, 1.0f);
    float grain01 = surfaceGrain(position, c);
    float g = pow(grain01, 1.2f);
    const float grainStrength = 0.09f;
    float3 grainTint = float3(1.0f, 0.99f, 0.965f);
    half3 rgb = half3(currentColor.rgb) + half3(grainTint) * half(g * grainStrength);
    const float grainMulLo = 0.94f;
    const float grainMulHi = 1.06f;
    float m = mix(grainMulLo, grainMulHi, g);
    rgb = rgb * half(m);
    rgb = clamp(rgb, half3(0.0f), half3(1.0f));
    return half4(rgb, currentColor.a);
}

/// Soft-вариант: только additive, без мультипликативной ветки. Для оверлеев на фото/UI без лишнего затемнения.
[[ stitchable ]] half4 grainOverlaySoft(
    float2 position,
    half4 currentColor,
    float2 size,
    float coverProgress
) {
    (void)size;
    float c = clamp(coverProgress, 0.0f, 1.0f);
    float grain01 = surfaceGrain(position, c);
    // Чуть мягче гамма, чем у полного зерна (1.2), чтобы при screen-смешении зерно читалось сильнее.
    float g = pow(grain01, 1.05f);
    const float grainStrength = 0.14f;
    float3 grainTint = float3(1.0f, 0.99f, 0.965f);
    half3 rgb = half3(currentColor.rgb) + half3(grainTint) * half(g * grainStrength);
    rgb = clamp(rgb, half3(0.0f), half3(1.0f));
    return half4(rgb, currentColor.a);
}
