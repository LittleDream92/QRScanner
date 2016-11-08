//
//  ViewController.m
//  CodeScanderDemo
//
//  Created by Meng Fan on 16/11/7.
//  Copyright © 2016年 Meng Fan. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeViewController.h"
#import "QRScanerHelper.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *titleArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _titleArray = @[@"扫描二维码", @"识别图中的二维码", @"生成二维码", @"生成带头像的二维码"];
    
    [self.view addSubview:self.tableView];
}


#pragma mark - lazyloading
-(UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.titleArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const kCellID = @"kcellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
    }
    
    cell.textLabel.text = self.titleArray[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
        {   //扫描二维码，真机测试
            QRCodeViewController *QRCodeVC = [[QRCodeViewController alloc] init];
            [QRCodeVC startScanner];
            [self.navigationController showViewController:QRCodeVC sender:nil];
            break;
        }
        case 1:
        {   //识别图中的二维码
            //做的一张假的二维码图
            UIImage *qrImage = [QRScanerHelper createQRCodeWithString:@"这是二维码" withSideLength:200.f];
            
            QRCodeViewController *QRCodeVC = [[QRCodeViewController alloc] init];
            [QRCodeVC createCodeWithQRString:@"这是二维码" andLogoImage:nil];
            [QRCodeVC recognizedQRImage:qrImage];
            [self.navigationController showViewController:QRCodeVC sender:nil];
            break;
        }
        case 2:
        {   //生成二维码
            QRCodeViewController *QRCodeVC = [[QRCodeViewController alloc] init];
            [QRCodeVC createCodeWithQRString:@"NO-Logo的二维码" andLogoImage:nil];
            [self.navigationController showViewController:QRCodeVC sender:nil];
            break;
        }
        case 3:
        {   //生成带头像的二维码
            QRCodeViewController *QRCodeVC = [[QRCodeViewController alloc] init];
            [QRCodeVC createCodeWithQRString:@"Have-Logo的二维码" andLogoImage:[UIImage imageNamed:@"happy"]];
            [self.navigationController showViewController:QRCodeVC sender:nil];
            break;
        }
        default:
            break;
    }
}

#pragma mark -
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
