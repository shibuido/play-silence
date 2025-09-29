/*
 * play_silence.c - A minimal ALSA program to play silence indefinitely
 *
 * Purpose: Solves vokoscreenNG 4.0.1 freezing issue with PulseAudio by
 * keeping the audio subsystem active with a silent stream.
 *
 * Author: Generated for gwwtests/play_silence project
 * License: Public Domain
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <alloca.h>
#include <alsa/asoundlib.h>

/* Global variables for clean shutdown */
static volatile int running = 1;
static snd_pcm_t *pcm_handle = NULL;

/* Signal handler for graceful shutdown */
void signal_handler(int sig) {
    printf("\nReceived signal %d, shutting down gracefully...\n", sig);
    running = 0;
}

/* Setup signal handlers */
void setup_signals() {
    signal(SIGINT, signal_handler);   /* Ctrl+C */
    signal(SIGTERM, signal_handler);  /* termination */
}

/* Initialize ALSA PCM device */
int init_alsa(const char *device_name) {
    snd_pcm_hw_params_t *hw_params;
    unsigned int sample_rate = 44100;
    int dir = 0;
    int err;

    /* Open PCM device for playback */
    err = snd_pcm_open(&pcm_handle, device_name, SND_PCM_STREAM_PLAYBACK, 0);
    if (err < 0) {
        fprintf(stderr, "Error: Cannot open PCM device %s: %s\n",
                device_name, snd_strerror(err));
        return -1;
    }

    /* Allocate hardware parameters structure */
    snd_pcm_hw_params_alloca(&hw_params);

    /* Initialize hardware parameters with default values */
    err = snd_pcm_hw_params_any(pcm_handle, hw_params);
    if (err < 0) {
        fprintf(stderr, "Error: Cannot initialize hw params: %s\n",
                snd_strerror(err));
        return -1;
    }

    /* Set access type to interleaved */
    err = snd_pcm_hw_params_set_access(pcm_handle, hw_params,
                                       SND_PCM_ACCESS_RW_INTERLEAVED);
    if (err < 0) {
        fprintf(stderr, "Error: Cannot set access type: %s\n",
                snd_strerror(err));
        return -1;
    }

    /* Set sample format to 16-bit signed little-endian */
    err = snd_pcm_hw_params_set_format(pcm_handle, hw_params,
                                       SND_PCM_FORMAT_S16_LE);
    if (err < 0) {
        fprintf(stderr, "Error: Cannot set format: %s\n",
                snd_strerror(err));
        return -1;
    }

    /* Set number of channels to stereo */
    err = snd_pcm_hw_params_set_channels(pcm_handle, hw_params, 2);
    if (err < 0) {
        fprintf(stderr, "Error: Cannot set channels: %s\n",
                snd_strerror(err));
        return -1;
    }

    /* Set sample rate */
    err = snd_pcm_hw_params_set_rate_near(pcm_handle, hw_params,
                                          &sample_rate, &dir);
    if (err < 0) {
        fprintf(stderr, "Error: Cannot set sample rate: %s\n",
                snd_strerror(err));
        return -1;
    }

    /* Apply hardware parameters */
    err = snd_pcm_hw_params(pcm_handle, hw_params);
    if (err < 0) {
        fprintf(stderr, "Error: Cannot apply hw params: %s\n",
                snd_strerror(err));
        return -1;
    }

    printf("ALSA initialized successfully:\n");
    printf("  Device: %s\n", device_name);
    printf("  Sample rate: %u Hz\n", sample_rate);
    printf("  Format: 16-bit stereo\n");

    return 0;
}

/* Play silence in a loop */
void play_silence_loop() {
    const int buffer_frames = 1024;  /* Small buffer for low latency */
    /* const int buffer_size = buffer_frames * 2 * sizeof(short); // stereo 16-bit - unused */
    short *silence_buffer;
    snd_pcm_sframes_t frames_written;
    int recovery_attempts = 0;
    const int max_recovery_attempts = 3;

    /* Allocate and zero the silence buffer */
    silence_buffer = calloc(buffer_frames * 2, sizeof(short));
    if (!silence_buffer) {
        fprintf(stderr, "Error: Cannot allocate silence buffer\n");
        return;
    }

    printf("Playing silence... Press Ctrl+C to stop.\n");

    while (running) {
        /* Write silence to the PCM device */
        frames_written = snd_pcm_writei(pcm_handle, silence_buffer, buffer_frames);

        if (frames_written < 0) {
            /* Handle underrun or other errors */
            if (frames_written == -EPIPE) {
                printf("Warning: PCM underrun occurred\n");
                if (snd_pcm_prepare(pcm_handle) < 0) {
                    fprintf(stderr, "Error: Cannot recover from underrun\n");
                    recovery_attempts++;
                    if (recovery_attempts >= max_recovery_attempts) {
                        fprintf(stderr, "Error: Too many recovery attempts, exiting\n");
                        break;
                    }
                    usleep(100000); /* Wait 100ms before retry */
                    continue;
                }
                recovery_attempts = 0; /* Reset counter on successful recovery */
            } else {
                fprintf(stderr, "Error: PCM write failed: %s\n",
                        snd_strerror(frames_written));
                break;
            }
        } else if (frames_written != buffer_frames) {
            /* Partial write - not necessarily an error but log it */
            printf("Warning: Partial write (%ld/%d frames)\n",
                   frames_written, buffer_frames);
        }

        /* Small sleep to prevent excessive CPU usage */
        /* This is optional since ALSA blocking I/O should handle timing */
        usleep(1000); /* 1ms sleep */
    }

    free(silence_buffer);
    printf("Silence playback stopped.\n");
}

/* Cleanup ALSA resources */
void cleanup_alsa() {
    if (pcm_handle) {
        snd_pcm_drain(pcm_handle);  /* Drain remaining samples */
        snd_pcm_close(pcm_handle);  /* Close PCM device */
        pcm_handle = NULL;
        printf("ALSA resources cleaned up.\n");
    }
}

/* Print usage information */
void print_usage(const char *program_name) {
    printf("Usage: %s [device_name]\n", program_name);
    printf("\n");
    printf("Play silence indefinitely using ALSA.\n");
    printf("\n");
    printf("Arguments:\n");
    printf("  device_name    ALSA device name (default: 'default')\n");
    printf("\n");
    printf("Examples:\n");
    printf("  %s                    # Use default ALSA device\n", program_name);
    printf("  %s hw:0,0             # Use hardware device 0, subdevice 0\n", program_name);
    printf("  %s plughw:1,0         # Use hardware device 1 with format conversion\n", program_name);
    printf("\n");
    printf("Press Ctrl+C to stop the program.\n");
}

int main(int argc, char *argv[]) {
    const char *device_name = "default";

    /* Parse command line arguments */
    if (argc > 2) {
        print_usage(argv[0]);
        return 1;
    }

    if (argc == 2) {
        if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
            print_usage(argv[0]);
            return 0;
        }
        device_name = argv[1];
    }

    printf("play_silence - ALSA silence player v1.0\n");
    printf("Purpose: Keep audio subsystem active to prevent vokoscreenNG freezing\n");
    printf("=========================================================================\n\n");

    /* Setup signal handlers for graceful shutdown */
    setup_signals();

    /* Initialize ALSA */
    if (init_alsa(device_name) < 0) {
        cleanup_alsa();
        return 1;
    }

    /* Play silence until interrupted */
    play_silence_loop();

    /* Clean up and exit */
    cleanup_alsa();

    printf("Program terminated successfully.\n");
    return 0;
}