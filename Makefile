SWIFT_BUILD_FLAGS?=
VERSION?=$(shell git describe --tags --always --dirty 2>/dev/null || echo "0.1.0")
PREFIX?=/usr/local
INSTALL_NAME=remindian

.PHONY: build run test clean binary install dist dist-zip dist-tar uninstall

build:
	swift build $(SWIFT_BUILD_FLAGS)

run:
	swift run $(SWIFT_BUILD_FLAGS) remindian $(ARGS)

test:
	swift test $(SWIFT_BUILD_FLAGS)

# Build an optimized binary for distribution
binary:
	swift build -c release $(SWIFT_BUILD_FLAGS)
	mkdir -p ./bin
	cp -f .build/release/remindian ./bin/
	@echo "Binary created at ./bin/remindian"

# Create a distribution package with binary and documentation
dist: binary
	mkdir -p ./dist/$(INSTALL_NAME)-$(VERSION)
	cp -f ./bin/remindian ./dist/$(INSTALL_NAME)-$(VERSION)/
	cp -f README.md ./dist/$(INSTALL_NAME)-$(VERSION)/
	cp -f LICENSE ./dist/$(INSTALL_NAME)-$(VERSION)/ 2>/dev/null || echo "No LICENSE file found"
	@echo "Distribution package created at ./dist/$(INSTALL_NAME)-$(VERSION)/"

# Create a zip archive of the distribution
dist-zip: dist
	cd ./dist && zip -r $(INSTALL_NAME)-$(VERSION).zip $(INSTALL_NAME)-$(VERSION)
	@echo "Zip archive created at ./dist/$(INSTALL_NAME)-$(VERSION).zip"

# Create a tarball of the distribution
dist-tar: dist
	cd ./dist && tar -czf $(INSTALL_NAME)-$(VERSION).tar.gz $(INSTALL_NAME)-$(VERSION)
	@echo "Tarball created at ./dist/$(INSTALL_NAME)-$(VERSION).tar.gz"

# Install the binary to a standard location
install: binary
	mkdir -p $(PREFIX)/bin
	install ./bin/remindian $(PREFIX)/bin/
	@echo "Installed remindian to $(PREFIX)/bin/"

# Uninstall the binary
uninstall:
	rm -f $(PREFIX)/bin/remindian
	@echo "Uninstalled remindian from $(PREFIX)/bin/"

clean:
	rm -rf .build
	rm -rf ./bin
	rm -rf ./dist
