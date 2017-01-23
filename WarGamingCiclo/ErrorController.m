//
//  ErrorController.m
//  RPN Calculator
//
//  Created by Admin on 23.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import "ErrorController.h"

@implementation ErrorController

+ (ErrorController*)errorControllerWithTitle:(NSString*)title
                                     message:(NSString*)message {
    
    ErrorController* ec = [ErrorController alertControllerWithTitle:title
                                                            message:message
                                                     preferredStyle:UIAlertControllerStyleAlert];
    
    [ec addAction:[UIAlertAction actionWithTitle:@"Закрыть" style:UIAlertActionStyleCancel handler:nil]];
    
    return ec;
}

@end
