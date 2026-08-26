PROJECT := hackers-unite
CA65 := ./tools/ca65-strict.sh
LD65 := ld65
C1541 ?= /Applications/Emulators/Vice/bin/c1541
VICE ?= /Applications/Emulators/Vice/bin/x64sc

SOURCES := startup state assets tiles scroll physics objects boss_attack projectile game sound sprites vic_phase3 input irq_phase3 scheduler_phase3
DEBUG_OBJS := $(addprefix build/debug/,$(addsuffix .o,$(SOURCES)))
RELEASE_OBJS := $(addprefix build/release/,$(addsuffix .o,$(SOURCES)))
TEST_OBJS := $(addprefix build/test/,$(addsuffix .o,$(SOURCES)))
SOAK_OBJS := $(addprefix build/soak/,$(addsuffix .o,$(SOURCES)))
PREVIEW_OBJS := $(addprefix build/preview/,$(addsuffix .o,$(SOURCES)))
DEPS := $(DEBUG_OBJS:.o=.d) $(RELEASE_OBJS:.o=.d) $(TEST_OBJS:.o=.d) $(SOAK_OBJS:.o=.d) $(PREVIEW_OBJS:.o=.d)
CAFLAGS := -I src --cpu 6502 -D PHASE4_BUILD=1
LDFLAGS := -C cfg/c64.cfg

.PHONY: all build debug release preview run test soak disk assets c64-assets validate-assets validate-source clean

C64_ASSETS := assets/c64/charset.bin assets/c64/metatile-chars.bin assets/c64/metatile-colors.bin assets/c64/metatile-flags.bin assets/c64/static-map.bin assets/c64/world-chars.bin assets/c64/row-colors.bin assets/c64/player-sprites.bin assets/c64/object-sprites.bin assets/c64/stance-sprites.bin assets/c64/projectile-sprite.bin assets/c64/bomb-sprite.bin assets/c64/boss-sprite.bin assets/c64/action-sprites.bin assets/c64/level-layout-patches.bin assets/c64/asset-manifest.json
C64_ASSET_STAMP := build/assets/c64-assets.stamp
SID_SOURCE := assets/source/Madness_part_1.sid
SID_ASSET := assets/c64/madness-part-1.bin
SID_METADATA := assets/c64/madness-part-1.json
PHASE2_ASSETS := $(C64_ASSETS) $(SID_ASSET) $(SID_METADATA)

all: build
build: validate-source debug release
debug: validate-source build/debug/$(PROJECT).prg
release: validate-source release/$(PROJECT).prg
preview: validate-source build/preview/$(PROJECT)-phase12.prg

build/debug/%.o: src/%.s $(PHASE2_ASSETS)
	@mkdir -p $(@D)
	$(CA65) $(CAFLAGS) -D DEBUG_BUILD=1 -g --create-dep $(@:.o=.d) -l $(@:.o=.lst) -o $@ $<

build/release/%.o: src/%.s $(PHASE2_ASSETS)
	@mkdir -p $(@D)
	$(CA65) $(CAFLAGS) --create-dep $(@:.o=.d) -o $@ $<

build/test/%.o: src/%.s $(PHASE2_ASSETS)
	@mkdir -p $(@D)
	$(CA65) $(CAFLAGS) -D DEBUG_BUILD=1 -D AUTOTEST=1 -g --create-dep $(@:.o=.d) -o $@ $<

build/soak/%.o: src/%.s $(PHASE2_ASSETS)
	@mkdir -p $(@D)
	$(CA65) $(CAFLAGS) -D DEBUG_BUILD=1 -D AUTOTEST=1 -D SOAK_TEST=1 -g --create-dep $(@:.o=.d) -o $@ $<

build/preview/%.o: src/%.s $(PHASE2_ASSETS)
	@mkdir -p $(@D)
	$(CA65) $(CAFLAGS) -D PHASE12_PREVIEW=1 --create-dep $(@:.o=.d) -o $@ $<

build/debug/$(PROJECT).prg: $(DEBUG_OBJS) cfg/c64.cfg
	$(LD65) $(LDFLAGS) -m build/debug/$(PROJECT).map -Ln build/debug/$(PROJECT).lbl --dbgfile build/debug/$(PROJECT).dbg -o $@ $(DEBUG_OBJS)

release/$(PROJECT).prg: $(RELEASE_OBJS) cfg/c64.cfg
	@mkdir -p release
	$(LD65) $(LDFLAGS) -m release/$(PROJECT).map -Ln release/$(PROJECT).lbl -o $@ $(RELEASE_OBJS)

build/test/$(PROJECT)-test.prg: $(TEST_OBJS) cfg/c64-test.cfg
	$(LD65) -C cfg/c64-test.cfg -m build/test/$(PROJECT).map -Ln build/test/$(PROJECT).lbl -o $@ $(TEST_OBJS)

build/soak/$(PROJECT)-soak.prg: $(SOAK_OBJS) cfg/c64-test.cfg
	$(LD65) -C cfg/c64-test.cfg -m build/soak/$(PROJECT).map -Ln build/soak/$(PROJECT).lbl -o $@ $(SOAK_OBJS)

build/preview/$(PROJECT)-phase12.prg: $(PREVIEW_OBJS) cfg/c64.cfg
	$(LD65) $(LDFLAGS) -m build/preview/$(PROJECT).map -Ln build/preview/$(PROJECT).lbl -o $@ $(PREVIEW_OBJS)

run: build/debug/$(PROJECT).prg
	$(VICE) -pal -autostartprgmode 1 -autostart $<

test: validate-source validate-assets build/test/$(PROJECT)-test.prg release/$(PROJECT).prg
	./tests/host_checks.sh
	./tests/vice_smoke.sh "$(VICE)" "build/test/$(PROJECT)-test.prg"

soak: validate-source validate-assets build/soak/$(PROJECT)-soak.prg
	./tests/vice_soak.sh "$(VICE)" "build/soak/$(PROJECT)-soak.prg"

disk: validate-source release/$(PROJECT).d64

assets: c64-assets
	./tools/build_visual_assets.sh

c64-assets: $(PHASE2_ASSETS)

$(C64_ASSETS): $(C64_ASSET_STAMP)
	@test -s $@

$(C64_ASSET_STAMP): tools/build_c64_assets.py
	@mkdir -p $(@D)
	python3 tools/build_c64_assets.py
	@touch $@

$(SID_ASSET) $(SID_METADATA): $(SID_SOURCE) tools/import_sid.py
	python3 tools/import_sid.py $(SID_SOURCE) $(SID_SOURCE) $(SID_ASSET) $(SID_METADATA)

validate-assets: c64-assets
	python3 tools/validate_assets.py

validate-source:
	python3 tools/validate_source_merge.py

release/$(PROJECT).d64: release/$(PROJECT).prg
	@mkdir -p release
	$(C1541) -format "hackers unite,hu" d64 $@ -write $< "hackers unite"

clean:
	rm -rf build release

-include $(DEPS)
