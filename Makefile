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

# for qt: pacman -S mingw-w64-x86_64-qt5
# -lQt5Charts -lQt5Core -lQt5Gui -lQt5Widgets -lQt5OpenGL -lQt5Multimedia -lQt5MultimediaWidgets -lQt5Network -lQt5PrintSupport -lQt5Qml -lQt5Quick -lQt5QuickWidgets -lQt5Sensors -lQt5Sql -lQt5Svg -lQt5Test -lQt5WebChannel -lQt5WebSockets -lQt5Widgets -lQt5Xml -lQt5XmlPatterns
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

