#!/bin/bash

# play_silence.sh - Play silence indefinitely using aplay
# Solves vokoscreenNG 4.0.1 freezing issue with PulseAudio

set -euo pipefail

# Default configuration
SAMPLE_RATE=44100
CHANNELS=2
FORMAT="cd"  # CD quality (16-bit, 44.1kHz, stereo)
METHOD="generate"  # Default method: generate or wavfile
WAV_FILE="silence_1sec.wav"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to show help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Play silence indefinitely using aplay to solve vokoscreenNG freezing issues.

OPTIONS:
    -h, --help          Show this help message
    -m, --method METHOD Choose method: 'generate' or 'wavfile' (default: generate)
    -r, --rate RATE     Sample rate in Hz (default: 44100)
    -c, --channels NUM  Number of channels (default: 2)
    -f, --format FMT    Audio format (default: cd)
    -w, --wavfile FILE  WAV file to use for wavfile method (default: silence_1sec.wav)
    -v, --verbose       Verbose output

METHODS:
    generate    Generate silence on-the-fly and pipe to aplay (more efficient)
    wavfile     Create and loop a minimal WAV file (uses disk space)

EXAMPLES:
    $0                              # Use default settings (generate method)
    $0 -m wavfile                   # Use WAV file looping method
    $0 -r 48000 -c 1               # Mono, 48kHz sample rate
    $0 -m wavfile -w my_silence.wav # Use custom WAV file
    $0 -v                           # Verbose output

SIGNALS:
    Ctrl+C (SIGINT)  - Gracefully stop playback
    SIGTERM          - Gracefully stop playback

DEPENDENCIES:
    - alsa-utils (for aplay command)
    - dd (for generating silence)
    - sox (optional, for creating custom WAV files)

PURPOSE:
    This script solves the vokoscreenNG 4.0.1 freezing issue with PulseAudio
    by providing a continuous silent audio stream that keeps the audio system active.

EOF
}

# Function for logging
log() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${GREEN}[INFO]${NC} $1" >&2
    fi
}

# Function for warnings
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# Function for errors
error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Signal handler for graceful shutdown
cleanup() {
    echo ""
    log "Received interrupt signal, cleaning up..."

    # Kill any background processes
    if [[ -n "${APLAY_PID:-}" ]] && kill -0 "$APLAY_PID" 2>/dev/null; then
        log "Stopping aplay process (PID: $APLAY_PID)"
        kill "$APLAY_PID" 2>/dev/null || true
        wait "$APLAY_PID" 2>/dev/null || true
    fi

    if [[ -n "${DD_PID:-}" ]] && kill -0 "$DD_PID" 2>/dev/null; then
        log "Stopping dd process (PID: $DD_PID)"
        kill "$DD_PID" 2>/dev/null || true
        wait "$DD_PID" 2>/dev/null || true
    fi

    log "Cleanup completed"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Function to check dependencies
check_dependencies() {
    local missing_deps=()

    if ! command -v aplay >/dev/null 2>&1; then
        missing_deps+=("aplay (alsa-utils)")
    fi

    if ! command -v dd >/dev/null 2>&1; then
        missing_deps+=("dd (coreutils)")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing_deps[*]}"
        echo "Please install the required packages:" >&2
        echo "  Arch Linux: sudo pacman -S alsa-utils" >&2
        echo "  Ubuntu/Debian: sudo apt-get install alsa-utils" >&2
        echo "  CentOS/RHEL: sudo yum install alsa-utils" >&2
        exit 1
    fi
}

# Function to create a minimal WAV file with silence
create_silence_wav() {
    local file="$1"
    local duration="${2:-1}"  # Duration in seconds

    if [[ -f "$file" ]]; then
        log "WAV file '$file' already exists, skipping creation"
        return 0
    fi

    log "Creating $duration second silence WAV file: $file"

    # Calculate the number of samples needed
    local samples=$((SAMPLE_RATE * duration))
    local bytes_per_sample=$((CHANNELS * 2))  # 16-bit = 2 bytes per sample
    local data_size=$((samples * bytes_per_sample))
    local file_size=$((data_size + 44))  # WAV header is 44 bytes

    # Create WAV file with proper header
    {
        # RIFF header
        printf "RIFF"
        printf "\\$(printf "%o" $((file_size - 8 & 255)))"
        printf "\\$(printf "%o" $(((file_size - 8) >> 8 & 255)))"
        printf "\\$(printf "%o" $(((file_size - 8) >> 16 & 255)))"
        printf "\\$(printf "%o" $(((file_size - 8) >> 24 & 255)))"
        printf "WAVE"

        # Format chunk
        printf "fmt "
        printf "\\020\\000\\000\\000"  # Chunk size (16)
        printf "\\001\\000"           # Audio format (PCM)
        printf "\\$(printf "%o" $((CHANNELS & 255)))"
        printf "\\$(printf "%o" $((CHANNELS >> 8 & 255)))"
        printf "\\$(printf "%o" $((SAMPLE_RATE & 255)))"
        printf "\\$(printf "%o" $(((SAMPLE_RATE >> 8) & 255)))"
        printf "\\$(printf "%o" $(((SAMPLE_RATE >> 16) & 255)))"
        printf "\\$(printf "%o" $(((SAMPLE_RATE >> 24) & 255)))"

        local byte_rate=$((SAMPLE_RATE * CHANNELS * 2))
        printf "\\$(printf "%o" $((byte_rate & 255)))"
        printf "\\$(printf "%o" $(((byte_rate >> 8) & 255)))"
        printf "\\$(printf "%o" $(((byte_rate >> 16) & 255)))"
        printf "\\$(printf "%o" $(((byte_rate >> 24) & 255)))"

        printf "\\$(printf "%o" $((bytes_per_sample & 255)))"
        printf "\\$(printf "%o" $((bytes_per_sample >> 8 & 255)))"
        printf "\\020\\000"  # Bits per sample (16)

        # Data chunk
        printf "data"
        printf "\\$(printf "%o" $((data_size & 255)))"
        printf "\\$(printf "%o" $(((data_size >> 8) & 255)))"
        printf "\\$(printf "%o" $(((data_size >> 16) & 255)))"
        printf "\\$(printf "%o" $(((data_size >> 24) & 255)))"

        # Silent audio data (zeros)
        dd if=/dev/zero bs=1 count="$data_size" 2>/dev/null
    } > "$file"

    log "Created WAV file: $file ($(wc -c < "$file") bytes)"
}

# Function to play silence using generated method
play_silence_generate() {
    log "Starting silence playback using generate method"
    log "Sample rate: ${SAMPLE_RATE}Hz, Channels: $CHANNELS, Format: $FORMAT"

    echo "Playing silence indefinitely (Ctrl+C to stop)..."
    echo "Method: Generate silence on-the-fly"
    echo "Audio settings: ${SAMPLE_RATE}Hz, ${CHANNELS} channels, format: $FORMAT"

    # Generate continuous silence and pipe to aplay
    # Using a larger block size for efficiency
    dd if=/dev/zero bs=4096 2>/dev/null &
    DD_PID=$!

    # Pipe the silence to aplay
    dd if=/dev/zero bs=4096 2>/dev/null | aplay -t raw -f "$FORMAT" -r "$SAMPLE_RATE" -c "$CHANNELS" &
    APLAY_PID=$!

    # Wait for aplay to finish (which should never happen unless interrupted)
    wait "$APLAY_PID"
}

# Function to play silence using WAV file method
play_silence_wavfile() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local wav_path="$script_dir/$WAV_FILE"

    log "Starting silence playback using WAV file method"
    log "WAV file: $wav_path"

    # Create the WAV file if it doesn't exist
    create_silence_wav "$wav_path"

    if [[ ! -f "$wav_path" ]]; then
        error "Failed to create or find WAV file: $wav_path"
        exit 1
    fi

    echo "Playing silence indefinitely (Ctrl+C to stop)..."
    echo "Method: Looping WAV file"
    echo "WAV file: $wav_path"
    echo "Audio settings: ${SAMPLE_RATE}Hz, ${CHANNELS} channels"

    # Loop the WAV file indefinitely
    while true; do
        aplay "$wav_path" &
        APLAY_PID=$!
        wait "$APLAY_PID" || break
    done
}

# Parse command line arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -m|--method)
            METHOD="$2"
            shift 2
            ;;
        -r|--rate)
            SAMPLE_RATE="$2"
            shift 2
            ;;
        -c|--channels)
            CHANNELS="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -w|--wavfile)
            WAV_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            echo "Use -h or --help for usage information" >&2
            exit 1
            ;;
    esac
done

# Validate method
if [[ "$METHOD" != "generate" && "$METHOD" != "wavfile" ]]; then
    error "Invalid method: $METHOD (must be 'generate' or 'wavfile')"
    exit 1
fi

# Validate numeric parameters
if ! [[ "$SAMPLE_RATE" =~ ^[0-9]+$ ]] || [[ "$SAMPLE_RATE" -lt 8000 ]] || [[ "$SAMPLE_RATE" -gt 192000 ]]; then
    error "Invalid sample rate: $SAMPLE_RATE (must be between 8000 and 192000)"
    exit 1
fi

if ! [[ "$CHANNELS" =~ ^[0-9]+$ ]] || [[ "$CHANNELS" -lt 1 ]] || [[ "$CHANNELS" -gt 8 ]]; then
    error "Invalid number of channels: $CHANNELS (must be between 1 and 8)"
    exit 1
fi

# Check dependencies
check_dependencies

# Start playing silence based on chosen method
case "$METHOD" in
    generate)
        play_silence_generate
        ;;
    wavfile)
        play_silence_wavfile
        ;;
esac