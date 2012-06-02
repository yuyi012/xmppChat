//
//  MessageListController.h
//  iPhoneXMPP
//
//  Created by 俞 億 on 12-5-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MessageListController : UIViewController<UITableViewDelegate,UITableViewDataSource,NSFetchedResultsControllerDelegate>{
    UITableView *DataTable;
    NSMutableArray *personArray;
    NSFetchedResultsController *fetchResultController;
}
@end
