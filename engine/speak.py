"""Read text aloud with Kokoro. Run again while it reads to stop."""
import hashlib
import json
import os
import queue
import re
import signal
import subprocess
import sys
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.path.join(HERE, "models", "kokoro-v1.0.onnx")
VOICES = os.path.join(HERE, "models", "voices-v1.0.bin")
SETTINGS = os.path.join(HERE, "settings.json")
LANGS = {"a": "en-us", "b": "en-gb", "e": "es", "f": "fr-fr", "h": "hi",
         "i": "it", "j": "ja", "p": "pt-br", "z": "cmn"}


def load_settings():
    try:
        saved = json.load(open(SETTINGS))
    except (OSError, ValueError):
        saved = {}
    voice = os.environ.get("SAY_VOICE") or saved.get("voice") or "af_heart"
    speed = float(os.environ.get("SAY_SPEED") or saved.get("speed") or 1.1)
    return voice, speed, LANGS.get(voice[0], "en-us")


VOICE, SPEED, LANG = load_settings()
RUNDIR = os.environ["XDG_RUNTIME_DIR"]
PIDFILE = os.path.join(RUNDIR, "omarchy-say.pid")
STATEFILE = os.path.join(RUNDIR, "omarchy-say.state")
SEENFILE = os.path.join(RUNDIR, "omarchy-say.seen")


def set_state(state):
    with open(STATEFILE, "w") as f:
        f.write(state)


def stop_running():
    try:
        pid = int(open(PIDFILE).read())
        if b"speak.py" not in open(f"/proc/{pid}/cmdline", "rb").read():
            return False
        os.killpg(pid, signal.SIGTERM)
        set_state("idle")
        return True
    except (OSError, ValueError):
        return False
    finally:
        if os.path.exists(PIDFILE):
            os.remove(PIDFILE)


def clean(text):
    text = re.sub(r"```.*?```", " Code block. ", text, flags=re.S)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"https?://\S+", "link", text)
    text = re.sub(r"[*_`#>|]", "", text)
    text = re.sub(r"^\s*[-•]\s+", "", text, flags=re.M)
    text = re.sub(r"^\s*-{3,}\s*$", "", text, flags=re.M)
    text = re.sub(r"\n{2,}", ". ", text)
    text = re.sub(r"\.\s*\.", ".", text)
    return re.sub(r"\s+", " ", text).strip()


def speak(text):
    import onnxruntime
    from kokoro_onnx import Kokoro

    onnxruntime.disable_telemetry_events()
    kokoro = Kokoro(MODEL, VOICES)
    sentences = [x for x in re.split(r"(?<=[.!?])\s+", text) if x.strip()]
    chunks = queue.Queue(maxsize=4)

    # Voice one sentence at a time in the background, so the first one plays
    # in about a second while the rest is still being made.
    def produce():
        for sentence in sentences:
            samples, _ = kokoro.create(sentence, voice=VOICE, speed=SPEED, lang=LANG)
            chunks.put(samples)
        chunks.put(None)

    threading.Thread(target=produce, daemon=True).start()
    player = subprocess.Popen(
        ["pw-play", "--raw", "--format", "f32", "--rate", "24000", "--channels", "1", "-"],
        stdin=subprocess.PIPE,
    )
    started = False
    while (samples := chunks.get()) is not None:
        if not started:
            set_state("playing")
            started = True
        player.stdin.write(samples.astype("float32").tobytes())
        player.stdin.flush()
    player.stdin.close()
    player.wait()


CLIP_MAX = 1_000_000
CLIP_TIMEOUT = 2


def kill_group(proc):
    try:
        os.killpg(proc.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def offered_type():
    # Some apps copy text under a non-text type only (terminals: application/mbox)
    try:
        types = subprocess.run(["wl-paste", "--list-types"], capture_output=True, text=True,
                               timeout=CLIP_TIMEOUT).stdout.split()
    except (OSError, subprocess.TimeoutExpired):
        return None
    for t in types:
        if not t.startswith(("image/", "audio/", "video/", "font/")) and t != "application/octet-stream":
            return t
    return None


def paste(args):
    try:
        proc = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                start_new_session=True)
    except OSError:
        return ""
    timer = threading.Timer(CLIP_TIMEOUT, kill_group, (proc,))
    timer.start()
    try:
        data = proc.stdout.read(CLIP_MAX)
    finally:
        timer.cancel()
        kill_group(proc)
        proc.wait()
    return data.decode("utf-8", "replace").strip()


def newest_selection():
    # Apps that draw their own selection (Herdr, tmux) copy it to the clipboard and leave the
    # primary selection stale, so --sel reads whichever of the two changed since the last read
    sel = paste(["wl-paste", "-n", "-p", "-t", "text"])
    clip = paste(["wl-paste", "-n", "-t", "text"])
    now = {k: hashlib.sha256(v.encode()).hexdigest() for k, v in (("sel", sel), ("clip", clip))}
    try:
        with open(SEENFILE) as f:
            seen = json.load(f)
    except (OSError, ValueError):
        seen = {}
    try:
        fd = os.open(SEENFILE, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w") as f:
            json.dump(now, f)
    except OSError:
        pass
    if clip and now["clip"] != seen.get("clip") and now["sel"] == seen.get("sel"):
        return clip
    return sel or clip


def clipboard(selection_first=False):
    if selection_first:
        out = newest_selection()
        if out:
            return out
    for args in (["wl-paste", "-n", "-t", "text"], ["wl-paste", "-n", "-p", "-t", "text"]):
        out = paste(args)
        if out:
            return out
    fallback = offered_type()
    return paste(["wl-paste", "-n", "-t", fallback]) if fallback else ""


def main():
    args = sys.argv[1:]
    if args == ["--stop"]:
        stop_running()
        return
    restart = args[:1] == ["--start"]
    if restart:
        args = args[1:]
    if stop_running() and not restart:
        return
    if args == ["-"]:
        text = clean(sys.stdin.read(CLIP_MAX))
    else:
        text = clean(" ".join(a for a in args if a not in ("--clip", "--sel"))
                     or clipboard("--sel" in args))
    if not text:
        return
    with open(PIDFILE, "w") as f:
        f.write(str(os.getpgrp()))
    set_state("loading")
    try:
        speak(text)
    finally:
        if os.path.exists(PIDFILE) and open(PIDFILE).read() == str(os.getpgrp()):
            os.remove(PIDFILE)
            set_state("idle")


if __name__ == "__main__":
    main()
