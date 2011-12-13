#import <Foundation/Foundation.h>

#define FB_DEBUG

#ifdef FB_DEBUG
#    define DLog(...) NSLog(__VA_ARGS__)
#else
#    define DLog(...) 
#endif

#define ALog(...) NSLog(__VA_ARGS__)

#define localize(str) \
[[NSBundle bundleWithIdentifier:@"com.burgess.lockinfo.FacebookPlugin"] localizedStringForKey:str value:str table:nil]

#define Hook(cls, sel, imp) \
_ ## imp = MSHookMessage($ ## cls, @selector(sel), &$ ## imp)

extern "C" CFStringRef UIDateFormatStringForFormatType(CFStringRef type);

@interface UIKeyboard : UIView

+(UIKeyboard*) activeKeyboard;
+(void) initImplementationNow;
+(CGSize) defaultSize;

@end

@interface UIProgressIndicator : UIView

+(CGSize) defaultSizeForStyle:(int) size;
-(void) setStyle:(int) style;
-(void)startAnimation;

@end

@interface JSON

+ (id)objectWithData:(NSData*) data options:(unsigned) options error:(NSError**) error;
+ (id)stringWithObject:(id)arg1 options:(unsigned int)arg2 error:(id *)arg3;

@end