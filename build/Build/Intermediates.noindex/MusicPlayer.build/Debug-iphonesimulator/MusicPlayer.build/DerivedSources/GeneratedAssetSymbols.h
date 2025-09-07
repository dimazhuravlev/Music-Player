#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "Anasheed" asset catalog image resource.
static NSString * const ACImageNameAnasheed AC_SWIFT_PRIVATE = @"Anasheed";

/// The "EveningAzkar" asset catalog image resource.
static NSString * const ACImageNameEveningAzkar AC_SWIFT_PRIVATE = @"EveningAzkar";

/// The "MorningAzkar" asset catalog image resource.
static NSString * const ACImageNameMorningAzkar AC_SWIFT_PRIVATE = @"MorningAzkar";

/// The "Ruqya" asset catalog image resource.
static NSString * const ACImageNameRuqya AC_SWIFT_PRIVATE = @"Ruqya";

/// The "album" asset catalog image resource.
static NSString * const ACImageNameAlbum AC_SWIFT_PRIVATE = @"album";

/// The "backward" asset catalog image resource.
static NSString * const ACImageNameBackward AC_SWIFT_PRIVATE = @"backward";

/// The "dislike-active" asset catalog image resource.
static NSString * const ACImageNameDislikeActive AC_SWIFT_PRIVATE = @"dislike-active";

/// The "dislike-default" asset catalog image resource.
static NSString * const ACImageNameDislikeDefault AC_SWIFT_PRIVATE = @"dislike-default";

/// The "forward" asset catalog image resource.
static NSString * const ACImageNameForward AC_SWIFT_PRIVATE = @"forward";

/// The "like-active" asset catalog image resource.
static NSString * const ACImageNameLikeActive AC_SWIFT_PRIVATE = @"like-active";

/// The "like-default" asset catalog image resource.
static NSString * const ACImageNameLikeDefault AC_SWIFT_PRIVATE = @"like-default";

/// The "pause" asset catalog image resource.
static NSString * const ACImageNamePause AC_SWIFT_PRIVATE = @"pause";

/// The "play" asset catalog image resource.
static NSString * const ACImageNamePlay AC_SWIFT_PRIVATE = @"play";

#undef AC_SWIFT_PRIVATE
