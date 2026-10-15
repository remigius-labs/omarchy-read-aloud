.pragma library

// Kokoro voice ids: first letter is the language, second the gender.
// Ordered by how many Omarchy users likely speak each.
var languages = [
  { value: "a", label: "US", name: "English (US)", sample: "Hi, this is {name}." },
  { value: "b", label: "UK", name: "English (UK)", sample: "Hello, this is {name}." },
  { value: "p", label: "PT", name: "Português", sample: "Olá, eu sou {name}." },
  { value: "e", label: "ES", name: "Español", sample: "Hola, soy {name}." },
  { value: "f", label: "FR", name: "Français", sample: "Bonjour, je suis {name}." },
  { value: "j", label: "JA", name: "日本語", sample: "こんにちは、{name}です。" },
  { value: "i", label: "IT", name: "Italiano", sample: "Ciao, sono {name}." },
  { value: "z", label: "ZH", name: "中文", sample: "你好，我是{name}。" },
  { value: "h", label: "HI", name: "हिन्दी", sample: "नमस्ते, मैं {name} हूँ।" }
]


var allVoices = [
  "af_heart", "af_bella", "af_nicole", "af_aoede", "af_kore", "af_sarah", "af_alloy",
  "af_jessica", "af_nova", "af_river", "af_sky",
  "am_michael", "am_fenrir", "am_puck", "am_echo", "am_eric", "am_liam", "am_onyx",
  "am_adam", "am_santa",
  "bf_emma", "bf_isabella", "bf_alice", "bf_lily",
  "bm_george", "bm_fable", "bm_lewis", "bm_daniel",
  "ff_siwis",
  "pf_dora", "pm_alex", "pm_santa",
  "ef_dora", "em_alex", "em_santa",
  "if_sara", "im_nicola",
  "jf_alpha", "jf_gongitsune", "jf_nezumi", "jf_tebukuro", "jm_kumo",
  "zf_xiaobei", "zf_xiaoni", "zf_xiaoxiao", "zf_xiaoyi",
  "zm_yunjian", "zm_yunxi", "zm_yunxia", "zm_yunyang",
  "hf_alpha", "hf_beta", "hm_omega", "hm_psi"
]

// Best-rated first (Kokoro VOICES.md grades); the first of each gender is the default.
var shortVoices = {
  a: ["af_heart", "af_bella", "af_nicole", "am_michael"],
  b: ["bf_emma", "bf_isabella", "bm_george", "bm_fable"],
  f: ["ff_siwis"],
  p: ["pf_dora", "pm_alex", "pm_santa"],
  e: ["ef_dora", "em_alex", "em_santa"],
  i: ["if_sara", "im_nicola"],
  j: ["jf_alpha", "jf_gongitsune", "jf_nezumi", "jm_kumo"],
  z: ["zf_xiaoxiao", "zf_xiaoyi", "zm_yunxi", "zm_yunjian"],
  h: ["hf_alpha", "hf_beta", "hm_omega", "hm_psi"]
}

var speeds = ["0.9", "1.0", "1.1", "1.25", "1.5"]

function voiceName(id) {
  var n = id.slice(3)
  return n.charAt(0).toUpperCase() + n.slice(1)
}

function language(code) {
  for (var i = 0; i < languages.length; i++)
    if (languages[i].value === code) return languages[i]
  return languages[0]
}

function sample(id) {
  return language(id.charAt(0)).sample.replace("{name}", voiceName(id))
}

