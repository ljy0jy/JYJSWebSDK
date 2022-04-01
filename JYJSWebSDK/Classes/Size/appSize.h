//
//  appSize.h
//  IMPro
//
//  Created by BF.Space on 2021/8/4.
//  Copyright © 2021 BF.Space. All rights reserved.
//

#ifndef appSize_h
#define appSize_h

#define QRCodeWidth  260.0   //正方形二维码的边长
#define QQZScreenBounds   [UIScreen mainScreen].bounds
#define QQZScreenWidth    [UIScreen mainScreen].bounds.size.width
#define QQZScreenHeight   [UIScreen mainScreen].bounds.size.height
#define QQZScaleWidth(w)         ((w) * QQZScreenWidth / 375)
#define QQZScaleHeight(h)         ((h) * QQZScreenHeight / 812)

#define WIDTH_SCALE [UIScreen mainScreen].bounds.size.width/375.f
#define PX_HEIGHT [UIScreen mainScreen].bounds.size.height/812.f

#endif /* appSize_h */
