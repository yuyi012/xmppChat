//
//  MessageEntity.h
//  iPhoneXMPP
//
//  Created by 俞 億 on 12-5-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersonEntity;

@interface MessageEntity : NSManagedObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSNumber * flag_sended;
@property (nonatomic, retain) NSDate * sendDate;
@property (nonatomic, retain) NSNumber * flag_readed;
@property (nonatomic, retain) PersonEntity *receiver;
@property (nonatomic, retain) PersonEntity *sender;

@end
