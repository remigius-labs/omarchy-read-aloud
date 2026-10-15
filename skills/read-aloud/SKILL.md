---
name: read-aloud
description: Use when the user asks to hear something, or asks what is in a long file, report, draft or answer ("read it to me", "say it", "read aloud", "what's in that file"). Pipes a spoken version into the local Read Aloud engine (Kokoro) instead of pasting long text into chat. Also use instead of any chat paste longer than about 40 lines.
---

# Read aloud

Long text in a terminal is slow to read, and hard with dyslexia. The Read Aloud engine reads it out locally with Kokoro; nothing leaves the machine. Chat gets one line, the audio carries the content.

Engine: `~/.local/share/omarchy-say/say` (installed by the Read Aloud plugin on first click).

## When
- The user asks to hear something, or asks for the full text of a file.
- An answer would paste more than about 40 lines.
- Short answers stay in chat as normal.

## Steps
1. **Write a spoken script**, not the raw file. Save it to `$TMPDIR/read-aloud.txt`.
   - Headings: "Section: <name>."
   - Bullets and numbered items: one sentence each, in order.
   - Small tables (15 rows or fewer): one sentence per row, naming the columns.
   - Big tables: one summary sentence, then the first 5 rows, then "and N more rows in the file."
   - Drop: wallet and contract addresses, hashes, URLs, code blocks, file paths.
   - Numbers as spoken: "$2.2M" becomes "2.2 million dollars", "0.2%" becomes "0.2 percent", "10-05" becomes "October 5".
   - Keep the source wording otherwise. A literal ask gets literal content, made speakable.
2. **Play it** in the background. Audio needs the PipeWire socket, so run it outside any command sandbox:
   `~/.local/share/omarchy-say/say --start - < "$TMPDIR/read-aloud.txt"`
3. **Chat gets one line:** what is playing, rough length (words / 165 = minutes), and how to stop.

## Controls
- `say --start -` reads stdin, `say --clip` reads the clipboard, `say --stop` stops.
- Clicking the bar bubble while it reads also stops it.
- Voice, speed and language: right-click the bubble. Saved for every read, including this skill.
