CC := cc

ODIN := odin
RUN := run
BUILD := build

SRC_DIR := src
OUT_DIR := build

FLAGS_REL := -build-mode:exe -o:none -vet-semicolon

COLLECTIONS := -collection:proj=src

BIN_NAME := hoi4_clone
ifeq ($(PLATFORM),windows)
	BIN_EXT := exe
else
	BIN_EXT :=
endif
BIN_OUT := $(OUT_DIR)/$(BIN_NAME)$(BIN_EXT)

EXTERN_DIR := extern
MA_DIR := miniaudio
MA_FILE := ma.c
MA_OBJ := ma.o
MA_ARC := miniaudio.a

all:
	$(ODIN) $(BUILD) $(SRC_DIR) $(FLAGS_REL) $(COLLECTIONS) -out:$(BIN_OUT)
	$(BIN_OUT)
