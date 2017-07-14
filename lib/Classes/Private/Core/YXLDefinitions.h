
#define WEAKIFY_SELF	\
    __weak __typeof__((self)) self##__weak = (self)

#define STRONGIFY_SELF	\
    __strong __typeof__((self##__weak)) self = (self##__weak)

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
    #define YXL_USE_WEBVIEW 1
#endif
