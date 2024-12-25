# Common build makefile

# Inspired by the excellent article: 
# https://spin.atomicobject.com/2016/08/26/makefile-c-projects/

# Sources directory
SRC_DIR		?= ./src

# Build objects directory (will be created if it doesn't exist)
BUILD_DIR	?= ./build

# Binaries location
BIN_DIR		?= ./bin

# Executable out (rename this to your own)
TARGET		?= $(BIN_DIR)/executable

# Object files
OBJ_DIR		?= $(BUILD_DIR)/obj

# Build log
BUILD_LOG	?= $(BUILD_DIR)/build.log


# Compiler flags

# Assembly flags
ASFLAGS		?=

# C flags
CFLAGS		?=

# C++ Flags
CXXFLAGS	?=

# Linker flags (defaults to static linking)
LDFLAGS		?= -Wl -Bstatic



# End custom options

# Default compilers
CC		?= clang
CXX		?= clang++
AS		?= clang
COMPILER_NAME	?= Unknown

# Compiler flags
CFLAGS		+= -fsanitize=address -Wall -Wextra -O2
CXXFLAGS	+= -fsanitize=address -Wall -Wextra -Wconversion \
		-Wunreachable-code -Wshadow -Werror -pedantic -std=c++17 -O2

# Platform detect
ifeq ($(OS),)
	UNAME_S	:= $(shell uname -s)
	ifeq ($(UNAME_S),Darwin)
		OS = Darwin
	else ifeq ($(UNAME_S),Linux)
		OS = Linux
	else
		OS = Unix
	endif
endif

# Helpers
ifeq ($(OS),Windows_NT)
	MKDIR_P		= mkdir
	RMDIR		= if exist $(1) rmdir /s /q $(1)
else
	MKDIR_P		= mkdir -p
	RMDIR		= rm -rf $(1)
endif

# Compiler detect
ifeq ( $(CC), clang )
	COMPILER_NAME	= Clang
endif

ifeq ( $(CC), gcc )
	COMPILER_NAME	= GCC
endif

ifeq ($(CXX), clang++)
	COMPILER_NAME	= Clang++
endif

ifeq ($(CXX), g++)
	COMPILER_NAME	= G++
endif


# Find sources
ASM_SRCS	:= $(shell find $(SRC_DIR) -name '*.s')
C_SRCS		:= $(shell find $(SRC_DIR) -name '*.c')
CPP_SRCS	:= $(shell find $(SRC_DIR) -name '*.cpp')

# Create object paths
ASM_OBJS	:= $(patsubst $(SRC_DIR)/%, $(OBJ_DIR)/asm/%, $(ASM_SRCS:.s=.o))
C_OBJS		:= $(patsubst $(SRC_DIR)/%, $(OBJ_DIR)/c/%, $(C_SRCS:.c=.o))
CPP_OBJS	:= $(patsubst $(SRC_DIR)/%, $(OBJ_DIR)/cpp/%, $(CPP_SRCS:.cpp=.o))

# Dependencies
C_DEPS		:= $(patsubst $(SRC_DIR)/%, $(OBJ_DIR)/c/%, $(C_SRCS:.c=.d))
CPP_DEPS	:= $(patsubst $(SRC_DIR)/%, $(OBJ_DIR)/cpp/%, $(CPP_SRCS:.cpp=.d))

# Combined dependencies
DEPS		:= $(C_DEPS) $(CPP_DEPS)

# Combined objects
OBJS		:= $(ASM_OBJS) $(C_OBJS) $(CPP_OBJS)

# Set linker
ifneq ($(strip $(CPP_SRCS)),)
	LINKER = $(CXX)
else
	LINKER = $(CC)
endif

# Default build target
all: $(TARGET)
	$(MKDIR_P) $(BUILD_DIR)/obj/c $(BUILD_DIR)/obj/cpp
	check-version $(TARGET)

# Check compiler version
check-version:
	@echo "Compiler $(COMPILER_NAME)" > $(BUILD_LOG)
	@$(LINKER) --version | head -n 1 >> $(BUILD_LOG)


# Executable linking
$(TARGET): $(OBJS)
	@echo "Building. Check $(BUILD_LOG) for details once complete."
	@echo "Linking objects" >> $(BUILD_LOG)
	$(MKDIR_P) $(BIN_DIR)
	$(LINKER) $(OBJS) $(LDFLAGS) -o $(TARGET)


# Dependency generation

# Assembly dependencies
$(OBJ_DIR)/asm/%.d: $(SRC_DIR)/%.s
	$(MKDIR_P) $(dir $@)
	@echo "Dependency for $<" >> $(BUILD_LOG)
	$(AS) -MMD -MP $(ASFLAGS) $< > $@

# C dependencies
$(OBJ_DIR)/c/%.d: $(SRC_DIR)/%.c
	$(MKDIR_P) $(dir $@)
	
	@echo "Dependency for $<" >> $(BUILD_LOG)
	$(CC) -MMD -MP $(CFLAGS) $< > $@

# C++ dependencies
$(OBJ_DIR)/cpp/%.d: $(SRC_DIR)/%.cpp
	$(MKDIR_P) $(dir $@)
	
	@echo "Dependency for $<" >> $(BUILD_LOG)
	$(CXX) -MMD -MP $(CXXFLAGS) $< > $@

# Add dependencies
-include $(DEPS)


# Compilation 

# Assembly to object files
$(OBJ_DIR)/asm/%.o: $(SRC_DIR)/%.s $(OBJ_DIR)/asm/%.d
	$(MKDIR_P) $(dir $@)
	
	@echo "Compiling Assembly source $<" >> $(BUILD_LOG)
	$(AS) $(ASFLAGS) -c $< -o $@
	
# C source
$(OBJ_DIR)/c/%.o: $(SRC_DIR)/%.c $(OBJ_DIR)/c/%.d
	$(MKDIR_P) $(dir $@)
	
	@echo "Compiling C source $<" >> $(BUILD_LOG)
	$(CC) $(CFLAGS) -c $< -o $@

# C++ source
$(OBJ_DIR)/cpp/%.o: $(SRC_DIR)/%.cpp $(OBJ_DIR)/cpp/%.d
	$(MKDIR_P) $(dir $@)
	
	@echo "Compiling C++ source $<" >> $(BUILD_LOG)
	$(CXX) $(CXXFLAGS) -c $< -o $@


clean:
	$(call RMDIR,$(BUILD_DIR))

clean-obj:
	$(call RMDIR,$(BUILD_DIR)/obj)

distclean: clean
	$(call RMDIR,$(BIN_DIR))

.PHONY:	all check-version clean


