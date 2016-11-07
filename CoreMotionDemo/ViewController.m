//
//  ViewController.m
//  CoreMotionDemo
//
//  Created by 888 on 16/11/4.
//  Copyright © 2016年 lk. All rights reserved.
//

#import "ViewController.h"

#import <math.h>
#import <CoreLocation/CoreLocation.h>
#import "FINCamera/FINCamera.h"


@interface ViewController () <CLLocationManagerDelegate,FINCameraDelagate,AVCaptureVideoDataOutputSampleBufferDelegate>

/** 照相机 */
@property(nonatomic,strong)FINCamera * camera;
/** 位置管理者 */
@property(strong,nonatomic)CLLocationManager* CLManager;
/** 箭头图片 */
@property (nonatomic,strong)UIImageView *arrowImage;
/** 定位位置 */
@property (nonatomic,assign)CLLocationCoordinate2D  coordinate2D;

@end

@implementation ViewController

/*位置管理者懒加载*/
-(CLLocationManager *)CLManager
{
    if (_CLManager==nil) {
        _CLManager=[[CLLocationManager alloc]init];
        _CLManager.delegate=self;
        _CLManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    }
    return _CLManager;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //创建图片
    self.arrowImage = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 150, 200)];
    self.arrowImage.image = [UIImage imageNamed:@"arrow.jpg"];
    [self.view insertSubview:self.arrowImage atIndex:1];
    
    [self openCamera];
    [self.CLManager startUpdatingHeading];
    
    /** 由于IOS8中定位的授权机制改变 需要进行手动授权
     * 获取授权认证，两个方法：
     * [self.locationManager requestWhenInUseAuthorization];
     * [self.locationManager requestAlwaysAuthorization];
     */
    if ([self.CLManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        NSLog(@"requestAlwaysAuthorization");
        [self.CLManager requestAlwaysAuthorization];
    }
    
    //开始定位，不断调用其代理方法
    [self.CLManager startUpdatingLocation];
    NSLog(@"start gps");
}

#pragma mark - 定位
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //获取用户位置的对象
    CLLocation *location = [locations lastObject];
    CLLocationCoordinate2D coordinate = location.coordinate;
    self.coordinate2D = coordinate;
//    NSLog(@"纬度:%f 经度:%f", coordinate.latitude, coordinate.longitude);
}

#pragma mark - 定位方向
- (void)locationManager:(CLLocationManager *)manager  didUpdateHeading:(CLHeading *)newHeading
{
    
    //如果当前设备的朝向信息不可用，直接返回
    if (newHeading.headingAccuracy<0) return;
    
    //获取设备的朝向角度
    CLLocationDirection direction = newHeading.magneticHeading;
    
    
    double xxx = [self getAngleLat1:39.914714 withLng1:116.404269 withLat2:39.913053 withLng2:116.20736];
    
    //获得的角度  这里应该写一个方法 用方向去算角度
    //CGFloat angle = direction/180*M_PI;//
    NSString *fangxiang = [self getDirection:xxx];
    //算角度
    CGFloat angle = [self getAngle:direction with:fangxiang];
    //NSLog(@"%f",angle);
    //设置旋转动画
    if (direction) {
     
        [UIView animateWithDuration:0.5 animations:^{
            
            self.arrowImage.transform = CGAffineTransformMakeRotation(-angle);
            //self.arrowImage.transform = CGAffineTransformMakeRotation(-xxx);
            
        }];
        
    }
    
}


#pragma mark - 相机
- (void)openCamera {
    __weak typeof(self) weakSelf = self;
    self.camera =[FINCamera createWithBuilder:^(FINCamera *builder) {
        // input
        [builder useBackCamera];
        // output
        [builder useVideoDataOutputWithDelegate:weakSelf];
        // delegate
        [builder setDelegate:weakSelf];
        // setting
        [builder setPreset:AVCaptureSessionPresetPhoto];
    }];
    [self.camera startSession];
    
    [self.view insertSubview:[self.camera previewWithFrame:self.view.bounds] atIndex:0];
    
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //    NSLog(@"TEST");
}
-(void)camera:(FINCamera *)camera adjustingFocus:(BOOL)adjustingFocus{
    //    NSLog(@"%@",adjustingFocus?@"正在对焦":@"对焦完毕");
}

#pragma mark - 得到角度值
- (double)getAngleLat1:(double)lat1 withLng1:(double)lng1 withLat2:(double)lat2 withLng2:(double)lng2
{
    double x1 = lng1;
    double y1 = lat1;
    double x2 = lng2;
    double y2 = lat2;
    double pi = M_PI;
    double w1 = y1 / 180 * pi;
    double j1 = x1 / 180 * pi;
    double w2 = y2 / 180 * pi;
    double j2 = x2 / 180 * pi;
    double ret;
    if (j1 == j2) {
        if (w1 > w2)
            return 270; // 北半球的情况，南半球忽略
        else if (w1 < w2)
            return 90;
        else
            return -1;// 位置完全相同
    }
    ret = 4* pow(sin((w1 - w2) / 2), 2)- pow(
                                                            sin((j1 - j2) / 2) * (cos(w1) - cos(w2)),2);
    ret = sqrt(ret);
    double temp = (sin(fabs(j1 - j2) / 2) * (cos(w1) + cos(w2)));
    ret = ret / temp;
    ret = atan(ret) / pi * 180;
    if (j1 > j2){ // 1为参考点坐标
        if (w1 > w2)
            ret += 180;
        else
            ret = 180 - ret;
    } else if (w1 > w2)
        ret = 360 - ret;
    return ret;
}
#pragma mark - 得到方向
- (NSString *)getDirection:(double)jiaodu
{
    if ((jiaodu <= 10) || (jiaodu > 350))
        return @"东";
    if ((jiaodu > 10) && (jiaodu <= 80))
        return @"东北";
    if ((jiaodu > 80) && (jiaodu <= 100))
        return @"北";
    if ((jiaodu > 100) && (jiaodu <= 170))
        return @"西北";
    if ((jiaodu > 170) && (jiaodu <= 190))
        return @"西";
    if ((jiaodu > 190) && (jiaodu <= 260))
        return @"西南";
    if ((jiaodu > 260) && (jiaodu <= 280))
        return @"南";
    if ((jiaodu > 280) && (jiaodu <= 350))
        return @"东南";
    return @"";
}

#pragma mark - 算角度
- (CGFloat)getAngle:(CLLocationDirection)direction with:(NSString *)fangxiang
{
    if ([fangxiang isEqualToString:@"东"])
        return direction/90*M_PI;//@"东"
    if ([fangxiang isEqualToString:@"东北"])
        return direction/45*M_PI;//@"东北"
    if ([fangxiang isEqualToString:@"北"])
        return direction/0*M_PI;//@"北"
    if ([fangxiang isEqualToString:@"西北"])
        return direction/315*M_PI;//@"西北"
    if ([fangxiang isEqualToString:@"西"])
        return direction/270*M_PI;//@"西"
    if ([fangxiang isEqualToString:@"西南"])
        return direction/225*M_PI;//@"西南"
    if ([fangxiang isEqualToString:@"南"])
        return direction/180*M_PI;//@"南"
    if ([fangxiang isEqualToString:@"东南"])
        return direction/135*M_PI;//@"东南"
    return direction/180*M_PI;
}

#pragma mark - 随机字符串
- (NSString *)ret32bitString

{
    char data[32];
    
    for (int x=0;x<32;data[x++] = (char)('A' + (arc4random_uniform(26))));
    
    return [[NSString alloc] initWithBytes:data length:32 encoding:NSUTF8StringEncoding];
}

@end
