APP = build/Caffeinate\ UI.app
CONTENTS = $(APP)/Contents
BINARY = $(CONTENTS)/MacOS/CaffeinateUI
SOURCES = Sources/CaffeinateUI.swift Sources/CaffeinateApp.swift

.PHONY: all run
all: $(CONTENTS)/_CodeSignature/CodeResources

$(BINARY): $(SOURCES) Makefile
	mkdir -p $(CONTENTS)/MacOS build/module-cache
	xcrun --sdk macosx swiftc -O -target "$(shell uname -m)-apple-macos13.0" -module-cache-path build/module-cache $(SOURCES) -o "$@"

$(CONTENTS)/Info.plist: Info.plist
	mkdir -p $(CONTENTS)
	cp "$<" "$@"

$(CONTENTS)/_CodeSignature/CodeResources: $(BINARY) $(CONTENTS)/Info.plist
	codesign --force --sign - $(APP)

run: all
	open $(APP)
