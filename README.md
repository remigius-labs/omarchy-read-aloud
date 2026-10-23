# Read Aloud: Text to Speech

Text to speech (TTS) for the [Omarchy](https://omarchy.org) bar. Read aloud any text you copy with a local AI voice ([Kokoro](https://huggingface.co/hexgrad/Kokoro-82M)). 54 voices, 9 languages, works offline after setup. Helps with dyslexia and long reads.

Powered by Kokoro: [GitHub](https://github.com/hexgrad/kokoro) · [🤗 Hugging Face](https://huggingface.co/hexgrad/Kokoro-82M)

![Read Aloud](preview.png)

## Controls

- **Left-click** the speech bubble: read the clipboard. Click again to stop.
- **Right-click**: pick a voice, switch male or female, and open Settings for speed, language and keys.
- While a voice is getting ready, the icon turns into a spinning ring. While it reads, it shows a stop square.

Picking a voice plays a short sample. Choices are saved and apply to every read.

## Keybind

Add a toggle to `~/.config/hypr/bindings.lua`. **Copy the shortcut setup** in Settings (right-click the bubble) copies these lines for you. They fire on a tap of AltGr + Right Ctrl:

```lua
o.bind("CTRL + ALT + Control_R", "Read clipboard aloud / stop", '$HOME/.local/share/omarchy-say/say --clip', { release = true })
o.bind("CTRL + ALT + Alt_R", "Read clipboard aloud / stop", '$HOME/.local/share/omarchy-say/say --clip', { release = true })
```

## First run

The first click sets up the voice by itself: Python 3.12 and the Kokoro engine through `uv`, then the 350 MB voice model, checked against fixed SHA-256 hashes. A progress bar shows in the panel, and it says "Voice ready" when done. Everything lands in `~/.local/share/omarchy-say/`.

Needs PipeWire (`pw-play`) and wl-clipboard (`wl-paste`), which Omarchy ships, and `uv`, which some installs lack. Check with `command -v uv`, add it with `omarchy pkg add uv`.

## Install

```bash
omarchy plugin add https://github.com/remigius-labs/omarchy-read-aloud --enable
```

The icon shows in the bar after the shell reloads: `omarchy restart shell`, or log out and back in.

## Install with an AI assistant

Paste this page into your assistant (Claude Code, Codex, …) and ask it to install Read Aloud. Each step has a check, so it knows when to move on.

1. **Check the tools.** Run `command -v omarchy uv pw-play wl-paste`. All four should print a path.
   - If `uv` is missing, run `omarchy pkg add uv`. If that fails, use the official installer: `curl -LsSf https://astral.sh/uv/install.sh | sh`, then open a new shell.
2. **Add the plugin.** Run `omarchy plugin add https://github.com/remigius-labs/omarchy-read-aloud --enable --yes`.
   - Check: `omarchy plugin list | grep remi.say` shows `enabled`.
3. **Set up the voice.** Run `~/.config/omarchy/plugins/remi.say/engine/setup`. It installs Python 3.12 and the engine through `uv`, then downloads the 350 MB model. This takes a few minutes.
   - Check: `ls ~/.local/share/omarchy-say/.ready` exists. If setup stops, it prints the reason; fix that and run it again.
4. **Reload the bar.** Run `omarchy restart shell`. The speech bubble shows in the bar.
5. **Test the voice.** Run `~/.local/share/omarchy-say/say "Read Aloud is ready"`. You should hear it.
6. **Optional keybind.** Add the two lines from [Keybind](#keybind) to `~/.config/hypr/bindings.lua`.

## Remove

```bash
omarchy plugin remove remi.say
rm -rf ~/.local/share/omarchy-say
```

The second line deletes the voice engine and model (about 350 MB).

## Limits

- Kokoro has English (US, UK), Portuguese, Spanish, French, Japanese, Italian, Mandarin and Hindi.
- First sound takes about a second on a laptop CPU.

## How it works

Copy text, tap the key, and it reads it out.

![Copy text, tap the key, it reads aloud](demo.gif)

## License

MIT. Kokoro model weights are Apache 2.0. Packages the setup installs keep their own licenses: kokoro-onnx and onnxruntime (MIT), phonemizer and espeak-ng (GPL-3).
