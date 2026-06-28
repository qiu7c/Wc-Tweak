# Theos Makefile
# 构建命令: make package
# 清理: make clean

THEOS_PACKAGE_SCHEME = rootless

TARGET := iphone:clang:latest:16.0
ARCHS := arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ForeignAppEnhancer

# 源文件
ForeignAppEnhancer_FILES = Tweak.xm
ForeignAppEnhancer_CFLAGS = -fobjc-arc
ForeignAppEnhancer_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
