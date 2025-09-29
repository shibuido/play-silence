# play_silence - ALSA Silence Player

## Purpose

This program solves the **vokoscreenNG 4.0.1 freezing issue with PulseAudio** by keeping the audio subsystem active with a continuous silent audio stream. When vokoscreenNG runs without any audio activity, it can freeze due to PulseAudio timing issues. This utility provides a minimal, low-resource solution by generating and playing silence indefinitely.

## How It Works

The program uses the ALSA (Advanced Linux Sound Architecture) API to:

* Open the default audio output device (or a specified device)
* Configure audio parameters (44.1kHz, 16-bit stereo)
* Generate silence programmatically (zeros in audio buffer)
* Continuously write silent audio frames to keep the audio subsystem active
* Handle interruptions gracefully with proper cleanup

The implementation uses a small buffer (1024 frames) to minimize latency and memory usage while maintaining continuous audio activity.

## Build Instructions

### Prerequisites

Install ALSA development libraries:

```bash
# Ubuntu/Debian
sudo apt-get install libasound2-dev

# Fedora/RHEL
sudo dnf install alsa-lib-devel

# Arch Linux
sudo pacman -S alsa-lib

# openSUSE
sudo zypper install alsa-devel
```

### Compilation

```bash
# Check if dependencies are installed
make check-deps

# Build the program
make

# Or build manually
gcc -Wall -Wextra -O2 -std=c99 -o play_silence play_silence.c -lasound
```

## Usage Examples

### Basic Usage

```bash
# Use default ALSA device
./play_silence

# Get help
./play_silence --help
```

### Specific Audio Devices

```bash
# Use hardware device 0, subdevice 0
./play_silence hw:0,0

# Use hardware device 1 with format conversion
./play_silence plughw:1,0

# Use PulseAudio through ALSA
./play_silence pulse
```

### System Installation

```bash
# Install system-wide (requires sudo)
make install

# Now you can run from anywhere
play_silence

# Uninstall
make uninstall
```

### Running with vokoscreenNG

1. Start the silence player in the background:
   ```bash
   ./play_silence &
   ```

2. Launch vokoscreenNG - it should no longer freeze

3. Stop the silence player when done:
   ```bash
   # Press Ctrl+C or send SIGTERM
   kill %1  # if running in background
   ```

## Dependencies

### Runtime Dependencies

* **ALSA libraries** (`libasound2`) - Usually installed by default on Linux systems
* **Linux kernel with ALSA support** - Standard on modern distributions

### Build Dependencies

* **GCC compiler** - For compilation
* **ALSA development headers** (`libasound2-dev`) - For building against ALSA API
* **Make** - For using the provided Makefile (optional)

### System Requirements

* **Linux operating system** with ALSA support
* **Audio hardware** or virtual audio device
* **Minimal CPU and memory** - Program uses <1% CPU and <1MB RAM

## Features

### Low Resource Usage

* **Minimal CPU usage** - Efficient ALSA I/O with small buffers
* **Low memory footprint** - Single 4KB audio buffer
* **No external dependencies** - Only standard C library and ALSA

### Robust Operation

* **Graceful shutdown** - Handles SIGINT (Ctrl+C) and SIGTERM cleanly
* **Error recovery** - Automatically recovers from audio underruns
* **Device flexibility** - Works with any ALSA-compatible audio device

### User-Friendly

* **Clear status messages** - Shows device info and operational status
* **Command-line help** - Built-in usage instructions
* **Multiple device support** - Can specify custom ALSA devices

## Technical Details

### Audio Configuration

* **Sample Rate**: 44.1kHz (CD quality)
* **Format**: 16-bit signed little-endian
* **Channels**: 2 (stereo)
* **Buffer Size**: 1024 frames (low latency)

### Signal Handling

The program registers handlers for:

* **SIGINT** - Ctrl+C keyboard interrupt
* **SIGTERM** - Termination signal from system

Both signals trigger graceful shutdown with proper ALSA cleanup.

### Error Handling

* **Device opening failures** - Clear error messages with device names
* **Audio underruns** - Automatic recovery with retry logic
* **Memory allocation** - Proper cleanup on allocation failures

## Troubleshooting

### Common Issues

**"Cannot open PCM device" error:**

```bash
# Check available ALSA devices
aplay -l

# Test with specific device
./play_silence hw:0,0
```

**Permission denied:**

```bash
# Add user to audio group
sudo usermod -a -G audio $USER
# Log out and back in
```

**PulseAudio conflicts:**

```bash
# Use PulseAudio device explicitly
./play_silence pulse

# Or restart PulseAudio
pulseaudio --kill && pulseaudio --start
```

### Debugging

Enable verbose ALSA output:

```bash
# Set environment variable for ALSA debugging
export ALSA_DEBUG=1
./play_silence
```

Check audio system status:

```bash
# Test audio output
speaker-test -c 2 -t sine

# Check PulseAudio status
pulseaudio --check -v
```

## License

This program is released into the **Public Domain**. You are free to use, modify, and distribute it without restrictions.

## Development

### Building for Development

```bash
# Test compilation only
make test-compile

# Clean build artifacts
make clean

# Run directly after building
make run
```

### Code Structure

* **Signal handling** - Clean shutdown on interruption
* **ALSA initialization** - Device setup and configuration
* **Audio loop** - Continuous silence generation and playback
* **Error recovery** - Robust handling of audio system issues
* **Resource cleanup** - Proper memory and device cleanup

The code follows C99 standards and uses only POSIX-compliant system calls for maximum portability across Linux distributions.