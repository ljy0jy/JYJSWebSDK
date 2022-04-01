//
//  IMProSizeManager.h
//  IMPro
//
//  Created by BF.Space on 2021/8/5.
//  Copyright © 2021 BF.Space. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface IMProSizeManager : NSObject
+(BOOL)isiPhoneX;
+(UIEdgeInsets)safeArea;
+(CGFloat)IMProStatusHei;
+(CGFloat)IMProNavgationHei;
+(CGFloat)IMProTabbarHei;
+(CGFloat)IMProTabbarTopY;

@end

NS_ASSUME_NONNULL_END
