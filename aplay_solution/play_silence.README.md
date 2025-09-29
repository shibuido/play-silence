# play_silence.sh

A bash script that uses `aplay` to play silence indefinitely, specifically designed to solve the vokoscreenNG 4.0.1 freezing issue with PulseAudio.

## Purpose

This script addresses a common issue where vokoscreenNG 4.0.1 freezes when using PulseAudio. The problem occurs because the audio subsystem becomes inactive or unavailable during screen recording. By providing a continuous silent audio stream, this script keeps the audio system active and prevents the freezing issue.

## How It Works

The script provides two different approaches to generate and play silence:

### Method 1: Generate Silence On-the-Fly (Default)

* Uses `dd` to generate continuous zeros from `/dev/zero`
* Pipes the silent data directly to `aplay` in real-time
* More memory and CPU efficient
* No disk space usage
* Recommended for most use cases

### Method 2: WAV File Looping

* Creates a minimal 1-second silence WAV file
* Loops the WAV file indefinitely using `aplay`
* Uses a small amount of disk space (few KB)
* Slightly less CPU efficient due to file I/O
* Useful when you need a file-based approach

## Features

* **Two playback methods**: Generated silence or WAV file looping
* **Configurable audio settings**: Sample rate, channels, and format
* **Graceful signal handling**: Responds to Ctrl+C and SIGTERM
* **Comprehensive error checking**: Validates dependencies and parameters
* **Verbose mode**: Optional detailed logging
* **Cross-platform compatibility**: Works on most Linux distributions

## Dependencies

* **alsa-utils** - Provides the `aplay` command
* **coreutils** - Provides the `dd` command (usually pre-installed)

### Installation

**Arch Linux:**
```bash
sudo pacman -S alsa-utils
```

**Ubuntu/Debian:**
```bash
sudo apt-get install alsa-utils
```

**CentOS/RHEL/Fedora:**
```bash
# CentOS/RHEL
sudo yum install alsa-utils

# Fedora
sudo dnf install alsa-utils
```

## Usage

### Basic Usage

```bash
# Use default settings (generate method, 44.1kHz, stereo)
./play_silence.sh

# Use WAV file method
./play_silence.sh --method wavfile

# Verbose output
./play_silence.sh --verbose
```

### Advanced Usage

```bash
# Custom audio settings
./play_silence.sh --rate 48000 --channels 1 --format s16_le

# Use custom WAV file
./play_silence.sh --method wavfile --wavfile my_silence.wav

# Mono, 22kHz with verbose output
./play_silence.sh -r 22050 -c 1 -v
```

### Command Line Options

```
Usage: ./play_silence.sh [OPTIONS]

OPTIONS:
    -h, --help          Show help message
    -m, --method METHOD Choose method: 'generate' or 'wavfile' (default: generate)
    -r, --rate RATE     Sample rate in Hz (default: 44100)
    -c, --channels NUM  Number of channels (default: 2)
    -f, --format FMT    Audio format (default: cd)
    -w, --wavfile FILE  WAV file to use for wavfile method (default: silence_1sec.wav)
    -v, --verbose       Verbose output
```

### Audio Format Options

The script supports various audio formats that `aplay` recognizes:

* `cd` - CD quality (16-bit, 44.1kHz) - **Default**
* `dat` - DAT quality (16-bit, 48kHz)
* `s16_le` - Signed 16-bit little-endian
* `s8` - Signed 8-bit
* `u8` - Unsigned 8-bit
* `s24_le` - Signed 24-bit little-endian
* `s32_le` - Signed 32-bit little-endian

## Examples

### For vokoscreenNG Issue

1. **Start the silence player:**
   ```bash
   ./play_silence.sh
   ```

2. **In another terminal, start vokoscreenNG:**
   ```bash
   vokoscreenng
   ```

3. **Configure vokoscreenNG:**
   * Set audio source to your default PulseAudio device
   * The silence stream will keep the audio system active
   * Record normally without freezing issues

4. **Stop the silence player when done:**
   * Press `Ctrl+C` in the terminal running the script

### Background Execution

```bash
# Run in background (redirect output to avoid terminal spam)
./play_silence.sh > /dev/null 2>&1 &

# Save the process ID for later termination
SILENCE_PID=$!

# Later, stop the background process
kill $SILENCE_PID
```

### Testing Different Audio Settings

```bash
# Test with different sample rates
./play_silence.sh -r 22050 -v    # 22kHz
./play_silence.sh -r 48000 -v    # 48kHz
./play_silence.sh -r 96000 -v    # 96kHz

# Test mono vs stereo
./play_silence.sh -c 1 -v        # Mono
./play_silence.sh -c 2 -v        # Stereo
./play_silence.sh -c 6 -v        # 5.1 surround
```

## Signal Handling

The script gracefully handles interruption signals:

* **SIGINT (Ctrl+C)**: Gracefully stops all processes and exits
* **SIGTERM**: Gracefully stops all processes and exits

The cleanup process ensures that:

* All child processes (aplay, dd) are properly terminated
* No orphaned processes are left running
* Clean exit status is returned

## Technical Details

### WAV File Creation

When using the WAV file method, the script creates a minimal WAV file with:

* **Duration**: 1 second (configurable in code)
* **Content**: Pure silence (all zeros)
* **Header**: Standard RIFF/WAV format
* **Size**: Approximately 176KB for CD quality stereo

The WAV file is created with a proper RIFF header including:

* File format identification
* Audio format specifications (PCM)
* Sample rate and channel configuration
* Data chunk with silent audio samples

### Performance Characteristics

**Generate Method:**
* **CPU Usage**: Very low (mostly I/O operations)
* **Memory Usage**: Minimal (small buffers)
* **Disk Usage**: None
* **Startup Time**: Immediate

**WAV File Method:**
* **CPU Usage**: Low (file I/O overhead)
* **Memory Usage**: Minimal
* **Disk Usage**: ~176KB for CD quality
* **Startup Time**: Slight delay for file creation

## Troubleshooting

### Common Issues

1. **"aplay: command not found"**
   * Install alsa-utils package for your distribution

2. **"Permission denied" when creating WAV file**
   * Ensure write permissions in the script directory
   * Or use the generate method which doesn't require file creation

3. **No audio device found**
   * Check that ALSA/PulseAudio is properly configured
   * List available devices: `aplay -l`
   * Test with a real audio file first

4. **vokoscreenNG still freezes**
   * Ensure the script is running before starting vokoscreenNG
   * Try different audio settings (sample rate, channels)
   * Check that vokoscreenNG is configured to use the same audio system

### Debug Mode

Use verbose mode to see detailed information:

```bash
./play_silence.sh --verbose
```

This will show:

* Audio configuration details
* Process IDs of spawned processes
* File creation status (for WAV method)
* Cleanup operations during shutdown

### Testing Audio System

Before using with vokoscreenNG, test that the script works:

```bash
# Start the script
./play_silence.sh -v

# In another terminal, check that audio processes are running
ps aux | grep aplay

# Check audio device activity (if available)
pactl list short sources  # For PulseAudio
```

## Integration with vokoscreenNG

### Recommended Workflow

1. **Pre-recording setup:**
   ```bash
   # Start silence player
   ./play_silence.sh &
   SILENCE_PID=$!

   # Start vokoscreenNG
   vokoscreenng
   ```

2. **Post-recording cleanup:**
   ```bash
   # Stop silence player
   kill $SILENCE_PID
   ```

3. **Automated script example:**
   ```bash
   #!/bin/bash
   # Start silence, then vokoscreenNG, then cleanup

   ./play_silence.sh &
   SILENCE_PID=$!

   trap "kill $SILENCE_PID 2>/dev/null" EXIT

   vokoscreenng
   ```

### vokoscreenNG Configuration

* **Audio Source**: Set to your default PulseAudio device
* **Audio Format**: Match the format used by the silence script if possible
* **Sample Rate**: 44.1kHz works well with default script settings

## License and Support

This script is provided as-is for solving the vokoscreenNG freezing issue. Feel free to modify and distribute according to your needs.

For issues or improvements, please check the project documentation or create an issue in the repository.