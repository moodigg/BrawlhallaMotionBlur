// FrameBlendBlur.fx - clip-style motion blur, live in-game.
//
// Blends every rendered frame into a running average whose length is set in
// milliseconds, not frames. So the blur looks the same at 800fps in a match and
// at 60fps in the lobby (where low fps means there's barely anything to blend).
// Nothing is held back: each refresh shows the newest frame plus fading trails.
// Visual delay ~= half the blur length (16ms blur -> ~8ms).

// Self-contained (no ReShade.fxh needed)
texture FBB_BackBufferTex : COLOR;
sampler FBB_BackBuffer { Texture = FBB_BackBufferTex; };

void FBB_FullscreenVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

uniform int FrameCount < source = "framecount"; >;
uniform float FrameTime < source = "frametime"; >; // ms

uniform float BlurMs <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 50.0; ui_step = 0.5;
	ui_label = "Blur length (ms)";
	ui_tooltip = "How much time each frame's trail covers.\n16.7 = looks like a 60fps clip with full blur.\nLower = subtler + less visual delay.";
> = 16.7;

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Blur strength";
	ui_tooltip = "0 = no blur, 1 = full blur.";
> = 1.0;

uniform bool LinearBlend <
	ui_label = "Linear-light blending";
	ui_tooltip = "On = physically correct blur (bright trails stay bright).\nOff = blend raw colors, like most clip tools by default.";
> = true;

uniform bool DebugDiff <
	ui_label = "Debug: show frame-to-frame change";
	ui_tooltip = "Shows what changed since the previous frame.\nSteady outlines while moving = every frame is unique (good).\nHeavy flicker = the game repeats frames.";
> = false;

// Ping-pong accumulators: even frames write A (reading B), odd frames write B (reading A)
texture FBB_AccumA { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
texture FBB_AccumB { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler FBB_SampA { Texture = FBB_AccumA; };
sampler FBB_SampB { Texture = FBB_AccumB; };

// Raw previous frame, for the debug view
texture FBB_PrevA { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture FBB_PrevB { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler FBB_SampPrevA { Texture = FBB_PrevA; };
sampler FBB_SampPrevB { Texture = FBB_PrevB; };

float3 ToBlendSpace(float3 c)   { return LinearBlend ? pow(abs(c), 2.2) : c; }
float3 FromBlendSpace(float3 c) { return LinearBlend ? pow(abs(c), 1.0 / 2.2) : c; }

bool IsOdd() { return (FrameCount & 1) != 0; }

// Exponential average with time constant BlurMs / 2 (same average delay as a box of BlurMs)
float BlendWeight()
{
	float tau = max(BlurMs * 0.5, 0.01);
	return 1.0 - exp(-max(FrameTime, 0.0) / tau);
}

float4 Accumulate(float4 pos, sampler prevAccum)
{
	int2 p = int2(pos.xy);
	float3 current = ToBlendSpace(tex2Dfetch(FBB_BackBuffer, p).rgb);
	float3 history = tex2Dfetch(prevAccum, p).rgb;
	return float4(lerp(history, current, BlendWeight()), 1.0);
}

float4 PS_AccumA(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
	if (IsOdd()) discard;
	return Accumulate(pos, FBB_SampB);
}

float4 PS_AccumB(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
	if (!IsOdd()) discard;
	return Accumulate(pos, FBB_SampA);
}

float4 PS_Output(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
	int2 p = int2(pos.xy);
	float3 raw = tex2Dfetch(FBB_BackBuffer, p).rgb;

	if (DebugDiff)
	{
		float3 prev = IsOdd() ? tex2Dfetch(FBB_SampPrevA, p).rgb : tex2Dfetch(FBB_SampPrevB, p).rgb;
		return float4(saturate(abs(raw - prev) * 8.0), 1.0);
	}

	float3 accum = IsOdd() ? tex2Dfetch(FBB_SampB, p).rgb : tex2Dfetch(FBB_SampA, p).rgb;
	float3 blended = lerp(ToBlendSpace(raw), accum, Strength);
	return float4(FromBlendSpace(blended), 1.0);
}

// Save this frame's raw image for next frame's debug diff (output reads the other slot)
float4 PS_SavePrevA(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
	if (IsOdd() || !DebugDiff) discard;
	return tex2Dfetch(FBB_BackBuffer, int2(pos.xy));
}

float4 PS_SavePrevB(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
	if (!IsOdd() || !DebugDiff) discard;
	return tex2Dfetch(FBB_BackBuffer, int2(pos.xy));
}

technique FrameBlendBlur <
	ui_label = "Frame Blend Motion Blur";
	ui_tooltip = "Clip-style motion blur, time-based.\nRight-click the effect to set a toggle key.";
>
{
	pass AccumA { VertexShader = FBB_FullscreenVS; PixelShader = PS_AccumA; RenderTarget = FBB_AccumA; }
	pass AccumB { VertexShader = FBB_FullscreenVS; PixelShader = PS_AccumB; RenderTarget = FBB_AccumB; }
	pass SavePrevA { VertexShader = FBB_FullscreenVS; PixelShader = PS_SavePrevA; RenderTarget = FBB_PrevA; }
	pass SavePrevB { VertexShader = FBB_FullscreenVS; PixelShader = PS_SavePrevB; RenderTarget = FBB_PrevB; }
	pass Output { VertexShader = FBB_FullscreenVS; PixelShader = PS_Output; }
}
