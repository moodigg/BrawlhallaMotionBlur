# Brawlhalla Motion Blur

Clip-style motion blur for Brawlhalla, live in-game, as a ReShade shader.

It blends each frame into a running average measured in **milliseconds, not frames**, so the
blur looks the same at 800 fps in a match and at 60 fps in the lobby. Nothing is held back:
every refresh shows the newest frame plus fading trails. Visual delay is about half the blur
length (16 ms blur ≈ 8 ms).

Works best with an uncapped or high frame rate (well above your monitor's refresh rate),
because that gives it more frames to blend.

## Install

1. Install [ReShade](https://reshade.me) for `Brawlhalla.exe` (Steam: `steamapps\common\Brawlhalla`),
   rendering API **DirectX 10/11/12**. You can skip the shader packs; this shader needs none.
2. Copy `FrameBlendBlur.fx` into `Brawlhalla\reshade-shaders\Shaders\`.
3. Start the game, open the ReShade menu (default **Home**), and tick **Frame Blend Motion Blur**.
4. Optional: right-click the effect to set a toggle key.

## Settings

| Setting | What it does |
|---|---|
| Blur length (ms) | How much time each trail covers. 16.7 looks like a 60 fps clip with full blur. Lower is subtler, with less delay. |
| Blur strength | 0 = off, 1 = full blur. |
| Linear-light blending | On: bright trails stay bright (physically correct). Off: raw color blending, like most clip tools. |
| Debug: show frame-to-frame change | Shows what changed since the last frame. Steady outlines while moving mean every frame is unique. |

## Notes

- Brawlhalla has no anti-cheat today, and ReShade only changes what you see. Use it at your own risk.
- Blur adds a few milliseconds of visual delay. Lower the blur length if you notice it.
