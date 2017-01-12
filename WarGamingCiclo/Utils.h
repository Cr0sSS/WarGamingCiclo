//
//  Utils.h
//  WarGamingCiclo
//
//  Created by Admin on 10.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TEST_BUILD 1

void TestLog(NSString* string, ...) {
    
#if TEST_BUILD

    va_list argumentList;
    va_start(argumentList, string);
    
    NSLogv(string, argumentList);
    
    va_end(argumentList);
    
#endif
}
