//
//  DownloadViewCell.h
//  MQDownload
//
//  Created by 孙明卿 on 2017/3/31.
//  Copyright © 2017年 爱书人. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UILabel *percentLabel;
@end
