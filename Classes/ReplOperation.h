//
//  ReplOperation.h
//  Recipes
//
//  Created by Mike Kistler on 8/5/15.
//

#import <Foundation/Foundation.h>

typedef enum {
	ReplOperationPull,
	ReplOperationPush,
} ReplOperationType;

@interface ReplOperation : NSOperation

+ (ReplOperation *)operationWithType:(ReplOperationType)type managedObjectContext:(NSManagedObjectContext *)mainMoc;

@property (nonatomic, readonly) NSURL *remoteURL;

@end
