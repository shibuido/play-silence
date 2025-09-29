#!/bin/bash

# play_silence.sh - Sox-based silence generator for vokoscreenNG PulseAudio fix
# Generates and plays continuous silence to prevent vokoscreenNG 4.0.1 freezing issues

set -euo pipefail

# Default parameters
SAMPLE_RATE=44100
CHANNELS=2
DURATION=3600  # Generate 1 hour chunks (practically infinite when looped)
OUTPUT_MODE="direct"  # direct or file

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Signal handling for clean shutdown
cleanup() {
    echo -e "\n${YELLOW}Stopping silence playback...${NC}"
    # Kill any background sox processes we started
    jobs -p | xargs -r kill 2>/dev/null || true
    echo -e "${GREEN}Silence stopped.${NC}"
    exit 0
}

# Set up signal traps
trap cleanup SIGINT SIGTERM

show_help() {
    cat << EOF
play_silence.sh - Sox-based silence generator

PURPOSE:
    Solves vokoscreenNG 4.0.1 freezing issue with PulseAudio by playing
    continuous silence to keep the audio subsystem active.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -r, --rate RATE     Sample rate (default: 44100)
    -c, --channels N    Number of channels (default: 2)
    -f, --file          Generate silent WAV file first, then play it
    -d, --direct        Play silence directly without file (default)
    -v, --verbose       Verbose output

EXAMPLES:
    $0                          # Play silence with default settings
    $0 -r 48000 -c 1           # Mono silence at 48kHz
    $0 --file                  # Generate file first, then play
    $0 --verbose               # Show detailed output

DEPENDENCIES:
    - sox (Sound eXchange)
    - PulseAudio or ALSA

INSTALLATION:
    Ubuntu/Debian: sudo apt install sox
    Arch Linux:    sudo pacman -S sox
    CentOS/RHEL:   sudo yum install sox

Press Ctrl+C to stop.
EOF
}

check_dependencies() {
    if ! command -v sox &> /dev/null; then
        echo -e "${RED}Error: sox is not installed.${NC}" >&2
        echo -e "${YELLOW}Please install sox:${NC}" >&2
        echo "  Ubuntu/Debian: sudo apt install sox" >&2
        echo "  Arch Linux:    sudo pacman -S sox" >&2
        echo "  CentOS/RHEL:   sudo yum install sox" >&2
        exit 1
    fi
}

play_silence_direct() {
    echo -e "${GREEN}Playing silence directly (${SAMPLE_RATE}Hz, ${CHANNELS} channels)...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop.${NC}"

    while true; do
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Generating ${DURATION}s silence chunk..."
            sox -n -t pulseaudio -r "$SAMPLE_RATE" -c "$CHANNELS" trim 0.0 "$DURATION"
        else
            sox -n -t pulseaudio -r "$SAMPLE_RATE" -c "$CHANNELS" trim 0.0 "$DURATION" 2>/dev/null
        fi
    done
}

play_silence_file() {
    local silent_file="silence_${SAMPLE_RATE}hz_${CHANNELS}ch.wav"

    echo -e "${GREEN}Generating silent WAV file: $silent_file${NC}"

    # Generate a 1-second silent WAV file
    sox -n -r "$SAMPLE_RATE" -c "$CHANNELS" "$silent_file" trim 0.0 1.0

    echo -e "${GREEN}Playing silence from file (looping)...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop.${NC}"

    # Play the file in a loop
    while true; do
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Playing silence loop..."
            play "$silent_file"
        else
            play "$silent_file" 2>/dev/null
        fi
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
        -r|--rate)
            SAMPLE_RATE="$2"
            shift 2
            ;;
        -c|--channels)
            CHANNELS="$2"
            shift 2
            ;;
        -f|--file)
            OUTPUT_MODE="file"
            shift
            ;;
        -d|--direct)
            OUTPUT_MODE="direct"
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            echo "Use -h or --help for usage information." >&2
            exit 1
            ;;
    esac
done

# Validate numeric arguments
if ! [[ "$SAMPLE_RATE" =~ ^[0-9]+$ ]] || [[ "$SAMPLE_RATE" -lt 8000 ]] || [[ "$SAMPLE_RATE" -gt 192000 ]]; then
    echo -e "${RED}Error: Sample rate must be a number between 8000 and 192000${NC}" >&2
    exit 1
fi

if ! [[ "$CHANNELS" =~ ^[0-9]+$ ]] || [[ "$CHANNELS" -lt 1 ]] || [[ "$CHANNELS" -gt 8 ]]; then
    echo -e "${RED}Error: Channels must be a number between 1 and 8${NC}" >&2
    exit 1
fi

# Main execution
echo -e "${GREEN}Sox Silence Generator for vokoscreenNG${NC}"
echo -e "${YELLOW}Solving PulseAudio freezing issues...${NC}"
echo

check_dependencies

if [[ "$OUTPUT_MODE" == "file" ]]; then
    play_silence_file
else
    play_silence_direct
fi