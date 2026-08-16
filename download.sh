#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Qwen3.8-27B Q4_K_M - RunPod downloader
#
# Her şey download.sh'ın bulunduğu dizine kurulur.
# Klasör karmaşası yok 🗿
# ============================================================

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE"

REPO="bartowski/Qwen3.8-27B-GGUF"
MODEL="Qwen3.8-27B-Q4_K_M.gguf"

echo
echo "=========================================="
echo " Qwen3.8-27B Q4_K_M Setup"
echo "=========================================="
echo
echo "Kurulum dizini: $BASE"
echo


# ============================================================
# Hugging Face CLI
# ============================================================

if ! command -v hf >/dev/null 2>&1; then

    echo "Hugging Face CLI bulunamadı, kuruluyor..."

    if ! command -v python3 >/dev/null 2>&1; then
        echo "HATA: python3 bulunamadı."
        exit 1
    fi

    python3 -m pip install --user -U "huggingface_hub[cli]"

    export PATH="$HOME/.local/bin:$PATH"

fi


# ============================================================
# MODEL
# ============================================================

if [ -f "$BASE/$MODEL" ]; then

    echo
    echo "Model zaten mevcut:"
    echo "$MODEL"

else

    echo
    echo "Model indiriliyor:"
    echo "$REPO"
    echo "$MODEL"
    echo

    hf download \
        "$REPO" \
        "$MODEL" \
        --local-dir "$BASE"

fi


# ============================================================
# INTERFACE.SH
# ============================================================

echo
echo "interface.sh oluşturuluyor..."

cat > "$BASE/interface.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE"

MODEL="$BASE/Qwen3.8-27B-Q4_K_M.gguf"

HOST="0.0.0.0"
PORT="8080"

CTX=32768
BATCH=2048
UBATCH=512
GPU_LAYERS=999

MTP_N_MAX=3


# ------------------------------------------------------------
# llama-server bul
# ------------------------------------------------------------

if [ -x "$BASE/llama-server" ]; then

    SERVER="$BASE/llama-server"

elif command -v llama-server >/dev/null 2>&1; then

    SERVER="$(command -v llama-server)"

else

    echo
    echo "HATA: llama-server bulunamadı."
    echo
    echo "llama-server binary'sini bu dizine koy"
    echo "veya PATH içine kur."
    echo

    exit 1

fi


# ------------------------------------------------------------
# Model kontrol
# ------------------------------------------------------------

if [ ! -f "$MODEL" ]; then

    echo
    echo "HATA: Model bulunamadı:"
    echo "$MODEL"
    echo
    echo "Önce ./download.sh çalıştır."
    echo

    exit 1

fi


# ------------------------------------------------------------
# Başlat
# ------------------------------------------------------------

echo
echo "=========================================="
echo " Qwen3.8-27B SERVER"
echo "=========================================="
echo
echo "Model   : $(basename "$MODEL")"
echo "MTP     : ON"
echo "MTP max : $MTP_N_MAX"
echo "Context : $CTX"
echo "Batch   : $BATCH"
echo "uBatch  : $UBATCH"
echo "Server  : $HOST:$PORT"
echo
echo "Başlatılıyor..."
echo


exec "$SERVER" \
    --model "$MODEL" \
    --host "$HOST" \
    --port "$PORT" \
    --n-gpu-layers "$GPU_LAYERS" \
    --ctx-size "$CTX" \
    --batch-size "$BATCH" \
    --ubatch-size "$UBATCH" \
    --flash-attn on \
    --spec-type draft-mtp \
    --spec-draft-n-max "$MTP_N_MAX"
EOF

chmod +x "$BASE/interface.sh"


# ============================================================
# DONE
# ============================================================

echo
echo "=========================================="
echo " HAZIR 🗿"
echo "=========================================="
echo
echo "Model:"
echo "  $MODEL"
echo
echo "Interface:"
echo "  interface.sh"
echo
echo "llama-server hazır olduğunda:"
echo
echo "  ./interface.sh"
echo