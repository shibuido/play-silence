# play_silence Wrapper Script

## Purpose

The `play_silence` wrapper script provides a unified interface to multiple silence-playing implementations designed to solve vokoscreenNG 4.0.1 freezing issues with PulseAudio when using simultaneous output virtual audio devices.

## Problem Being Solved

When vokoscreenNG 4.0.1 (https://github.com/vkohaupt/vokoscreenNG) captures audio from PulseAudio's "simultaneous output" virtual device, it can freeze indefinitely when no audio is playing. This occurs because the audio subsystem becomes inactive, causing vokoscreenNG to wait forever for audio packets that never arrive.

Playing any audio stream - even silence - keeps the audio subsystem active and prevents this freezing issue.

## Features

- **Multiple Backends**: Choose from 5 different implementation methods
- **Auto-detection**: Automatically checks for required dependencies
- **Graceful Handling**: All methods handle interruption signals properly
- **Minimal Resources**: All implementations use < 1% CPU
- **Zero Configuration**: Works out of the box with sensible defaults

## Available Methods

| Method | Technology | Dependencies | CPU Usage | Memory |
|--------|------------|--------------|-----------|--------|
| `c` | C/ALSA | libasound2-dev, gcc | ~0.1% | < 1MB |
| `python` | Python/PyAudio | python3, python3-pyaudio | ~0.5% | ~20MB |
| `sox` | Sox/Bash | sox | ~0.3% | ~5MB |
| `aplay` | ALSA/Bash | alsa-utils | ~0.2% | ~2MB |
| `wav` | Simple loop | alsa-utils | ~0.2% | ~2MB |

## Quick Start

```bash
# Use default method (Python - most compatible)
./play_silence

# Use a specific method
./play_silence -m sox

# Run in background
./play_silence -m aplay &

# List all available methods
./play_silence --list

# Get help
./play_silence --help
```

## Installation

### System-wide Installation

```bash
# Make it available system-wide
sudo cp play_silence /usr/local/bin/
sudo chmod +x /usr/local/bin/play_silence

# Copy the entire project for all methods to work
sudo cp -r . /opt/play_silence/
sudo ln -sf /opt/play_silence/play_silence /usr/local/bin/play_silence
```

### Per-user Installation

```bash
# Add to user's local bin
mkdir -p ~/.local/bin
cp play_silence ~/.local/bin/
chmod +x ~/.local/bin/play_silence

# Ensure ~/.local/bin is in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Usage with vokoscreenNG

### Basic Workflow

1. **Start the silence player** (before launching vokoscreenNG):
   ```bash
   play_silence &
   SILENCE_PID=$!
   ```

2. **Launch vokoscreenNG**:
   ```bash
   vokoscreenNG
   ```

3. **Configure vokoscreenNG**:
   - Select your PulseAudio simultaneous output device
   - Start recording without worrying about freezes

4. **Stop the silence player** when done:
   ```bash
   kill $SILENCE_PID
   ```

### Automatic Start/Stop Script

Create a wrapper for vokoscreenNG:

```bash
#!/bin/bash
# ~/bin/vokoscreenNG-no-freeze

# Start silence player
play_silence -m python &
SILENCE_PID=$!

# Ensure silence player stops when script exits
trap "kill $SILENCE_PID 2>/dev/null" EXIT

# Launch vokoscreenNG
vokoscreenNG "$@"
```

### Systemd Service (Optional)

For always-on silence playback:

```ini
# ~/.config/systemd/user/play-silence.service
[Unit]
Description=Play Silence for vokoscreenNG
After=sound.target

[Service]
Type=simple
ExecStart=/usr/local/bin/play_silence -m c
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

Enable with:
```bash
systemctl --user enable --now play-silence
```

## Method Selection Guide

### Choose C (`-m c`) when:
- You want minimal resource usage
- You have development tools installed
- You need the most efficient solution

### Choose Python (`-m python`) when:
- You want the most portable solution
- Python is already installed
- You need cross-platform compatibility

### Choose Sox (`-m sox`) when:
- You already use sox for audio processing
- You want advanced audio configuration options
- You need format conversion capabilities

### Choose Aplay (`-m aplay`) when:
- You're on a minimal Linux system
- You only have ALSA utilities available
- You want a simple bash solution

### Choose WAV (`-m wav`) when:
- You want the simplest possible solution
- You don't need any configuration
- You just need it to work quickly

## Troubleshooting

### Script not found
```bash
# Make sure the script is executable
chmod +x play_silence

# Check current directory
./play_silence  # Note the ./
```

### Method not available
```bash
# List what's available
./play_silence --list

# Install missing dependencies for your chosen method
# See individual README files in each solution directory
```

### Permission denied
```bash
# Audio group membership might be required
sudo usermod -a -G audio $USER
# Log out and back in for changes to take effect
```

### High CPU usage
- Try a different method: C and aplay typically use the least CPU
- Check system audio settings for high sample rates
- Ensure no other audio processing is running

### No audio devices found
```bash
# Check available audio devices
aplay -l

# For PulseAudio
pactl list sinks
```

## Command Line Options

| Option | Description |
|--------|-------------|
| `-m, --method METHOD` | Select playback method (default: python) |
| `-l, --list` | List all available methods with descriptions |
| `-h, --help` | Show comprehensive help message |
| `-v, --version` | Display version information |

## Environment Variables

The script respects standard audio environment variables:

- `ALSA_CARD`: Default ALSA card to use
- `PULSE_SERVER`: PulseAudio server address
- `PULSE_SINK`: Default PulseAudio sink

## Performance Characteristics

All methods are designed for minimal system impact:

- **CPU Usage**: 0.1% - 0.5% depending on method
- **Memory Usage**: 1MB - 20MB depending on method
- **Latency**: < 10ms audio buffer latency
- **Power Impact**: Negligible on modern systems

## See Also

- Individual solution documentation:
  - `c_solution/play_silence.README.md` - C/ALSA implementation details
  - `python_solution/play_silence.README.md` - Python implementation details
  - `sox_solution/play_silence.README.md` - Sox implementation details
  - `aplay_solution/play_silence.README.md` - Aplay implementation details
- Project README: `README.md`
- vokoscreenNG: https://github.com/vkohaupt/vokoscreenNG

## License

Public Domain - Use freely for any purpose

## Contributing

This tool was created to solve a specific issue with vokoscreenNG. If you find improvements or additional methods that might help others, contributions are welcome!