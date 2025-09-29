#!/usr/bin/env python3
"""
Play Silence - A utility to play silence indefinitely to keep audio system active.

This script solves the vokoscreenNG 4.0.1 freezing issue with PulseAudio by
continuously playing silence, preventing the audio system from going idle.

Supports multiple audio backends:
- pyaudio (default, recommended)
- pygame (fallback option)
- subprocess with aplay (system fallback)
"""

import sys
import time
import signal
import argparse
import threading
from typing import Optional


class SilencePlayer:
    """Base class for silence players."""

    def __init__(self):
        self.running = False
        self.thread: Optional[threading.Thread] = None

    def start(self):
        """Start playing silence."""
        self.running = True
        self.thread = threading.Thread(target=self._play_loop, daemon=True)
        self.thread.start()

    def stop(self):
        """Stop playing silence."""
        self.running = False
        if self.thread and self.thread.is_alive():
            self.thread.join(timeout=1.0)

    def _play_loop(self):
        """Override in subclasses."""
        raise NotImplementedError


class PyAudioSilencePlayer(SilencePlayer):
    """PyAudio-based silence player (recommended)."""

    def __init__(self, sample_rate=44100, chunk_size=1024):
        super().__init__()
        self.sample_rate = sample_rate
        self.chunk_size = chunk_size
        self.pyaudio = None
        self.stream = None

        try:
            import pyaudio
            self.pyaudio = pyaudio.PyAudio()
            print("Using PyAudio backend")
        except ImportError:
            raise ImportError("PyAudio not available. Install with: pip install pyaudio")

    def _play_loop(self):
        """Play silence using PyAudio."""
        try:
            import pyaudio

            # Create silence buffer (zeros)
            silence_chunk = b'\x00' * (self.chunk_size * 2)  # 16-bit stereo

            # Open audio stream
            self.stream = self.pyaudio.open(
                format=pyaudio.paInt16,
                channels=2,
                rate=self.sample_rate,
                output=True,
                frames_per_buffer=self.chunk_size
            )

            print(f"Playing silence at {self.sample_rate}Hz, chunk size {self.chunk_size}")

            while self.running:
                self.stream.write(silence_chunk)
                time.sleep(0.001)  # Small delay to prevent excessive CPU usage

        except Exception as e:
            print(f"PyAudio error: {e}")
        finally:
            if self.stream:
                self.stream.stop_stream()
                self.stream.close()
            if self.pyaudio:
                self.pyaudio.terminate()


class PygameSilencePlayer(SilencePlayer):
    """Pygame-based silence player (fallback option)."""

    def __init__(self, sample_rate=44100, buffer_size=1024):
        super().__init__()
        self.sample_rate = sample_rate
        self.buffer_size = buffer_size

        try:
            import pygame
            pygame.mixer.pre_init(
                frequency=sample_rate,
                size=-16,
                channels=2,
                buffer=buffer_size
            )
            pygame.mixer.init()
            print("Using Pygame backend")
        except ImportError:
            raise ImportError("Pygame not available. Install with: pip install pygame")

    def _play_loop(self):
        """Play silence using Pygame."""
        try:
            import pygame
            import numpy as np

            # Create silence sound (1 second of silence)
            silence_duration = 1.0  # seconds
            silence_samples = int(self.sample_rate * silence_duration)
            silence_array = np.zeros((silence_samples, 2), dtype=np.int16)

            silence_sound = pygame.sndarray.make_sound(silence_array)

            print(f"Playing silence with Pygame at {self.sample_rate}Hz")

            while self.running:
                silence_sound.play()
                time.sleep(silence_duration * 0.9)  # Slight overlap to prevent gaps

        except ImportError as e:
            if "numpy" in str(e):
                print("Numpy not available for Pygame backend. Install with: pip install numpy")
            raise
        except Exception as e:
            print(f"Pygame error: {e}")
        finally:
            try:
                import pygame
                pygame.mixer.quit()
            except:
                pass


class SubprocessSilencePlayer(SilencePlayer):
    """Subprocess-based silence player using aplay (system fallback)."""

    def __init__(self):
        super().__init__()
        self.process = None

    def _play_loop(self):
        """Play silence using aplay subprocess."""
        try:
            import subprocess
            import tempfile
            import wave
            import os

            # Create a temporary WAV file with 1 second of silence
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp_file:
                wav_path = tmp_file.name

            # Generate 1 second of silence WAV file
            sample_rate = 44100
            duration = 1.0
            frames = int(sample_rate * duration)

            with wave.open(wav_path, 'w') as wav_file:
                wav_file.setnchannels(2)  # Stereo
                wav_file.setsampwidth(2)  # 16-bit
                wav_file.setframerate(sample_rate)
                wav_file.writeframes(b'\x00' * (frames * 4))  # 4 bytes per frame (2 channels * 2 bytes)

            print("Using aplay subprocess backend")

            while self.running:
                try:
                    # Play the silence file and wait for it to complete
                    result = subprocess.run(['aplay', wav_path],
                                          stdout=subprocess.DEVNULL,
                                          stderr=subprocess.DEVNULL,
                                          timeout=2.0)
                    if not self.running:
                        break
                except subprocess.TimeoutExpired:
                    pass
                except FileNotFoundError:
                    print("aplay command not found. Please install alsa-utils.")
                    break

        except Exception as e:
            print(f"Subprocess error: {e}")
        finally:
            # Clean up temporary file
            try:
                if 'wav_path' in locals():
                    os.unlink(wav_path)
            except:
                pass


def signal_handler(signum, frame):
    """Handle Ctrl+C gracefully."""
    print("\nReceived interrupt signal. Stopping...")
    sys.exit(0)


def main():
    parser = argparse.ArgumentParser(description="Play silence indefinitely to keep audio system active")
    parser.add_argument('--backend', choices=['pyaudio', 'pygame', 'subprocess'],
                       default='auto', help='Audio backend to use (default: auto)')
    parser.add_argument('--sample-rate', type=int, default=44100,
                       help='Sample rate in Hz (default: 44100)')
    parser.add_argument('--chunk-size', type=int, default=1024,
                       help='Chunk size for audio buffer (default: 1024)')

    args = parser.parse_args()

    # Set up signal handler for graceful shutdown
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    player = None

    try:
        # Try backends in order of preference
        if args.backend == 'auto':
            backends = ['pyaudio', 'pygame', 'subprocess']
        else:
            backends = [args.backend]

        for backend in backends:
            try:
                if backend == 'pyaudio':
                    player = PyAudioSilencePlayer(args.sample_rate, args.chunk_size)
                elif backend == 'pygame':
                    player = PygameSilencePlayer(args.sample_rate, args.chunk_size)
                elif backend == 'subprocess':
                    player = SubprocessSilencePlayer()

                break

            except ImportError as e:
                print(f"Backend {backend} not available: {e}")
                if args.backend != 'auto':
                    sys.exit(1)
                continue

        if not player:
            print("No audio backend available. Please install pyaudio or pygame.")
            sys.exit(1)

        print("Starting silence player... Press Ctrl+C to stop.")
        player.start()

        # Keep main thread alive
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            pass

    finally:
        if player:
            print("Stopping silence player...")
            player.stop()
            print("Stopped.")


if __name__ == '__main__':
    main()