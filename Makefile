COMPILE=coffee --bare
DELETE=rm -rf
CREATE=mkdir
TOP_DIR=~/workplace/coffeebot
SRC_DIR=$(TOP_DIR)/src
BUILD_DIR=$(TOP_DIR)/build
TOOL_DIR=$(TOP_DIR)/tools
PROD_DIR=/Users/robbie/Library/Application\ Support/Screeps/scripts/screeps.com/default
BIN_DIR=$(TOP_DIR)/bin
SRC_FILES=$(shell find $(SRC_DIR) -name "*.coffee")
TOOL_FILES=$(shell find $(TOOL_DIR) -name "*.coffee")


default:
	$(DELETE) $(BUILD_DIR)
	$(CREATE) $(BUILD_DIR)
	$(COMPILE) \
		--output $(BUILD_DIR) \
		--compile $(SRC_FILES)


show:
	$(DELETE) $(BUILD_DIR)
	$(CREATE) $(BUILD_DIR)
	$(COMPILE) \
		--print $(SRC_FILES)


run:
	$(DELETE) $(PROD_DIR)
	$(COMPILE) \
		--output $(PROD_DIR) \
		--compile $(SRC_FILES)


tools:
	$(DELETE) $(BIN_DIR)
	$(CREATE) $(BIN_DIR)
	$(COMPILE) \
		--output $(BIN_DIR) \
	    --compile $(TOOL_FILES)


clean:
	$(DELETE) $(BUILD_DIR)
	$(DELETE) $(BIN_DIR) 


uberclean:
	$(DELETE) $(PROD_DIR)
