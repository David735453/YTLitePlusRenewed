ifeq ($(ROOTLESS),1)
THEOS_PACKAGE_SCHEME=rootless
else ifeq ($(ROOTHIDE),1)
THEOS_PACKAGE_SCHEME=roothide
endif

DEBUG=0
FINALPACKAGE=1
ARCHS = arm64
PACKAGE_VERSION = 3.0.1
TARGET := iphone:clang:16.5:13.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = VideoOverlayTweaks
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation SystemConfiguration
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-unused-function -DTWEAK_VERSION=$(PACKAGE_VERSION) "-I.." "-I../YouTubeHeader"
$(TWEAK_NAME)_FILES = Init.x YouSpeed.x YouShare.x YouGetCaption.x Utils/NSBundle+YTLite.m Utils/Reachability.m Utils/YTLUserDefaults.m

include $(THEOS_MAKE_PATH)/tweak.mk
