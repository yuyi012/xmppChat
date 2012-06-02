//
//  ChatController.m
//  iPhoneXMPP
//
//  Created by 刘 大兵 on 12-5-28.
//  Copyright (c) 2012年 中华中等专业学校. All rights reserved.
//

#import "ChatController.h"
#import "MessageEntity.h"

//气泡的背景图片
#define kBallonImageViewTag 100
//显示消息内容的label
#define kChatContentLabelTag 101
//显示日期的label
#define kDateLabelTag 102
//显示消息正在发送的view的tag
#define kLoadingViewTag 103

@implementation ChatController
#pragma mark - View lifecycle
@synthesize friendEntity;
- (void)viewDidLoad
{
    [super viewDidLoad];
    DataTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    // Do any additional setup after loading the view from its nib.
    //更改输入框的字体和偏移
    inputContainer.userInteractionEnabled = YES;
    UIImage *chatBgImage = [UIImage imageNamed:@"ChatBar.png"];
    chatBgImage = [chatBgImage stretchableImageWithLeftCapWidth:18 topCapHeight:20];
    inputContainer.image = chatBgImage;
    inputView = [[UITextView alloc]initWithFrame:CGRectMake(40, 10, 220, 30)];
    inputView.delegate = self;
    inputView.backgroundColor = [UIColor clearColor];
    inputView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    inputView.contentInset = UIEdgeInsetsMake(0, 5, 0, 0);
    inputView.showsHorizontalScrollIndicator = NO;
//    inputView.returnKeyType = UIReturnKeyNext;
    [inputContainer addSubview:inputView];
    inputView.font = [UIFont systemFontOfSize:16];
    //inputView.contentStretch = uiviewcont
    //发送按钮的标题国际化
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendButton.frame = CGRectMake(270, 5, 40, 40);
    [sendButton addTarget:self
                   action:@selector(sendButtonClick:) 
         forControlEvents:UIControlEventTouchUpInside];
    [sendButton setTitle:NSLocalizedString(@"Send", @"") forState:UIControlStateNormal];
    [inputContainer addSubview:sendButton];
    
    UIButton *dissmissButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    dissmissButton.frame = CGRectMake(5, 5, 30, 35);
    [dissmissButton addTarget:self
                   action:@selector(dismissButtonClick) 
         forControlEvents:UIControlEventTouchUpInside];
    [dissmissButton setTitle:NSLocalizedString(@"D", @"") forState:UIControlStateNormal];
    [inputContainer addSubview:dissmissButton];
    
    //监测键盘位置的变化，让输入框显示在键盘上面
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillShow:)
                                                name:UIKeyboardWillShowNotification
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(keyboardWillHide:)
                                                name:UIKeyboardWillHideNotification
                                              object:nil];
    
    iPhoneXMPPAppDelegate *appDelegate = (iPhoneXMPPAppDelegate*)[[UIApplication sharedApplication]delegate];
    //当前登陆用户的jid
    NSString *selfUserName = [[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID];
    //取出当前用户的entity
    selfEntity = [appDelegate fetchPerson:selfUserName];
    NSLog(@"selfUserName:%@",selfUserName);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sender.name=%@ or receiver.name=%@",selfUserName,selfUserName];
    NSFetchRequest *fetechRequest = [NSFetchRequest fetchRequestWithEntityName:@"MessageEntity"];
    [fetechRequest setPredicate:predicate];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"sendDate" ascending:YES];
    [fetechRequest setSortDescriptors:[NSArray arrayWithObject:sortDesc]];
    //取到历史消息,还可以监测消息的新增
    //viewController之间互相传递数据的方法之一
    fetchController = [[NSFetchedResultsController alloc]initWithFetchRequest:fetechRequest
                                                         managedObjectContext:appDelegate.managedObjectContext
                                                           sectionNameKeyPath:nil cacheName:nil];
    fetchController.delegate = self;
    [fetchController performFetch:NULL];
    //把消息都保存在messageArray中
    NSArray *contentArray = [fetchController fetchedObjects];
    messageArray = [[NSMutableArray alloc]init];
    //在messageArray加入日期，两条消息间隔超过15分钟才加入日期
    for (NSInteger i=0; i<contentArray.count; i++) {
        //数组循环过程中，可以更改内容，但是插入和删除元素
        //第一条消息加一个日期
        MessageEntity *messageEntity = [contentArray objectAtIndex:i];
        NSDate *messageDate = messageEntity.sendDate;
        if (i==0) {
            [messageArray addObject:messageDate];
        }else {
            //和前一条的日期比较，判断是否超过15分钟
            MessageEntity *previousEntity = [contentArray objectAtIndex:i-1];
            //计算两个日期之间的秒数
            NSTimeInterval timeIntervalBetween = [messageDate timeIntervalSinceDate:previousEntity.sendDate];
            //判断两个日期间隔是否超过15分钟
            if (timeIntervalBetween>15*60) {
                [messageArray addObject:messageDate];
            }
        }
        [messageArray addObject:messageEntity];
    }
    [DataTable reloadData];
    //设置contentOffset才能完整显示最后一条消息,scrollToRect,scrollToIndexPath都不行
    [DataTable setContentOffset:CGPointMake(0, DataTable.contentSize.height)];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self
            name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self
            name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark keybord
// Prepare to resize for keyboard.
- (void)keyboardWillShow:(NSNotification *)notification 
{
    //NSLog(@"keyboardWillShow");
 	NSDictionary *userInfo = [notification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    //NSLog(@"keyboardEndFrame:%@",NSStringFromCGRect(keyboardEndFrame));
    //重新设置inputContainer高度，让输入框出现在键盘上面
    CGRect inputFrame = inputContainer.frame;
    //64＝20＋44。20是statusbar的高度，44是navigationbar的高度
    //取到的keyboardEndFrame的orgin是相对于window的
    inputFrame.origin.y = keyboardEndFrame.origin.y - inputFrame.size.height-64;
    [UIView animateWithDuration:0.2
                     animations:^{
                         inputContainer.frame = inputFrame;
                         
                         CGRect tableFrame = DataTable.frame;
                         tableFrame.size.height = inputFrame.origin.y;
                         DataTable.frame = tableFrame;
                     }completion:^(BOOL finish){
                         if (messageArray.count>0) {
                             [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                                              atScrollPosition:UITableViewScrollPositionBottom
                                                      animated:YES];
                         }

                     }];

//	keyboardIsShowing = YES;
    
//    [self slideFrame:YES 
//               curve:animationCurve 
//            duration:animationDuration];
}

// Expand textview on keyboard dismissal
- (void)keyboardWillHide:(NSNotification *)notification 
{
	//NSLog(@"keyboardWillHide");
 	NSDictionary *userInfo = [notification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    //把输入框位置下移
    CGRect inputFrame = inputContainer.frame;
    //64＝20＋44。20是statusbar的高度，44是navigationbar的高度
    //取到的keyboardEndFrame的orgin是相对于window的
    inputFrame.origin.y = keyboardEndFrame.origin.y - inputFrame.size.height-64;
    [UIView animateWithDuration:0.2
                     animations:^{
                         inputContainer.frame = inputFrame;
                         
                         CGRect tableFrame = DataTable.frame;
                         tableFrame.size.height = inputFrame.origin.y;
                         DataTable.frame = tableFrame;
                     }completion:^(BOOL finish){
                         if (messageArray.count>0) {
                             [DataTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messageArray.count-1 inSection:0]
                                              atScrollPosition:UITableViewScrollPositionBottom
                                                      animated:YES];
                         }
                     }];
    
    //NSLog(@"keyboardEndFrame:%@",NSStringFromCGRect(keyboardEndFrame));
//	keyboardIsShowing = NO;
    
//    [self slideFrame:NO 
//               curve:animationCurve 
//            duration:animationDuration];
}

- (void)textViewDidChange:(UITextView *)textView{
    //判断是否要更改container的高度，在输入框内显示更多的文字
    if (inputView.contentSize.height<100&&inputView.contentSize.height>30) {
        CGRect inputFrame = inputContainer.frame;
        //contentsize的高度和frame的高度一样，就能显示所有正在输入的文字
        inputFrame.size.height = inputView.contentSize.height+10;
        //64＝20＋44。20是statusbar的高度，44是navigationbar的高度
        //取到的keyboardEndFrame的orgin是相对于window的
        inputFrame.origin.y = keyboardEndFrame.origin.y - inputFrame.size.height-64;
        //必须更改inputContainer的高度，因为inputView是放在inputContainer内的且他的高度可变
        //inputContainer的高度改变，inputView会随之改变
        inputContainer.frame = inputFrame;
        inputView.scrollEnabled = NO;
    }else {
        inputView.scrollEnabled = YES;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    //tableview滑动代表用户想要看到所有的聊天内容，键盘隐藏
    //[inputView resignFirstResponder];
    if ([scrollView isKindOfClass:[UITextView class]]) {
        if (inputView.contentSize.height<100&&inputView.contentSize.height>30) {
            [inputView setContentOffset:CGPointMake(0, 6)];
        }
    }else {
        //[inputView resignFirstResponder];
    }
}

-(void)sendButtonClick:(id)sender{
    //把输入框中文字去掉头尾空白符和换行符
    NSString *content = [inputView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //把输入框清空
    inputView.text = @"";
    //拼写xml格式的xmpp消息
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:content];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    //[message addAttributeWithName:@"type" stringValue:@"chat"];
    //消息发送者
    [message addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults]objectForKey:kXMPPmyJID]];
    //消息接受者
    [message addAttributeWithName:@"to" stringValue:friendEntity.name];
    [message addChild:body];
    NSLog(@"friendEntity.name:%@",friendEntity.name);
    iPhoneXMPPAppDelegate *appDelegate = (iPhoneXMPPAppDelegate*)[[UIApplication sharedApplication]delegate];
    //新建消息的entity
    MessageEntity *messageEntity = [NSEntityDescription insertNewObjectForEntityForName:@"MessageEntity"
                                                                 inManagedObjectContext:appDelegate.managedObjectContext];
    messageEntity.content = content;
    messageEntity.sendDate = [NSDate date];
    //设置消息的接受者和发送者
    PersonEntity *senderUserEntity = [appDelegate fetchPerson:selfEntity.name];
    messageEntity.sender = senderUserEntity;
    [senderUserEntity addSendedMessagesObject:messageEntity];
    messageEntity.receiver = [appDelegate fetchPerson:friendEntity.name];
    [appDelegate saveContext];
    
    XMPPElementReceipt *receipt;
    //发送消息
    [[[iPhoneXMPPAppDelegate sharedAppDelegate] xmppStream]sendElement:message andGetReceipt:&receipt];
    NSLog(@"message ready to send:%@",[[NSDate alloc]init]);
    //等待发送成功，可以设置最长等待时间
    if ([receipt wait:20]) {
        //会延迟几秒
        NSLog(@"message sended:%@",[[NSDate alloc]init]);
        //因为服务器端和客户端都在本地，所以发送消息无延迟，方便在本机测试延伸的动画，需要延迟几秒调用发送成功
        [self performSelector:@selector(messageSendedDelay:)
                   withObject:messageEntity
                   afterDelay:2];
    }else {
        NSLog(@"sendedFail");
    }
}

-(void)messageSendedDelay:(MessageEntity*)messageEntity{
    //在正式项目中，不需要本方法，本方法是用于测试loadingView是否显示正确
    messageEntity.flag_sended = [NSNumber numberWithBool:YES];
    [[iPhoneXMPPAppDelegate sharedAppDelegate] saveContext];
}

-(void)dismissButtonClick{
    [inputView resignFirstResponder];
}

#pragma mark chat
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath{
    if ([anObject isKindOfClass:[MessageEntity class]]&&type==NSFetchedResultsChangeInsert) {
        MessageEntity *messageEntity = (MessageEntity*)anObject;
        NSIndexPath *dateIndexPath = nil;
        //判断和前一条消息的间隔时间
        if (messageArray.count>0) {
            //和前一条的日期比较，判断是否超过15分钟
            MessageEntity *previousEntity = [messageArray objectAtIndex:messageArray.count-1];
            //计算两个日期之间的秒数
            NSTimeInterval timeIntervalBetween = [messageEntity.sendDate timeIntervalSinceDate:previousEntity.sendDate];
            //判断两个日期间隔是否超过15分钟
            if (timeIntervalBetween>15*60) {
                [messageArray addObject:messageEntity.sendDate];
                dateIndexPath = [NSIndexPath indexPathForRow:messageArray.count-1 inSection:0];
            }
        }else {
            //以前没有内容
            [messageArray addObject:messageEntity.sendDate];
            dateIndexPath = [NSIndexPath indexPathForRow:messageArray.count-1 inSection:0];
        }
        [messageArray addObject:anObject];
        //[DataTable reloadData];
        //在最后一行添加聊天内容
        NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:messageArray.count-1 inSection:0];
        //bottom代表动画从下到上
        NSMutableArray *indexPathArray = [NSMutableArray array];
        if (dateIndexPath!=nil) {
            [indexPathArray addObject:dateIndexPath];
        }
        [indexPathArray addObject:insertIndexPath];
        [DataTable insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationBottom];
        //
        [DataTable scrollToRowAtIndexPath:insertIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }else if (type==NSFetchedResultsChangeUpdate) {
        //fetchResultsController的indexPath不是DataTable的indexPath,因为messageArray中有日期
        NSIndexPath *messageIndexPath = [NSIndexPath indexPathForRow:[messageArray indexOfObject:anObject] inSection:0];
        [DataTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:messageIndexPath]
                         withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark tableview
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    //直接返回messageArray的数量
    return messageArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //计算聊天内容需要的高度
    CGFloat rowHeight = 0;
    id messageObject = [messageArray objectAtIndex:indexPath.row];
    //因为messageArray有日期和MessageEntity两种对象
    if ([messageObject isKindOfClass:[MessageEntity class]]) {
        MessageEntity *messageEntity = (MessageEntity*)messageObject;
        CGSize contentSize =  [messageEntity.content sizeWithFont:[UIFont systemFontOfSize:14]
                                                constrainedToSize:CGSizeMake(200, CGFLOAT_MAX)];
        rowHeight = contentSize.height+30;
    }else if ([messageObject isKindOfClass:[NSDate class]]) {
        //用于显示日期的label
        rowHeight = 30;
    }
    return rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = nil;
    //右边的cell，显示自己发送的消息
    id messageObject = [messageArray objectAtIndex:indexPath.row];
    //判断数组中的是否messageEntity，因为还有可能是时间
    if ([messageObject isKindOfClass:[MessageEntity class]]) {
        //判断消息应该显示在左边还是右边
        MessageEntity *messageEntity = (MessageEntity*)messageObject;
        //取出这条消息的发送者的jid，和当前用户的jid进行比较，判断是否一致
        //NSLog(@"sender:%@,self:%@",messageEntity.sender.name,selfEntity.name);
        if ([messageEntity.sender.name isEqualToString:selfEntity.name]) {
            //要显示在右边
            //NSLog(@"content:%@,sender:%@",messageEntity.content,messageEntity.sender.name);
            UITableViewCell *rightCell = [DataTable dequeueReusableCellWithIdentifier:@"rightCell"];
            if (rightCell==nil) {
                rightCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:@"rightCell"];
                //高度定制的cell，通常都不能默认的方式选中
                rightCell.selectionStyle = UITableViewCellSelectionStyleNone;
                //设置不可拉伸的区域,通常不可拉伸的区域是圆角，尖角
                UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGreen"]resizableImageWithCapInsets:UIEdgeInsetsMake(19, 8, 8, 16)];
                //ballon的frame会随消息内容而变化,所以在初始化的过程中设置frame没有意义
                
                UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                ballonImageView.image = ballonImageRight;
                ballonImageView.tag = kBallonImageViewTag;
                [rightCell.contentView addSubview:ballonImageView];
                //显示消息内容的label
                UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                contentLabel.backgroundColor = [UIColor clearColor];
                contentLabel.font = [UIFont systemFontOfSize:14];
                contentLabel.textAlignment = UITextAlignmentCenter;
                contentLabel.numberOfLines = NSIntegerMax;
                contentLabel.tag = kChatContentLabelTag;
                [rightCell.contentView addSubview:contentLabel];
                //不需要指定frame，只能改frame
                //只有右边的cell需要loadingView,因为左边的是显示接受到的消息
                UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                loadingView.tag = kLoadingViewTag;
                [rightCell.contentView addSubview:loadingView];
            }
            UIImageView *ballonImageView = (UIImageView*)[rightCell.contentView viewWithTag:kBallonImageViewTag];
            //计算消息显示需要的frame
            //靠右显示，最大宽度200,如果不够200,靠右显示,如果超过200，换行
            CGSize contentSize =  [messageEntity.content sizeWithFont:[UIFont systemFontOfSize:14]
                                                    constrainedToSize:CGSizeMake(200, CGFLOAT_MAX)];
            //气泡比显示的文字大
            //直接使用contentSize做frame的size，上边留5像素空白
            CGRect ballonFrame = CGRectMake(300-contentSize.width, 5, contentSize.width+20, contentSize.height+20);
            ballonImageView.frame = ballonFrame;
            
            UILabel *contentLabel = (UILabel*)[rightCell.contentView viewWithTag:kChatContentLabelTag];
            //contentLabel的frame比气泡小
            CGRect contentFrame = CGRectMake(307-contentSize.width, 7, contentSize.width, contentSize.height+10);
            contentLabel.frame = contentFrame;
            contentLabel.text = messageEntity.content;
            
            UIActivityIndicatorView *loadingView = (UIActivityIndicatorView*)[rightCell.contentView viewWithTag:kLoadingViewTag];
            //loadingView显示在气泡的左边
            loadingView.center = CGPointMake(280-contentSize.width, 25);
            //判断是否显示
            //用startAnimaton和stopAnimation来设置显示和隐藏
            if ([messageEntity.flag_sended boolValue]) {
                //发送成功，隐藏loadingView
                [loadingView stopAnimating];
            }else {
                //正在发送，显示loadingView
                [loadingView startAnimating];
            }
            //rightCell.textLabel.text = messageEntity.content;
            cell = rightCell;
        }
        else{
            //别人发的消息，显示在左边
            UITableViewCell *leftCell = [DataTable dequeueReusableCellWithIdentifier:@"leftCell"];
            if (leftCell==nil) {
                leftCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:@"leftCell"];
                //高度定制的cell，通常都不能默认的方式选中
                leftCell.selectionStyle = UITableViewCellSelectionStyleNone;
                //设置不可拉伸的区域,通常不可拉伸的区域是圆角，尖角
                //因为图片的尖角在左边，所以左边的不可拉伸区域大一些
                UIImage *ballonImageRight = [[UIImage imageNamed:@"ChatBubbleGray"]resizableImageWithCapInsets:UIEdgeInsetsMake(19.0f, 16.0f, 8.0f, 8.0f)];
                //ballon的frame会随消息内容而变化,所以在初始化的过程中设置frame没有意义
                
                UIImageView *ballonImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
                ballonImageView.image = ballonImageRight;
                ballonImageView.tag = kBallonImageViewTag;
                [leftCell.contentView addSubview:ballonImageView];
                //显示消息内容的label
                UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectZero];
                contentLabel.backgroundColor = [UIColor clearColor];
                contentLabel.font = [UIFont systemFontOfSize:14];
                contentLabel.textAlignment = UITextAlignmentCenter;
                contentLabel.numberOfLines = NSIntegerMax;
                contentLabel.tag = kChatContentLabelTag;
                [leftCell.contentView addSubview:contentLabel];
            }
            UIImageView *ballonImageView = (UIImageView*)[leftCell.contentView viewWithTag:kBallonImageViewTag];
            //计算消息显示需要的frame
            //靠右显示，最大宽度200,如果不够200,靠右显示,如果超过200，换行
            CGSize contentSize =  [messageEntity.content sizeWithFont:[UIFont systemFontOfSize:14]
                                                    constrainedToSize:CGSizeMake(200, CGFLOAT_MAX)];
            //气泡比显示的文字大
            //直接使用contentSize做frame的size，上边留5像素空白
            CGRect ballonFrame = CGRectMake(0, 5, contentSize.width+20, contentSize.height+20);
            ballonImageView.frame = ballonFrame;
            
            UILabel *contentLabel = (UILabel*)[leftCell.contentView viewWithTag:kChatContentLabelTag];
            //contentLabel的frame比气泡小
            CGRect contentFrame = CGRectMake(13, 7, contentSize.width, contentSize.height+10);
            contentLabel.frame = contentFrame;
            contentLabel.text = messageEntity.content;
            //rightCell.textLabel.text = messageEntity.content;
            
            cell = leftCell;
        }
    }else if ([messageObject isKindOfClass:[NSDate class]]) {
        //用于显示日期的label
        UITableViewCell *dateCell = [DataTable dequeueReusableCellWithIdentifier:@"dateCell"];
        if (dateCell==nil) {
            dateCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                             reuseIdentifier:@"dateCell"];
            dateCell.selectionStyle = UITableViewCellSelectionStyleNone;
            //居中显示发送日期
            UILabel *dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(80, 5, 160, 20)];
            dateLabel.backgroundColor = [UIColor clearColor];
            dateLabel.font = [UIFont systemFontOfSize:14];
            dateLabel.textColor = [UIColor lightGrayColor];
            dateLabel.textAlignment = UITextAlignmentCenter;
            dateLabel.tag = kDateLabelTag;
            [dateCell.contentView addSubview:dateLabel];
        }
        UILabel *dateLabel = (UILabel*)[dateCell.contentView viewWithTag:kDateLabelTag];
        NSDate *messageSendDate = (NSDate*)messageObject;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        dateLabel.text = [dateFormatter stringFromDate:messageSendDate];
        cell = dateCell;
    }
    //避免cell为空,比直接在每个分支中返回cell要安全
    if (cell==nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:@"cell"];
    }
    return cell;
}
@end
