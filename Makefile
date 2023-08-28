CXX       := g++
CXX_FLAGS := -Wall -Wextra -std=c++20 -ggdb -fmodules-ts

BIN      := bin
SRC      := src
INCLUDE  := include
LIB      := lib
MODULE   := module

MODS     := $(wildcard $(MODULE)/*.cpp)
MOD_OBJS := $(patsubst $(MODULE)/%.cpp,$(BIN)/%.o,$(MODS))

HEADERS  := $(wildcard $(INCLUDE)/*.hpp)

LIBRARIES   := -lbenchmark -lbenchmark_main -lgtest -lgtest_main -lsqlite3 -lGLEW32 -lglfw3 -lopengl32 -lpthread 
EXECUTABLE  := main

all: $(BIN)/$(EXECUTABLE)

run: all
	./$(BIN)/$(EXECUTABLE)

$(BIN)/%.o: $(MODULE)/%.cpp
	$(CXX) $(CXX_FLAGS) -c $< -o $@

$(BIN)/%.o: $(INCLUDE)/%.hpp
	$(CXX) $(CXX_FLAGS) -c $< -o $@

$(BIN)/$(EXECUTABLE): $(SRC)/*.cpp $(MOD_OBJS) $(HEADERS)
	$(CXX) $(CXX_FLAGS) -I$(INCLUDE) -L$(LIB) $^ -o $@ $(LIBRARIES)

