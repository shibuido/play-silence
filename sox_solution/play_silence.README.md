# play_silence.sh

A sox-based silence generator designed to solve vokoscreenNG 4.0.1 freezing issues with PulseAudio.

## Purpose

**Problem**: vokoscreenNG 4.0.1 can freeze when using PulseAudio due to audio subsystem inactivity or buffering issues during screen recording.

**Solution**: This script continuously plays silence to keep the PulseAudio subsystem active and prevent the freezing behavior that occurs during screen recording sessions.

## How It Works

The script uses sox (Sound eXchange) to generate digital silence and plays it continuously through PulseAudio. This maintains audio subsystem activity without producing any audible sound, effectively preventing the vokoscreenNG freezing issue.

**Two operational modes:**

1. **Direct Mode (default)**: Generates silence on-the-fly and streams directly to PulseAudio
2. **File Mode**: Creates a minimal silent WAV file first, then loops it continuously

## Usage Examples

### Basic Usage

```bash
# Play silence with default settings (44.1kHz, stereo)
./play_silence.sh

# Show help and all options
./play_silence.sh --help
```

### Advanced Configuration

```bash
# High-quality silence (48kHz, stereo)
./play_silence.sh --rate 48000 --channels 2

# Mono silence for minimal resource usage
./play_silence.sh --rate 44100 --channels 1

# Use file-based approach (alternative method)
./play_silence.sh --file

# Verbose output for debugging
./play_silence.sh --verbose
```

### Integration with vokoscreenNG

1. Start the silence generator:
   ```bash
   ./play_silence.sh
   ```

2. In another terminal, start vokoscreenNG:
   ```bash
   vokoscreenNG
   ```

3. Configure vokoscreenNG to record normally
4. Stop silence generator with `Ctrl+C` when done recording

## Command Line Options

* `-h, --help` - Show help message
* `-r, --rate RATE` - Set sample rate (8000-192000, default: 44100)
* `-c, --channels N` - Set channel count (1-8, default: 2)
* `-f, --file` - Generate WAV file first, then play it
* `-d, --direct` - Play silence directly without file (default)
* `-v, --verbose` - Enable verbose output

## Dependencies

### Required

* **sox** - Sound eXchange audio processing toolkit
* **PulseAudio** or **ALSA** - Audio subsystem

### Optional

* **play** command (usually included with sox) - For file-based mode

## Installation Instructions

### Install sox

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install sox
```

**Arch Linux:**
```bash
sudo pacman -S sox
```

**CentOS/RHEL/Fedora:**
```bash
# CentOS/RHEL
sudo yum install sox

# Fedora
sudo dnf install sox
```

**macOS (Homebrew):**
```bash
brew install sox
```

### Verify Installation

```bash
# Check sox installation
sox --version

# Check PulseAudio is running
pulseaudio --check -v
```

## Technical Details

### Default Configuration

* **Sample Rate**: 44,100 Hz (CD quality)
* **Channels**: 2 (stereo)
* **Bit Depth**: 16-bit (sox default)
* **Duration**: Infinite (until interrupted)

### Resource Usage

* **CPU**: Minimal (<1% on modern systems)
* **Memory**: <10MB for direct mode, <50MB for file mode
* **Network**: None
* **Disk**: None for direct mode, ~1KB for file mode

### Signal Handling

The script handles `SIGINT` (Ctrl+C) and `SIGTERM` gracefully:

* Stops sox processes cleanly
* Removes temporary files (if any)
* Exits with proper status codes

## Troubleshooting

### Common Issues

**"sox: command not found"**

* Install sox using the instructions above

**"No default audio device"**

* Ensure PulseAudio is running: `pulseaudio --start`
* Check audio devices: `pactl list short sinks`

**Permission denied**

* Make script executable: `chmod +x play_silence.sh`

**Still experiencing freezing**

* Try file mode: `./play_silence.sh --file`
* Use different sample rate: `./play_silence.sh --rate 48000`
* Check vokoscreenNG audio settings

### Debug Mode

Run with verbose output to diagnose issues:

```bash
./play_silence.sh --verbose
```

## Alternative Approaches

If the default direct mode doesn't work:

1. **File-based mode**: Use `--file` flag
2. **Different sample rates**: Try `--rate 48000` or `--rate 22050`
3. **Mono audio**: Use `--channels 1` for lower resource usage
4. **External tools**: Consider using `aplay` or `paplay` alternatives

## Safety Notes

* The script generates true digital silence (0 amplitude)
* No audible sound is produced
* Safe to run continuously
* Minimal system resource usage
* Does not interfere with normal audio playback

## License

This script is provided as-is for solving vokoscreenNG compatibility issues. Use freely and modify as needed.