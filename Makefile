COMPILE=coffee --bare
DELETE=rm -rf
CREATE=mkdir
TOP_DIR=$(shell pwd)
SRC_DIR=$(TOP_DIR)/src
BUILD_DIR=$(TOP_DIR)/build
TOOL_DIR=$(TOP_DIR)/tools
SRC_FILES=$(shell find $(SRC_DIR) -name "*.coffee")
TOOL_FILES=$(shell find $(TOOL_DIR) -name "*.coffee")


build:
	$(DELETE) $(BUILD_DIR)
	$(CREATE) $(BUILD_DIR)
	$(COMPILE) \
		--output $(BUILD_DIR) \
		--compile $(SRC_FILES)


run: build
	grunt screeps


show:
	$(DELETE) $(BUILD_DIR)
	$(CREATE) $(BUILD_DIR)
	$(COMPILE) \
		--print $(SRC_FILES)


clean:
	$(DELETE) $(BUILD_DIR)
