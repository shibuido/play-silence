# Play Silence

A collection of minimal tools to play silence indefinitely, solving audio subsystem freezing issues.

## Problem

**vokoscreenNG 4.0.1** ([GitHub](https://github.com/vkohaupt/vokoscreenNG)) freezes when capturing PulseAudio's "simultaneous output" virtual audio device if no audio is actively playing. The application waits indefinitely for audio packets that never arrive when the audio subsystem is idle.

This is a known issue affecting many users (see [vokoscreenNG issue #189](https://github.com/vkohaupt/vokoscreenNG/issues/189)) with various audio configurations including:
- PulseAudio simultaneous output devices
- USB microphones
- Bluetooth audio devices
- Monitor sources with PipeWire/PulseAudio

**Workaround documented in**: [vokoscreenNG issue #379](https://github.com/vkohaupt/vokoscreenNG/issues/379)

## Solution

Playing continuous silence keeps the audio subsystem active, preventing freezes. This project provides multiple lightweight implementations to suit different system configurations.

## Quick Start

```bash
# Use the wrapper script with default method
./play_silence

# Or choose a specific implementation
./play_silence -m sox     # Use sox
./play_silence -m python  # Use Python
./play_silence -m c       # Use C/ALSA
./play_silence -m aplay   # Use aplay
```

## Features

- **5 different implementations** for maximum compatibility
- **< 1% CPU usage** across all methods
- **Zero configuration** required
- **Graceful signal handling** (Ctrl+C to stop)
- **Unified interface** via wrapper script

## Project Structure

```
play_silence/
├── play_silence           # Main wrapper script
├── play_silence.README.md # Wrapper documentation
├── assets/
│   └── silence.wav       # Minimal 1-second silent WAV
├── c_solution/           # C/ALSA implementation
│   ├── play_silence.c
│   ├── Makefile
│   └── play_silence.README.md
├── python_solution/      # Python implementation
│   ├── play_silence.py
│   └── play_silence.README.md
├── sox_solution/         # Sox-based script
│   ├── play_silence.sh
│   └── play_silence.README.md
└── aplay_solution/       # Aplay-based script
    ├── play_silence.sh
    └── play_silence.README.md
```

## Installation

### Quick Test
```bash
# No installation needed, just run
./play_silence
```

### System-wide Installation
```bash
sudo cp -r . /opt/play_silence/
sudo ln -s /opt/play_silence/play_silence /usr/local/bin/
```

## Usage with vokoscreenNG

1. Start silence player:
   ```bash
   play_silence &
   ```

2. Launch vokoscreenNG and configure audio capture

3. Record without freezing issues

4. Stop when done:
   ```bash
   killall play_silence
   ```

## Methods Comparison

| Method | Best For | Dependencies |
|--------|----------|--------------|
| **Python** | Default choice, cross-platform | python3-pyaudio |
| **C** | Minimal resources | libasound2-dev |
| **Sox** | Audio professionals | sox |
| **Aplay** | Minimal systems | alsa-utils |
| **WAV** | Simplest solution | alsa-utils |

## Documentation

- [Wrapper Script Documentation](play_silence.README.md) - Main interface details
- Individual solution READMEs in each directory
- Use `./play_silence --help` for complete usage information

## Requirements

Varies by method. The wrapper script will inform you of missing dependencies.

## License

Public Domain

## Contributing

Created specifically for vokoscreenNG users. Improvements and additional methods welcome!