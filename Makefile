# -*- makefile -*- --- yohe, An editor made in C, for C.
#
#                         Version: v0.13                           ++++++++++++
#  
#                   Documentation: Refer to README.                ++++++++++++
#
#  CHANGELOG:
#
#  ==== Added ==== 
#	- (v0.13) Added some placeholder .c files to each library
#	- (v0.13) Added library creation
#	- (v0.11) Added Libraries/ subdirs
#	- (v0.10) Added basic YohE project structure
#	- (v0.10) Added a Makefile
#
#  ==== Fixed ====
#	- (v0.13) Fixed `make strip` to be handled by make
#	- (v0.12) Fixed gitignore by including bin/
#	- (v0.11) Fixed `make strip` 
#  
#  ==== Removed ====
#  	- (v0.13) Removed LIBRARY.c files
#  	- (v0.11) Removed Core/ dir(s)
#

PROJECT_NAME    := yohe
PROJECT_VERSION := v0.12

CSTD := c11
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

BIN_DIR          := bin/$(ARCH)
LIB_OUT_DIR      := $(BIN_DIR)/libs
TARGET           := $(BIN_DIR)/$(PROJECT_NAME)
INTERMEDIATE_DIR := bin/intermediates

APP_DIR       := YohE/App
LIBRARIES_DIR := YohE/Libraries

APP_SOURCES   := $(shell find $(APP_DIR) -name '*.c' 2>/dev/null)

APP_OBJECTS      := $(APP_SOURCES:%.c=$(INTERMEDIATE_DIR)/%.o)
BACKEND_OBJECTS  := $(shell find $(LIBRARIES_DIR)/Backend/Source -name '*.c' 2>/dev/null | sed 's|^|$(INTERMEDIATE_DIR)/|;s|\.c$$|.o|')
INPUT_OBJECTS    := $(shell find $(LIBRARIES_DIR)/Input/Source   -name '*.c' 2>/dev/null | sed 's|^|$(INTERMEDIATE_DIR)/|;s|\.c$$|.o|')
UNICODE_OBJECTS  := $(shell find $(LIBRARIES_DIR)/Unicode/Source -name '*.c' 2>/dev/null | sed 's|^|$(INTERMEDIATE_DIR)/|;s|\.c$$|.o|')


LIB_BACKEND := $(LIB_OUT_DIR)/libbackend.a
LIB_INPUT   := $(LIB_OUT_DIR)/libinput.a
LIB_UNICODE := $(LIB_OUT_DIR)/libunicode.a
ALL_LIBS    := $(LIB_BACKEND) $(LIB_INPUT) $(LIB_UNICODE)

get_lib_objs = $(shell find $(LIBRARIES_DIR)/$(1)/Source -name '*.c' 2>/dev/null | sed 's|^|$(INTERMEDIATE_DIR)/|;s|\.c$$|.o|')

OBJECTS := $(APP_OBJECTS) $(BACKEND_OBJECTS) $(INPUT_OBJECTS) $(UNICODE_OBJECTS)
DEPS    := $(OBJECTS:.o=.d)

INCLUDES := -I$(APP_DIR) \
	    -I$(APP_DIR)/Headers \
	    -I$(LIBRARIES_DIR) \
	    -I$(LIBRARIES_DIR)/Backend/Source \
	    -I$(LIBRARIES_DIR)/Input/Source \
	    -I$(LIBRARIES_DIR)/Unicode/Source

$(INTERMEDIATE_DIR) $(BIN_DIR) $(LIB_OUT_DIR):
	mkdir -p $@

all: $(TARGET)

$(LIB_BACKEND): $(BACKEND_OBJECTS) | $(LIB_OUT_DIR)
		ar rcs $@ $^

$(LIB_INPUT): $(INPUT_OBJECTS) | $(LIB_OUT_DIR)
		ar rcs $@ $^

$(LIB_UNICODE): $(UNICODE_OBJECTS) | $(LIB_OUT_DIR)
		ar rcs $@ $^

debug: CFLAGS += $(CFLAGS_DEBUG_ADD)
debug: LDFLAGS += $(CFLAGS_DEBUG_ADD)
debug: $(TARGET)

release: CFLAGS += $(CFLAGS_RELEASE_ADD)
release: LDFLAGS += $(LDFLAGS_RELEASE)
release: $(TARGET)

$(TARGET): $(APP_OBJECTS) $(ALL_LIBS) | $(BIN_DIR)
	$(CC) $(APP_OBJECTS) -o $@ -L$(LIB_OUT_DIR) -lbackend -linput -lunicode $(LDFLAGS)

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
ifeq ($(shell uname),Darwin)
	strip -x -S $(TARGET)
else
	strip --strip-all $(TARGET)
endif

size: $(TARGET)
	@echo "Binary size:"
	@ls -lh $(TARGET)
	@size $(TARGET) 2>/dev/null || true

help:
	@echo "Available targets for yohe:"
	@echo "  all          - Build project (default)"
	@echo "  debug        - Build with debug symbols + sanitizers"
	@echo "  release      - Build optimized release version"
	@echo "  run          - Build and run"
	@echo "  run-debug    - Build debug version and run"
	@echo "  clean        - Remove all build files"
	@echo "  strip        - Strip release binary"
	@echo "  size         - Show binary size"
	@echo "  help         - Show this help"

.PHONY: all debug release clean run run-debug strip size help
