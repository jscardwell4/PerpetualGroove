//
//  MSKitMacros.h
//  MSKit
//
//  Created by Jason Cardwell on 3/28/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;
#import "MSKitDefines.h"
#import "NSNull+MSKitAdditions.h"
#import "NSString+MSKitAdditions.h"
#import "MSKitLoggingFunctions.h"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Strings
////////////////////////////////////////////////////////////////////////////////

#define isKind(OBJ, CLASS)                 [OBJ isKindOfClass:[CLASS class]]
#define isStringKind(OBJ)                  isKind(OBJ, NSString)
#define isAttributedStringKind(OBJ)        isKind(OBJ, NSAttributedString)
#define isArrayKind(OBJ)                   isKind(OBJ, NSArray)
#define isDictionaryKind(OBJ)              isKind(OBJ, NSDictionary)
#define isSetKind(OBJ)                     isKind(OBJ, NSSet)
#define isOrderedSetKind(OBJ)              isKind(OBJ, NSOrderedSet)
#define isMutableStringKind(OBJ)           isKind(OBJ, NSMutableString)
#define isMutableAttributedStringKind(OBJ) isKind(OBJ, NSMutableAttributedString)
#define isMutableArrayKind(OBJ)            isKind(OBJ, NSMutableArray)
#define isMutableDictionaryKind(OBJ)       isKind(OBJ, NSMutableDictionary)
#define isMutableSetKind(OBJ)              isKind(OBJ, NSMutableSet)
#define isMutableOrderedSetKind(OBJ)       isKind(OBJ, NSMutableOrderedSet)
#define isNumberKind(OBJ)                  isKind(OBJ, NSNumber)   

#define isMember(OBJ, CLASS)           [OBJ isMemberOfClass:[CLASS class]]
#define isString(OBJ)                  isMember(OBJ, NSString)
#define isAttributedString(OBJ)        isMember(OBJ, NSAttributedString)
#define isArray(OBJ)                   isMember(OBJ, NSArray)
#define isDictionary(OBJ)              isMember(OBJ, NSDictionary)
#define isMSDictionary(OBJ)            isMember(OBJ, MSDictionary)
#define isSet(OBJ)                     isMember(OBJ, NSSet)
#define isOrderedSet(OBJ)              isMember(OBJ, NSOrderedSet)
#define isMutableString(OBJ)           isMember(OBJ, NSMutableString)
#define isMutableAttributedString(OBJ) isMember(OBJ, NSMutableAttributedString)
#define isMutableArray(OBJ)            isMember(OBJ, NSMutableArray)
#define isMutableDictionary(OBJ)       isMember(OBJ, NSMutableDictionary)
#define isMutableSet(OBJ)              isMember(OBJ, NSMutableSet)
#define isMutableOrderedSet(OBJ)       isMember(OBJ, NSMutableOrderedSet)

#define WRAP(BLOCK) do { BLOCK } while(0)
#define JOIN(x,y,z) x##y##z
#define NSStringify(a)@__STRING(a)
#define NSStringifyJoin(x,y,z) NSStringify(JOIN(x,y,z))

#define MSTOKEN_TO_STATIC_STRING_DEFINITION(t) MSSTATIC_STRING_CONST t = NSStringify(t)
#define MSTOKEN_TO_STRING_DEFINITION(t) MSSTRING_CONST t = NSStringify(t)

#define MSKEY_DEFINITION(k)          MSTOKEN_TO_STRING_DEFINITION(__CONCAT(k,Key))
#define MSNAMETAG_DEFINITION(n)      MSTOKEN_TO_STRING_DEFINITION(__CONCAT(n,Nametag))
#define MSNAME_DEFINITION(n)         MSTOKEN_TO_STRING_DEFINITION(__CONCAT(n,Name))
#define MSNOTIFICATION_DEFINITION(n) MSTOKEN_TO_STRING_DEFINITION(__CONCAT(n,Notification))
#define MSIDENTIFIER_DEFINITION(n)   MSTOKEN_TO_STRING_DEFINITION(__CONCAT(n,Identifier))

#define MSSTATIC_KEY(n)              MSTOKEN_TO_STATIC_STRING_DEFINITION(__CONCAT(n,Key))
#define MSSTATIC_NAMETAG(n)          MSTOKEN_TO_STATIC_STRING_DEFINITION(__CONCAT(n,Nametag))
#define MSSTATIC_NAME(n)             MSTOKEN_TO_STATIC_STRING_DEFINITION(__CONCAT(n,Name))
#define MSSTATIC_NOTIFICATION(n)     MSTOKEN_TO_STATIC_STRING_DEFINITION(__CONCAT(n,Notification))
#define MSSTATIC_IDENTIFIER(n)       MSTOKEN_TO_STATIC_STRING_DEFINITION(__CONCAT(n,Identifier))

#define MSEXTERN_KEY(k)          MSEXTERN_STRING __CONCAT(k,Key)
#define MSEXTERN_NAMETAG(n)      MSEXTERN_STRING __CONCAT(n,Nametag)
#define MSEXTERN_NAME(n)         MSEXTERN_STRING __CONCAT(n,Name)
#define MSEXTERN_NOTIFICATION(n) MSEXTERN_STRING __CONCAT(n,Notification)
#define MSEXTERN_IDENTIFIER(i)   MSEXTERN_STRING __CONCAT(i,Identifier)

#define MSSingleLineComment(COMMENT) [@" // " stringByAppendingString:COMMENT]
#define MSMultiLineComment(COMMENT) [NSString stringWithFormat:@" /* %@ */", COMMENT]

#define SuppressWarning(warning, block)                      \
    {                                                        \
        _Pragma("clang diagnostic push")                     \
        _Pragma(__STRING(clang diagnostic ignored warning)) \
        block                                                \
        _Pragma("clang diagnostic pop")                      \
    }

#define SuppressPerformSelectorLeakWarning(block) \
    SuppressWarning("-Warc-performSelector-leaks", block)


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Convenience
////////////////////////////////////////////////////////////////////////////////

// exceptions
#define InvalidNilArgument(ARG)                                               \
    [NSException exceptionWithName:NSInvalidArgumentException                 \
                            reason:$(@"%@ must not be nil", NSStringify(ARG)) \
                          userInfo:nil]

#define InvalidArgument(ARG, REASON)                                                  \
    [NSException exceptionWithName:NSInvalidArgumentException                         \
                            reason:$(@"%@ %@", NSStringify(ARG), NSStringify(REASON)) \
                          userInfo:nil]

#define InvalidIndexArgument(ARG)                                          \
    [NSException exceptionWithName:NSRangeException                        \
                            reason:$(@"%@ out of range", NSStringify(ARG)) \
                          userInfo:nil]

#define InvalidInternalInconsistency(REASON)                        \
    [NSException exceptionWithName:NSInternalInconsistencyException \
                            reason:$(@"%@", NSStringify(REASON))    \
                          userInfo:nil]

#define ThrowInvalidNilArgument(ARG)              @throw InvalidNilArgument(ARG)
#define ThrowInvalidIndexArgument(ARG)            @throw InvalidIndexArgument(ARG)
#define ThrowInvalidArgument(ARG,REASON)          @throw InvalidArgument(ARG,REASON)
#define ThrowInvalidInternalInconsistency(REASON) @throw InvalidInternalInconsistency(REASON)

#define KeyPathValue(OBJECT, KEYPATH) [OBJECT valueForKeyPath:KEYPATH]
#define SelfKeyPathValue(KEYPATH)     KeyPathValue(self, KEYPATH)

#define CollectionSafeKeyPathValue(OBJECT, KEYPATH) CollectionSafe(KeyPathValue(OBJECT, KEYPATH))
#define CollectionSafeSelfKeyPathValue(KEYPATH)     CollectionSafeKeyPathValue(self, KEYPATH)


#if TARGET_OS_IPHONE
#define UIApp           [UIApplication sharedApplication]
#define SharedApp       [UIApplication sharedApplication]
#define AppDelegate     [SharedApp delegate]
#define CurrentDevice   [UIDevice currentDevice]
#define MainScreen      [UIScreen mainScreen]
#define MainScreenScale [MainScreen scale]
#define MenuController  [UIMenuController sharedMenuController]

#define NSIndexPathMake(SECTION, ROW) [NSIndexPath indexPathForRow:ROW inSection:SECTION]

#define UIImageMake(NAMED) [UIImage imageNamed:NAMED]

#endif

#define MainQueue             [NSOperationQueue mainQueue]
#define CurrentQueue          [NSOperationQueue currentQueue]
#define OnMainQueue           ((CurrentQueue == MainQueue) ? YES : NO)
#define BlockOperation(block) [NSBlockOperation blockOperationWithBlock :^{ block }]
#define OnMainThread          [[NSThread currentThread] isMainThread]
#define MainBundle            [NSBundle mainBundle]
#define MainBundlePath        [MainBundle bundlePath]
#define NotificationCenter    [NSNotificationCenter defaultCenter]
#define FileManager           [NSFileManager defaultManager]
#define CurrentDate           [NSDate date]
#define SecondsSinceDate(d)   [CurrentDate timeIntervalSinceDate:d]

#define NSIndexSetMake(INDEX,...)  _NSIndexSetMake(INDEX, ##__VA_ARGS__, -1)
MSSTATIC_INLINE NSIndexSet * _NSIndexSetMake(NSUInteger location,...)
{
    NSUInteger length = 1;
    va_list args;
    va_start(args, location);
    NSInteger secondIndex = va_arg(args, int);
    if (secondIndex >= 0) length = (NSUInteger)secondIndex;
    va_end(args);

    NSRange range = NSMakeRange(location, length);
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
    return indexSet;
}

// character sets
#define NSAlphanumericCharacters         [NSCharacterSet alphanumericCharacterSet]
#define NSCapitalizedLetterCharacters    [NSCharacterSet capitalizedLetterCharacterSet]
#define NSControlCharacters              [NSCharacterSet controlCharacterSet]
#define NSDecimalDigitCharacters         [NSCharacterSet decimalDigitCharacterSet]
#define NSDecomposableCharacters         [NSCharacterSet decomposableCharacterSet]
#define NSIllegalCharacters              [NSCharacterSet illegalCharacterSet]
#define NSLetterCharacters               [NSCharacterSet letterCharacterSet]
#define NSLowercaseLetterCharacters      [NSCharacterSet lowercaseLetterCharacterSet]
#define NSNewlineCharacters              [NSCharacterSet newlineCharacterSet]
#define NSNonBaseCharacters              [NSCharacterSet nonBaseCharacterSet]
#define NSPunctuationCharacters          [NSCharacterSet punctuationCharacterSet]
#define NSSymbolCharacters               [NSCharacterSet symbolCharacterSet]
#define NSUppercaseLetterCharacterss     [NSCharacterSet uppercaseLetterCharacterSet]
#define NSWhitespaceAndNewlineCharacters [NSCharacterSet whitespaceAndNewlineCharacterSet]
#define NSWhitespaceCharacters           [NSCharacterSet whitespaceCharacterSet]

#define NSCharacterSetMake(STRING) \
[NSCharacterSet characterSetWithCharactersInString:NSStringify(STRING)]
#define NSMutableCharacterSetMake(STRING) \
[NSMutableCharacterSet characterSetWithCharactersInString:NSStringify(STRING)]

#define NSPredicateMake(FORMAT,...)  [NSPredicate predicateWithFormat:FORMAT,__VA_ARGS__]
#define NSPredicateBlock(BLOCK)      [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings){return BLOCK;}]


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Device, Orientation
////////////////////////////////////////////////////////////////////////////////


#if TARGET_OS_IPHONE
#define UIInterface    UI_USER_INTERFACE_IDIOM()
#define DeviceIsPhone  (UIInterface == UIUserInterfaceIdiomPhone)
#define DeviceIsPad    (UIInterface == UIUserInterfaceIdiomPad)

#define DeviceOrientation  CurrentDevice.orientation
#define DeviceIsLandscape  UIDeviceOrientationIsLandscape(DeviceOrientation)
#define DeviceIsPortrait   UIDeviceOrientationIsPortrait(DeviceOrientation)

#define InterfaceOrientation  SharedApp.statusBarOrientation
#define InterfaceIsLandscape  UIInterfaceOrientationIsLandscape(InterfaceOrientation)
#define InterfaceIsPortrait   UIInterfaceOrientationIsPortrait(InterfaceOrientation)

#define CurrentDeviceOrientation                DeviceOrientation
#define CurrentDeviceOrientationIsLandscape     DeviceIsLandscape
#define CurrentDeviceOrientationIsPortrait      DeviceIsLandscape
#define CurrentInterfaceOrientation             InterfaceOrientation
#define CurrentInterfaceOrientationIsLandscape  InterfaceIsLandscape
#define CurrentInterfaceOrientationIsPortrait   InterfaceIsPortrait
#endif

#define IsMainQueue ([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue])


////////////////////////////////////////////////////////////////////////////////
#pragma mark - File Paths
////////////////////////////////////////////////////////////////////////////////


#define LibraryFilePath                                                        \
	[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define DocumentsFilePath                                                        \
	[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Ranges
////////////////////////////////////////////////////////////////////////////////


#define NSNotFoundRange            ((NSRange){NSNotFound,0})
#define NSZeroRange                ((NSRange){.location = 0, .length = 0})
#define CFZeroRange                ((CFRange) {.location = 0, .length = 0})
#define NSRangeFromCFRange(range)  NSMakeRange(range.location, range.length)


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Logging
////////////////////////////////////////////////////////////////////////////////


#define ClassTagSelectorString \
	[NSString stringWithFormat:@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd)]
#define ClassTagString  [NSString stringWithFormat:@"<%@>", NSStringFromClass([self class])]
#define ClassTagSelectorStringForInstance(instance)               \
	[NSString stringWithFormat:@"[%@ %@]\u00AB%@\u00BB",          \
                                 NSStringFromClass([self class]), \
                                 NSStringFromSelector(_cmd),      \
                                 instance]
#define ClassTagStringForInstance(instance) \
	[NSString stringWithFormat:@"<%@:%@>", NSStringFromClass([self class]), instance]

#define TimerStart  NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate]
#define TimerEnd(msg)                                              \
	NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate]; \
	nsprintf([NSString stringWithFormat:@"%@ Time = %f", msg, stop - start])

#define MSDefaultTabWidth   4
#define MSDefaultTabString  @"    "
#define MSNewLineRegEx @"(?:\r\n|[\n\v\f\r\\x85\\p{Zl}\\p{Zp}])"


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Views
////////////////////////////////////////////////////////////////////////////////


#if TARGET_OS_IPHONE
#define AutoresizeAllFlexible                \
	UIViewAutoresizingFlexibleWidth |        \
	UIViewAutoresizingFlexibleHeight |       \
	UIViewAutoresizingFlexibleTopMargin |    \
	UIViewAutoresizingFlexibleBottomMargin | \
	UIViewAutoresizingFlexibleLeftMargin |   \
	UIViewAutoresizingFlexibleRightMargin
#define AutoresizeHeightAndWidthFlexible     \
	UIViewAutoresizingFlexibleWidth |        \
	UIViewAutoresizingFlexibleHeight
#define AutoresizeFlexibleMargins            \
	UIViewAutoresizingFlexibleTopMargin |    \
	UIViewAutoresizingFlexibleBottomMargin | \
	UIViewAutoresizingFlexibleLeftMargin |   \
	UIViewAutoresizingFlexibleRightMargin
#define AutoresizeNone UIViewAutoresizingNone

#define MenuItem(title, selector) [[UIMenuItem alloc] initWithTitle:title action:selector]

#define TitleBarButton(title, selector)                              \
    [[UIBarButtonItem alloc] initWithTitle:title                     \
                                     style:UIBarButtonItemStylePlain \
                                    target:self                      \
                                    action:selector]
#define ImageBarButton(image, selector)                               \
    [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:image] \
                                     style:UIBarButtonItemStylePlain  \
                                    target:self                       \
                                    action:selector]
#define SystemBarButton(item, selector)                             \
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItem##item \
                                                  target:self                        \
                                                  action:selector]
#define CustomBarButton(view)   [[UIBarButtonItem alloc] initWithCustomView:view]
#define FlexibleSpaceBarButton  SystemBarButton(FlexibleSpace, nil)
#define FixedSpaceBarButton(WIDTH)    ({ UIBarButtonItem * fixed = SystemBarButton(FixedSpace, nil); fixed.width = WIDTH; fixed; })
#endif

