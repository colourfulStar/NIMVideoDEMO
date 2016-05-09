//
//  ViewController.m
//  NIMVideoDEMO
//
//  Created by 张茜倩 on 16/5/3.
//  Copyright © 2016年 Xiqian Zhang. All rights reserved.
//

#import "ViewController.h"
#import "VideoController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *account;
@property (weak, nonatomic) IBOutlet UITextField *token;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    
    
}

- (IBAction)startAction:(id)sender {
    
    NSString *account = self.account.text;
    NSString *token = self.token.text;
    [[[NIMSDK sharedSDK] loginManager]login:account
                                      token:token
                                 completion:^(NSError *error){
                                     if (error == nil)
                                     {
                                         VideoController *viedeoCtrl = [[VideoController alloc]init];
                                         [self presentViewController:viedeoCtrl animated:YES completion:nil];
                                         
                                     }else
                                     {
                                         NSLog(@"%@",error);
                                         NSLog(@"网易云信登录失败");
                                     }
                                 }];
    
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
