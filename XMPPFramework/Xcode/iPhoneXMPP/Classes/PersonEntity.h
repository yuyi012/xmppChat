//
//  PersonEntity.h
//  iPhoneXMPP
//
//  Created by 俞 億 on 12-5-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MessageEntity;

@interface PersonEntity : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *sendedMessages;
@end

@interface PersonEntity (CoreDataGeneratedAccessors)

- (void)addSendedMessagesObject:(MessageEntity *)value;
- (void)removeSendedMessagesObject:(MessageEntity *)value;
- (void)addSendedMessages:(NSSet *)values;
- (void)removeSendedMessages:(NSSet *)values;

@end
