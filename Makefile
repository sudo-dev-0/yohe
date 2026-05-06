# -*- makefile -*- --- yohe, An editor made in C, for C.
#
#                         Version: v0.10                           ++++++++++++
#  
#                   Documentation: Refer to README.                ++++++++++++
#
#  CHANGELOG:
#
#  ==== Added ==== 
#	- (v0.10) Basic yohe project structure
#	- (v0.10) Added a Makefile
#
#  ==== Fixed ====
#  
#  ==== Removed ====
#

# Code:

PROJECT_NAME    :=  yohe
PROJECT_VERSION := v0.10

CSTD := c99
COPT := 2 	# Release optimization.

CC ?= gcc

UI_BACKEND ?= ncurses

CFLAGS             :=
CFLAGS_DEBUG_ADD   :=
CFLAGS_RELEASE_ADD :=
LDFLAGS_RELEASE    :=

CFLAGS := -std=c11 -pipe -Wall -Wextra -Wpedantic \
    -Wformat=2 -Wformat-security -Wformat-overflow -Wformat-truncation \
    -Wnull-dereference -Wstack-protector -Walloca -Wvla \
    -Warray-bounds -Wshadow -Wimplicit-fallthrough -Wshift-overflow \
    -Wcast-qual -Wconversion -Wsign-conversion \
    -Wstrict-overflow=4 -Wundef -Wstrict-prototypes -Wswitch-default \
    -Wswitch-enum -Wcast-align \
    -Wfloat-equal -Wdouble-promotion -Wmissing-prototypes \
    -fstack-protector-strong -fPIE -fPIC \
    -D_FORTIFY_SOURCE=3

CFLAGS_DEBUG_ADD := -g3 -Og -fno-omit-frame-pointer \
    -fsanitize=undefined -fsanitize-trap=undefined \
    -fsanitize=address -fsanitize=leak \
    -Wno-unused-parameter -Wno-unused-function

CFLAGS_RELEASE_ADD := -O2 -flto -march=native -mtune=native \
    -fstack-clash-protection -DNDEBUG

LDFLAGS_RELEASE := -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -Wl,-z,separate-code \
                   -pie

ARCH := $(shell uname -m)
ifeq ($(ARCH),x86_64)
    ARCH := x86_64
else ifeq ($(ARCH),aarch64)
    ARCH := aarch64
else ifeq ($(ARCH),arm64)
    ARCH := arm64
endif

BIN_DIR := bin/$(ARCH)
TARGET := $(BIN_DIR)/$(PROJECT_NAME)
INTERMEDIATE_DIR := bin/intermediates

CORE_DIR := YohE/Core
APP_DIR  := YohE/App

CORE_SOURCES := $(shell find $(CORE_DIR) -name '*.c')
APP_SOURCES  := $(shell find $(APP_DIR)  -name '*.c')
SOURCES := $(CORE_SOURCES) $(APP_SOURCES)

OBJECTS := $(SOURCES:%.c=$(INTERMEDIATE_DIR)/%.o)
DEPS    := $(OBJECTS:.o=.d)

INCLUDES := -I$(CORE_DIR) -I$(CORE_DIR)/Libraries/Headers \
            -I$(APP_DIR)  -I$(APP_DIR)/Libraries/Headers

$(INTERMEDIATE_DIR) $(BIN_DIR):
	mkdir -p $@

all: $(TARGET)

debug: CFLAGS += $(CFLAGS_DEBUG_ADD)
debug: LDFLAGS += $(CFLAGS_DEBUG_ADD)
debug: $(TARGET)

release: CFLAGS += $(CFLAGS_RELEASE_ADD)
release: LDFLAGS += $(LDFLAGS_RELEASE)
release: $(TARGET)

$(TARGET): $(OBJECTS) | $(BIN_DIR)
	$(CC) $(OBJECTS) -o $@ $(LDFLAGS)

$(INTERMEDIATE_DIR)/%.o: %.c | $(INTERMEDIATE_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -c $< -o $@

-include $(DEPS)

clean:
	rm -rf bin/

run: all
	./$(TARGET)

run-debug: debug
	./$(TARGET)

strip: release
	strip --strip-all $(TARGET)

size: $(TARGET)
	@echo "Binary size:"
	@ls -lh $(TARGET)
	@size $(TARGET)

help:
	@echo "Available targets:"
	@echo "  all          - Build yohe (default)"
	@echo "  debug        - Build with debug + sanitizers"
	@echo "  release      - Build optimized release"
	@echo "  run          - Build and run"
	@echo "  run-debug    - Build debug and run"
	@echo "  clean        - Remove all build artifacts"
	@echo "  strip        - Strip release binary"
	@echo "  size         - Show binary size information"
	@echo "  help         - Show this help"

.PHONY: all debug release clean run run-debug strip size help
