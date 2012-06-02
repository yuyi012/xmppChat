//
//  ChatController.h
//  iPhoneXMPP
//
//  Created by 刘 大兵 on 12-5-28.
//  Copyright (c) 2012年 中华中等专业学校. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PersonEntity.h"
#import <CoreData/CoreData.h>
#import "PersonEntity.h"

@interface ChatController : UIViewController<UITextViewDelegate,NSFetchedResultsControllerDelegate,UITableViewDelegate,UITableViewDataSource>{
    CGRect keyboardEndFrame;
    IBOutlet UIImageView *inputContainer;
    IBOutlet UITableView *DataTable;
    IBOutlet UITextView *inputView;
    CGFloat previousContentHeight;
    PersonEntity *selfEntity;
    
    NSMutableArray *messageArray;
    NSFetchedResultsController *fetchController;
}
-(void)sendButtonClick:(id)sender;
@property(nonatomic,retain) PersonEntity *friendEntity;
@end
