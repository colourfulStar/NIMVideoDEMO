//
//  Common.h
//  NIMVideoDEMO
//
//  Created by 张茜倩 on 16/5/3.
//  Copyright © 2016年 Xiqian Zhang. All rights reserved.
//

#ifndef Common_h
#define Common_h

/*
 说明：1）请自己在网易云信的后台管理中申请应用的key
      2）让服务器同事在key对应的应用上注册两个帐号、密码
      3）默认是kAccount1发送视频请求到kAccount2
 */

//网易云信的key
#define kYXAppKey @""


//两个测试帐号
#define kAccount1 @""
#define kToken1   @""

#define kAccount2 @""
#define kToken2   @""


//尺寸
#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height



#define dispatch_async_main_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}


#endif /* Common_h */
