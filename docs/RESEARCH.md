# Research: vokoscreenNG Freezing Issues

## Overview

This document summarizes research on vokoscreenNG freezing issues, particularly with PulseAudio, that led to the creation of the play-silence tool.

## Key Findings

### Primary Issue: vokoscreenNG Issue #189

**"Often freezes on stop"** - https://github.com/vkohaupt/vokoscreenNG/issues/189

- **Opened**: October 2021
- **Status**: Still open as of January 2025
- **Affected Versions**: 3.0.9 through 4.0.1
- **Symptoms**:
  - Application freezes when clicking stop button
  - Generates 0-byte files
  - Complete loss of recording
  - Requires force termination

### Affected Configurations

Multiple users report freezing with various audio setups:

1. **PulseAudio Configurations**
   - Monitor of built-in audio devices
   - USB microphones (e.g., Blue Microphones)
   - Bluetooth audio devices
   - Virtual devices (simultaneous output)

2. **PipeWire Configurations**
   - Echo cancel modules
   - Monitor sources
   - USB device monitors

3. **Common Patterns**
   - Freezing occurs when pausing/resuming recording
   - Long recordings (> few minutes) more likely to freeze
   - Without audio recording, no freezing occurs

## Technical Analysis

### Root Causes Identified

1. **Audio Pipeline Starvation**
   - PulseAudio monitor channels become unresponsive during silence
   - GStreamer pipeline waiting indefinitely for audio packets
   - Buffer underruns in audio encoder implementation

2. **Timer-Based Scheduling Issues**
   - PulseAudio's timer-based scheduling (`tsched=1`) can cause timing issues
   - Inconsistent sample rates between devices and recording

3. **Module Suspension**
   - `module-suspend-on-idle` causes audio devices to suspend
   - Suspended devices don't provide audio packets to monitors

### Related Issues in Other Projects

- **OBS Studio**: Video freezes with continuing audio, resolved by storage changes
- **SimpleScreenRecorder**: Audio sync issues with PulseAudio, fixed by sample rate consistency
- **Kazam**: GStreamer binding issues causing audio detection failures

## Community Workarounds

### Configuration-Based Solutions

1. **Disable Timer Scheduling**
   ```bash
   # In /etc/pulse/default.pa
   load-module module-udev-detect tsched=0
   ```

2. **Disable Module Suspension**
   ```bash
   # Comment out in /etc/pulse/default.pa
   # load-module module-suspend-on-idle
   ```

3. **Force Consistent Sample Rates**
   ```bash
   # In /etc/pulse/daemon.conf
   default-sample-rate = 48000
   alternate-sample-rate = 48000
   ```

### Active Workarounds

1. **Null Sink Module**
   ```bash
   pactl load-module module-null-sink sink_name=dummy
   ```

2. **Play Silent Audio** (our solution)
   - Keep audio subsystem active
   - Prevent monitor source suspension
   - Maintain continuous audio packet flow

## Why play-silence Works

The play-silence tool addresses the core issue by:

1. **Maintaining Active Audio Stream**
   - Prevents PulseAudio from suspending audio devices
   - Ensures continuous packet flow to monitor sources
   - Keeps GStreamer pipeline active

2. **Minimal Resource Impact**
   - Silent audio uses negligible CPU/memory
   - No actual sound output
   - Compatible with all recording scenarios

3. **Universal Compatibility**
   - Works with PulseAudio and PipeWire
   - Independent of vokoscreenNG version
   - No configuration changes required

## References

### GitHub Issues
- [vokoscreenNG #189](https://github.com/vkohaupt/vokoscreenNG/issues/189) - Main freezing issue
- [vokoscreenNG #301](https://github.com/vkohaupt/vokoscreenNG/issues/301) - Recording stuck with audio
- [vokoscreenNG #234](https://github.com/vkohaupt/vokoscreenNG/issues/234) - External soundcard freeze
- [vokoscreenNG #330](https://github.com/vkohaupt/vokoscreenNG/issues/330) - GST_MESSAGE_ERROR

### External Resources
- [ArchWiki PulseAudio Troubleshooting](https://wiki.archlinux.org/title/PulseAudio/Troubleshooting)
- [SimpleScreenRecorder Troubleshooting](https://www.maartenbaert.be/simplescreenrecorder/troubleshooting/)
- [OBS Forums - PulseAudio Issues](https://obsproject.com/forum/threads/no-audio-with-pulseaudio.61861/)

## Conclusion

The freezing issue in vokoscreenNG is a long-standing problem related to audio pipeline management in Linux. While the root cause requires fixes in vokoscreenNG's GStreamer implementation, the play-silence tool provides an effective workaround by maintaining an active audio stream, preventing the conditions that lead to freezing.

This workaround is particularly valuable given that:
- The issue has been open since 2021
- It affects multiple vokoscreenNG versions
- No permanent fix has been implemented
- Many users have lost recordings due to this bug