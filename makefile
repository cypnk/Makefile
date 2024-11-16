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


# mkdir helper
MKDIR_P		?= mkdir -p

# Compiler detect
CC		?= clang
CXX		?= clang++
AS		?= clang
COMPILER_NAME	?= Unknown

# Compiler flags
ifeq ( $(CC), clang )
	CFLAGS		+= -fsanitize=address -Wall -Wextra -O2
	COMPILER_NAME	= Clang
endif

ifeq ( $(CC), gcc )
	CFLAGS		+= -fsanitize=address -Wall -Wextra -O2
	COMPILER_NAME	= GCC
endif

ifeq ($(CXX), clang++)
	CXXFLAGS	+= -fsanitize=address -Wall -Wextra -Wconversion \
		-Wunreachable-code -Wshadow -Werror -pedantic -std=c++17 -O2
	
	COMPILER_NAME	= Clang++
endif

ifeq ($(CXX), g++)
	CXXFLAGS	+= -fsanitize=address -Wall -Wextra -Wconversion \
		-Wunreachable-code -Wshadow -Werror -pedantic -std=c++17 -O2
	
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

# Default build target
all: $(TARGET)
	$(MKDIR_P) $(BUILD_DIR)/obj/c $(BUILD_DIR)/obj/cpp
	check-version $(TARGET)

# Check compiler version
check-version:
	@echo "Compiler $(COMPILER_NAME)" > $(BUILD_LOG)
	@$(CC) --version | head -n 1 >> $(BUILD_LOG)



# Executable linking
$(TARGET): $(OBJS)
	@echo "Building. Check $(BUILD_LOG) for details once complete."
	@echo "Linking objects" >> $(BUILD_LOG)
	$(CC) $(OBJS) $(LDFLAGS) -o $(TARGET)


# Dependency generation

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
$(OBJ_DIR)/c/%.c.o: $(SRC_DIR)/%.c $(OBJ_DIR)/c/%.d
	$(MKDIR_P) $(dir $@)
	
	@echo "Compiling C source $<" >> $(BUILD_LOG)
	$(CC) $(CFLAGS) -c $< -o $@

# C++ source
$(OBJ_DIR)/cpp/%.cpp.o: $(SRC_DIR)/%.cpp $(OBJ_DIR)/cpp/%.d
	$(MKDIR_P) $(dir $@)
	
	@echo "Compiling C++ source $<" >> $(BUILD_LOG)
	$(CXX) $(CXXFLAGS) -c $< -o $@


clean:
	$(RM) -rf $(BUILD_DIR)

.PHONY:	all check-version clean


