//
//  MessageListController.m
//  iPhoneXMPP
//
//  Created by 俞 億 on 12-5-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MessageListController.h"
#import "MessageEntity.h"
#import "PersonEntity.h"

#define kNumViewTag 100
#define kNumLabelTag 101

@interface MessageListController ()

@end

@implementation MessageListController

-(void)loadView{
    UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 320, 416)];
    self.view = container;
    
    DataTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, 320, 416)];
    DataTable.delegate = self;
    DataTable.dataSource = self;
    [self.view addSubview:DataTable];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //显示和每个聊天的人的头像
    //查询所有的联系人，取出其中有发送消息的
    //对Entity里面的数组属性操作时需要@
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sendedMessages.@count>0 and name!=%@",selfUserName];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PersonEntity"];
    [fetchRequest setPredicate:predicate];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
    fetchResultController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetchRequest
                                                               managedObjectContext:[iPhoneXMPPAppDelegate sharedAppDelegate].managedObjectContext
                                                                 sectionNameKeyPath:nil cacheName:nil];
    //设置了delegate才能动态监测数据库变化
    fetchResultController.delegate = self;
    [fetchResultController performFetch:NULL];
    personArray = [[NSMutableArray alloc]initWithArray:[fetchResultController fetchedObjects]];
    for (PersonEntity *personEntity in personArray) {
        NSLog(@"name:%@,msg count:%d",personEntity.name,personEntity.sendedMessages.count);
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    if ([anObject isKindOfClass:[PersonEntity class]]) {
        PersonEntity *personEntity = (PersonEntity*)anObject;
        if (type==NSFetchedResultsChangeInsert) {
            [personArray addObject:personEntity];
            [DataTable insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationLeft];
        }else if (type==NSFetchedResultsChangeUpdate) {
            [DataTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return personArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *personCell = [DataTable dequeueReusableCellWithIdentifier:@"personCell"];
    if (personCell==nil) {
        personCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:@"personCell"];
        //联系人头像
        personCell.imageView.image = [UIImage imageNamed:@"defaultPerson.png"];
        //用一个红圈显示消息数量,不要显示太多的数字，一般不超过99
        UIImage *numImage = [[UIImage imageNamed:@"com_number_single"]stretchableImageWithLeftCapWidth:12 topCapHeight:12];
        UIImageView *numView = [[UIImageView alloc]initWithImage:numImage];
        numView.tag = kNumViewTag;
        [personCell.contentView addSubview:numView];
        UILabel *numLabel = [[UILabel alloc]initWithFrame:CGRectMake(5, 3, 20, 20)];
        numLabel.backgroundColor = [UIColor clearColor];
        numLabel.font = [UIFont systemFontOfSize:14];
        numLabel.textColor = [UIColor whiteColor];
        numLabel.tag = kNumLabelTag;
        [numView addSubview:numLabel];
    }
    PersonEntity *personEntity = [personArray objectAtIndex:indexPath.row];
    personCell.textLabel.text = personEntity.name;
    //在subTitle显示联系人发送的最后一条消息
    //取出这个联系人发送的所有消息，按照发送日期排序,取最新一条
    NSArray *sendedMessageArray = [personEntity.sendedMessages allObjects];
    //判断sendedMessageArray是否为空
    if (sendedMessageArray.count>0) {
        //按照升序排列，时间最晚的消息在最后
        NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
        sendedMessageArray = [sendedMessageArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDesc]];
        MessageEntity *lastMessageEntity = [sendedMessageArray lastObject];
        personCell.detailTextLabel.text = lastMessageEntity.content;
        
        //计算数字显示需要的frame
        NSString *numStr = [NSString stringWithFormat:@"%d",sendedMessageArray.count];
        CGSize numSize = [numStr sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(CGFLOAT_MAX, 20)];
        //因为红圈比文字大一圈
        //红圈显示在联系人头像的右上角
        UIImageView *numView = (UIImageView*)[personCell.contentView viewWithTag:kNumViewTag];
        numView.frame = CGRectMake(40-numSize.width, 0, numSize.width+20, numSize.height+10);
        UILabel *numLabel = (UILabel*)[numView viewWithTag:kNumLabelTag];
        numLabel.frame = CGRectMake(10, 3, numSize.width, numSize.height);
        numLabel.text = numStr;
    }

    return personCell;
}

@end
