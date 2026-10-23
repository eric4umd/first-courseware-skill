#!/usr/bin/env bash
# stage_setup.sh — one-time setup of the listening-audio toolchain (isolated; touches nothing else).
#   venv with edge-tts, kokoro-onnx, soundfile, numpy, faster-whisper, fonttools, brotli   (~1 GB incl. models)
#   Kokoro-82M model files (Apache-2.0) + a starter voices.json
# Needs: uv, ffmpeg. Re-run is safe. Remove everything with:  rm -rf "$STAGE_TTS_HOME"
set -euo pipefail
HOME_DIR="${STAGE_TTS_HOME:-$HOME/.local/share/eric-stage-tts}"
mkdir -p "$HOME_DIR/models"
command -v uv >/dev/null || { echo "uv not found (https://docs.astral.sh/uv/)"; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg not found (brew install ffmpeg)"; exit 1; }
[ -d "$HOME_DIR/venv" ] || uv venv --python 3.12 "$HOME_DIR/venv"
uv pip install --python "$HOME_DIR/venv/bin/python" -U edge-tts kokoro-onnx soundfile numpy faster-whisper fonttools brotli
M="$HOME_DIR/models"
BASE=https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0
[ -s "$M/kokoro-v1.0.onnx" ] || curl -L -o "$M/kokoro-v1.0.onnx" "$BASE/kokoro-v1.0.onnx"
[ -s "$M/voices-v1.0.bin" ]  || curl -L -o "$M/voices-v1.0.bin"  "$BASE/voices-v1.0.bin"
[ -f "$HOME_DIR/voices.json" ] || cat > "$HOME_DIR/voices.json" <<'J'
{
  "female": "edge:en-US-AvaMultilingualNeural@-6%",
  "male": "edge:en-US-AndrewMultilingualNeural@-6%",
  "offline-female": "kokoro:af_heart@0.95",
  "offline-male": "kokoro:am_michael@0.95"
}
J
echo "ready: $HOME_DIR  (voices.json = your named voices; edit after the audition)"
