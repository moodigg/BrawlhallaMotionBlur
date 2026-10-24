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

- My launch options helped a lot: with them I get a stable **800 fps** on a mid-range PC, which
  gives the blur plenty of frames to blend. Set them in Steam: right-click Brawlhalla →
  Properties → Launch Options.

  ```
  latencytest -unlockfps -dx9 -force64 -forceservice -high -64bit -framefix -framefixunbounded -novid -tickrate 128 -high +fps_max 0 +cl_showfps 0 +cl_interp 0 +cl_interp_ratio 1 +rate 128000 +cl_updaterate 128 +cl_cmdrate 128 +mat_queue_mo -triplebuffer
  ```
- Blur adds a few milliseconds of visual delay. Lower the blur length if you notice it.
