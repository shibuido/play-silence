# Makefile for play_silence - ALSA silence player
#
# Purpose: Compiles the play_silence program to solve vokoscreenNG 4.0.1
# freezing issues with PulseAudio by keeping audio subsystem active.

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
LDFLAGS = -lasound

# Target executable
TARGET = play_silence
SOURCE = play_silence.c

# Default target
all: $(TARGET)

# Build the executable
$(TARGET): $(SOURCE)
	@echo "Compiling $(TARGET)..."
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(LDFLAGS)
	@echo "Build complete: $(TARGET)"
	@echo ""
	@echo "Usage: ./$(TARGET) [device_name]"
	@echo "Run './$(TARGET) --help' for more information."

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(TARGET)
	@echo "Clean complete."

# Install to /usr/local/bin (requires sudo)
install: $(TARGET)
	@echo "Installing $(TARGET) to /usr/local/bin..."
	sudo cp $(TARGET) /usr/local/bin/
	sudo chmod 755 /usr/local/bin/$(TARGET)
	@echo "Installation complete. You can now run '$(TARGET)' from anywhere."

# Uninstall from /usr/local/bin (requires sudo)
uninstall:
	@echo "Uninstalling $(TARGET) from /usr/local/bin..."
	sudo rm -f /usr/local/bin/$(TARGET)
	@echo "Uninstall complete."

# Check if ALSA development libraries are installed
check-deps:
	@echo "Checking for ALSA development libraries..."
	@if pkg-config --exists alsa; then \
		echo "✓ ALSA development libraries found"; \
		pkg-config --modversion alsa; \
	else \
		echo "✗ ALSA development libraries not found"; \
		echo ""; \
		echo "Install with:"; \
		echo "  Ubuntu/Debian: sudo apt-get install libasound2-dev"; \
		echo "  Fedora/RHEL:   sudo dnf install alsa-lib-devel"; \
		echo "  Arch Linux:    sudo pacman -S alsa-lib"; \
		echo "  openSUSE:      sudo zypper install alsa-devel"; \
		exit 1; \
	fi

# Test compilation without linking
test-compile: check-deps
	@echo "Testing compilation..."
	$(CC) $(CFLAGS) -c $(SOURCE) -o $(TARGET).o
	@echo "✓ Compilation test passed"
	rm -f $(TARGET).o

# Run the program with default settings
run: $(TARGET)
	@echo "Running $(TARGET) with default ALSA device..."
	@echo "Press Ctrl+C to stop."
	@echo ""
	./$(TARGET)

# Show help
help:
	@echo "Makefile for play_silence - ALSA silence player"
	@echo ""
	@echo "Available targets:"
	@echo "  all           Build the executable (default)"
	@echo "  clean         Remove build artifacts"
	@echo "  install       Install to /usr/local/bin (requires sudo)"
	@echo "  uninstall     Remove from /usr/local/bin (requires sudo)"
	@echo "  check-deps    Check if ALSA development libraries are installed"
	@echo "  test-compile  Test compilation without linking"
	@echo "  run           Build and run with default settings"
	@echo "  help          Show this help message"
	@echo ""
	@echo "Dependencies:"
	@echo "  - ALSA development libraries (libasound2-dev)"
	@echo "  - GCC compiler"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Build the program"
	@echo "  make check-deps         # Check dependencies"
	@echo "  make run                # Build and run"
	@echo "  make install            # Install system-wide"

# Declare phony targets
.PHONY: all clean install uninstall check-deps test-compile run help