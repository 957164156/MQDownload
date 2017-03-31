//
//  DownloadTableViewController.m
//  MQDownload
//
//  Created by 孙明卿 on 2017/3/31.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import "DownloadTableViewController.h"
#import "DownloadViewCell.h"
#import "SMQRequest.h"
@interface DownloadTableViewController ()<SMQRequestDelegate>

@property (strong,nonatomic)NSMutableArray *dataArray;
@end

@implementation DownloadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //http://www.dingdongedu.com/files/default/2017/02-28/wu_1ba1tn0h719kas9pueist7ig90.flv
    //http://www.dingdongedu.com/files/default/2017/02-28/wu_1ba1tn0h719kas9pueist7ig90.flv
    //http://sw.bos.baidu.com/sw-search-sp/software/797b4439e2551/QQ_mac_5.0.2.dmg
    //@"http://192.168.0.177:8888/files/tmp/2017/03-01/wu_1ba4gntifc0ibs61qfie0n4fsb.mp4?6.1.0",
    self.dataArray = @[@"http://www.dingdongedu.com/files/default/2017/02-28/wu_1ba1tn0h719kas9pueist7ig90.flv",
                       @"http://sw.bos.baidu.com/sw-search-sp/software/797b4439e2551/QQ_mac_5.0.2.dmg",
                       @"http://192.168.0.177:8888/files/tmp/2017/03-01/wu_1ba4gntifc0ibs61qfie0n4fsb.mp4?6.1.0",
                       @"http://192.168.0.177:8888/files/default/2017/03-03/wu_1ba9fh9up1upo1uoscjgm4j1c2h0.flv?6.1.0",
                       @"http://192.168.0.177:8888/files/default/2017/03-22/wu_1bbpnb16n1s581kc61nq52q71pei0.mp4?6.1.0"].mutableCopy;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    
    cell.nameLabel.text = self.dataArray[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //
    DownloadViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *title = cell.startBtn.currentTitle;
    SMQRequest *request = [SMQRequest initWithURL:self.dataArray[indexPath.row]];
    if ([title isEqualToString:@"开始"]) {
        request.delegate = self;
        request.indexPath = indexPath;
        [request startDownloadTask];
        [cell.startBtn setTitle:@"等待" forState:UIControlStateNormal];
    }else if ([title isEqualToString:@"暂停"]) {
        //
        [request resumeDownloadTask];
        [cell.startBtn setTitle:@"等待" forState:UIControlStateNormal];
    }else if ([title isEqualToString:@"等待"]) {
        [request PlayDownloadTask];
    }else if ([title isEqualToString:@"正在下载"]) {
        [request pauseDownloadTask];
        [cell.startBtn setTitle:@"暂停" forState:UIControlStateNormal];

    }else {
        
    }
}

- (void)requestDownloadPause:(SMQRequest *)request {
    DownloadViewCell *cell = [self.tableView cellForRowAtIndexPath:request.indexPath];
    [cell.startBtn setTitle:@"暂停" forState:UIControlStateNormal];

}

- (void)requestDownloading:(SMQRequest *)request {
    //
    DownloadViewCell *cell = [self.tableView cellForRowAtIndexPath:request.indexPath];
    cell.percentLabel.text = [NSString stringWithFormat:@"%.2f%%",request.didWriteData * 1.0 / request.totoalData * 100];
    [cell.startBtn setTitle:@"正在下载" forState:UIControlStateNormal];
    //
}

-(void)requestDownloadFinish:(SMQRequest *)request {
    DownloadViewCell *cell = [self.tableView cellForRowAtIndexPath:request.indexPath];
    [cell.startBtn setTitle:@"下载完成" forState:UIControlStateNormal];

}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
