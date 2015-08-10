//
//  MSKitDefines.h
//  MSKit
//
//  Created by Jason Cardwell on 4/13/11.
//  Copyright 2011 Moondeer Studios. All rights reserved.
//
@import ObjectiveC;

#ifdef __cplusplus
#define MSEXTERN extern "C" __attribute__((visibility("default")))
#else
#define MSEXTERN extern __attribute__((visibility("default")))
#endif

#define MSSTATIC_INLINE       static inline
#define MSSTRING_CONST        NSString * const
#define MSSTATIC_STRING_CONST static MSSTRING_CONST
#define MSEXTERN_STRING       extern MSSTRING_CONST

#define MSDEBUG
