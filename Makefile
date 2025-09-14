SWIFT_BUILD_FLAGS?=

.PHONY: build run test clean

build:
	swift build $(SWIFT_BUILD_FLAGS)

run:
	swift run $(SWIFT_BUILD_FLAGS) remindian $(ARGS)

test:
	swift test $(SWIFT_BUILD_FLAGS)

clean:
	rm -rf .build
