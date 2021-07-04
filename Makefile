COMPILE=coffee --bare
DELETE=rm -rf
CREATE=mkdir
ROOT_DIR=$${PWD}
SRC_DIR=${ROOT_DIR}/src
BUILD_DIR=${ROOT_DIR}/build
SRC_FILES=$(shell find ${SRC_DIR} -name "*.coffee")


deploy: build
	grunt screeps


build: clean
	$(CREATE) $(BUILD_DIR)
	$(COMPILE)  \
		--output $(BUILD_DIR) \
		--compile $(SRC_FILES)


show:
	$(COMPILE) \
	--print $(SRC_FILES)


clean:
	$(DELETE) $(BUILD_DIR)
