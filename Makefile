TWEAK_NAME = WebPreview
WebPreview_FILES = WebPreview.m
WebPreview_FRAMEWORKS = Foundation UIKit CoreGraphics

ADDITIONAL_CFLAGS = -std=c99

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
