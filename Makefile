# Compiler
CXX = g++

# Compiler Flags
CXXFLAGS = -Wall -Wextra -Werror -pedantic -Wshadow -Wnon-virtual-dtor -Wold-style-cast \
           -Wcast-align -Wunused -Woverloaded-virtual -Wconversion -Wsign-conversion \
           -Wmisleading-indentation -Wduplicated-cond -Wduplicated-branches \
           -Wlogical-op -Wnull-dereference -Wuseless-cast -Wdouble-promotion

CXXFLAGS += -march=sandybridge

# Sources
SRCS = $(wildcard *.cpp)

# Object Files
OBJS = $(SRCS:.cpp=.o)

# Output Executable
TARGET = build

# Rules
all: $(TARGET)

bootsector_code.bin: bootsector_code.s
	as -o bootsector_code.o bootsector_code.s
	ld -o bootsector_code.bin -Ttext 0x7C00 --oformat binary bootsector_code.o

$(TARGET): $(OBJS) bootsector_code.bin
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(OBJS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)
	rm -f bootsector_code.bin
	rm -f bootsector_code.o
	rm -f disk.img

qemu_run:
	qemu-system-x86_64 -drive file=disk.img,format=raw -boot c

qemu_dbg:
	@echo "Starting QEMU with debugging enabled..."
	qemu-system-x86_64 -drive file=disk.img,format=raw -s -S &
	@echo "Starting GDB for debugging..."
	gdb-multiarch -ex "target remote :1234" -ex "b *0x7c00"

.PHONY: all clean qemu_run qemu_dbg