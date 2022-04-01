//
//  IMProSizeManager.m
//  IMPro
//
//  Created by BF.Space on 2021/8/5.
//  Copyright © 2021 BF.Space. All rights reserved.
//

#import "IMProSizeManager.h"

@implementation IMProSizeManager
+(BOOL)isiPhoneX{
    if ([IMProSizeManager safeArea].bottom > 0) {
        return YES;
    } else {
        return NO;
    }
}

+(UIEdgeInsets)safeArea{
    if (@available(iOS 11.0, *)) {
        //xcode 11  appdelegate 新增window，[UIApplication sharedApplication].delegate.window在iOS13 获取不到
        UIWindow *window = [[UIApplication sharedApplication].windows firstObject];
        return window.safeAreaInsets;
    } else {
        return UIEdgeInsetsMake(20, 0, 0, 0);
    }
}

+(CGFloat)IMProStatusHei{
    return IMProSizeManager.isiPhoneX ? 44.f : 20.f;
}
+(CGFloat)IMProNavgationHei{
    return IMProSizeManager.isiPhoneX ? 84.f : 64.f;
}
+(CGFloat)IMProTabbarHei{
    return IMProSizeManager.isiPhoneX ? 83.f : 49.f;
}

+(CGFloat)IMProTabbarTopY{
    return IMProSizeManager.isiPhoneX ? 71.f : 40.f;
}
@end
