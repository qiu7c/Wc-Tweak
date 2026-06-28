# Theos Makefile
# 构建命令: make package
# 清理: make clean

THEOS_PACKAGE_SCHEME = rootless

TARGET := iphone:clang:latest:16.0
ARCHS := arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WcPlus

# 源文件
WcPlus_FILES = Tweak.xm DayNightSwitch.m
WcPlus_CFLAGS = -fobjc-arc
WcPlus_FRAMEWORKS = UIKit Foundation QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk
