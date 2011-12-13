CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin10-llvm-gcc-4.2
CPP=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin10-llvm-g++-4.2
LD=$(CC)

SDKVER=5.0
SDK=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVER).sdk

LDFLAGS= -framework Foundation \
	-framework UIKit \
	-framework IOKit \
	-framework Security \
	-framework QuartzCore \
	-framework CoreFoundation \
	-framework CoreGraphics \
	-framework Preferences \
	-framework GraphicsServices \
	-L$(SDK)/usr/lib \
	-L$(SDK)/usr/lib/system \
	-F$(SDK)/System/Library/Frameworks \
	-F$(SDK)/System/Library/PrivateFrameworks \
	-lsubstrate \
	-lsqlite3 \
	-lobjc

CFLAGS= -I/var/include \
  -I$(SDK)/var/include \
  -I/var/include/gcc/darwin/4.2 \
  -I../../.. \
  -I"$(SDK)/usr/include" \
  -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/include" \
  -I"/Developer/Platforms/iPhoneOS.platform/Developer/usr/llvm-gcc-4.2/lib/gcc/arm-apple-darwin10/4.2.1/include" \
  -DDEBUG -Diphoneos_version_min=3.0 -g -objc-exceptions \
  -F"$(SDK)/System/Library/Frameworks" \
  -F"$(SDK)/System/Library/PrivateFrameworks"

Name=FacebookPlugin
Bundle=com.burgess.lockinfo.$(Name).bundle

all:	package

$(Name):	KeychainUtils.o FacebookAuth.o FacebookAuthController.o FacebookDeAuthController.o FacebookDonate.o FBSingletons.o FBDownload.o FBOptionsView.o FBPreview.o FBPreviewController.o FBCommentsPreview.o FBNewPostPreview.o FBNotificationsPreview.o FBCommentCell.o FBPostCell.o FBNotificationCell.o FBButtonCell.o FBLikesCell.o FBLoadingCell.o FBTextView.o UIImage-FBAdditions.o PullToRefreshView.o $(Name).o
		$(LD) $(LDFLAGS) -bundle -o $@ $^
		ldid -S $@
		chmod 755 $@

FB: 		KeychainUtils.o FacebookAuth.o FacebookAuthController.o FacebookDeAuthController.o FacebookDonate.o FBSingletons.o FBDownload.o FBOptionsView.o FBPreview.o FBPreviewController.o FBCommentsPreview.o FBNewPostPreview.o FBNotificationsPreview.o FBCommentCell.o FBPostCell.o FBNotificationCell.o FBButtonCell.o FBLikesCell.o FBLoadingCell.o FBTextView.o UIImage-FBAdditions.o PullToRefreshView.o $(Name).o
		$(LD) $(LDFLAGS) -bundle -o FacebookPlugin $^
		ldid -S FacebookPlugin
		chmod 755 FacebookPlugin
		-mkdir ./Plugin
		cp FacebookPlugin ./Plugin/FacebookPlugin

%.o:	%.mm
		$(CPP) -c $(CFLAGS) $< -o $@

clean:
		rm -f *.o $(Name)
		rm -rf package

package: 	$(Name)
	mkdir -p package/DEBIAN
	mkdir -p package/Library/LockInfo/Plugins/$(Bundle)
	cp -r Bundle/* package/Library/LockInfo/Plugins/$(Bundle)
	cp $(Name) package/Library/LockInfo/Plugins/$(Bundle)
	cp control package/DEBIAN
	find package -name .svn -print0 | xargs -0 rm -rf
	dpkg-deb -b package $(Name)_$(shell grep ^Version: control | cut -d ' ' -f 2).deb
