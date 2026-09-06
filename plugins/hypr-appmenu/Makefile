# hypr-appmenu - org_kde_kwin_appmenu support for Hyprland
#
# Plain Makefile on purpose: neither cmake nor meson is installed on this box.
# `make` is what hyprpm invokes too, so this stays compatible with it.

PLUGIN      := hypr-appmenu
TARGET      := $(PLUGIN).so

SRC_DIR     := src
GEN_DIR     := $(SRC_DIR)/protocols
OBJ_DIR     := build

# Shipped by qt6-wayland. Do not hand-write a copy of this.
PROTO_XML   ?= /usr/share/qt6/wayland/protocols/appmenu/appmenu.xml
SCANNER     ?= hyprwayland-scanner

GEN_HDR     := $(GEN_DIR)/appmenu.hpp
GEN_SRC     := $(GEN_DIR)/appmenu.cpp

SOURCES     := $(SRC_DIR)/main.cpp $(SRC_DIR)/AppmenuProtocol.cpp $(GEN_SRC)
OBJECTS     := $(patsubst %.cpp,$(OBJ_DIR)/%.o,$(SOURCES))

CXX         ?= g++

# --no-gnu-unique is required for plugins: without it the .so can never be
# unloaded and `hyprctl plugin unload` leaks / misbehaves.
CXXFLAGS    += -std=c++2b -fPIC --no-gnu-unique -Wall -Wno-unused-parameter -O2 -g
CXXFLAGS    += -I$(SRC_DIR)
CXXFLAGS    += $(shell pkg-config --cflags hyprland pixman-1 libdrm wayland-server)

LDFLAGS     += -shared

.PHONY: all clean protocols

all: $(TARGET)

protocols: $(GEN_HDR) $(GEN_SRC)

# hyprwayland-scanner emits appmenu.hpp + appmenu.cpp into the output dir.
$(GEN_HDR) $(GEN_SRC): $(PROTO_XML)
	@mkdir -p $(GEN_DIR)
	$(SCANNER) $(PROTO_XML) $(GEN_DIR)

$(OBJ_DIR)/%.o: %.cpp $(GEN_HDR)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(TARGET): $(OBJECTS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(OBJECTS) -o $(TARGET)

clean:
	rm -rf $(OBJ_DIR) $(TARGET) $(GEN_DIR)
