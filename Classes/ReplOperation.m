//
//  ReplOperation.m
//  Recipes
//
//  Created by Mike Kistler on 8/5/15.
//

#import "ReplOperation.h"

#import <CDTIncrementalStore/CDTIncrementalStore.h>

@interface ReplOperation () <CDTReplicatorDelegate>

typedef enum {
	ReplOperationStateInit,
	ReplOperationStateExecuting,
	ReplOperationStateFinished
} ReplOperationState;

@property (nonatomic, assign) ReplOperationState state;

@property (nonatomic, assign) ReplOperationType		replType;
@property (nonatomic, strong) NSPersistentStoreCoordinator *psc;
@property (nonatomic, strong) NSManagedObjectContext *moc;
@property (nonatomic, strong) CDTISReplicator		*replicator;

@property (nonatomic, strong) NSURL					*remoteURL;

@end

@implementation ReplOperation

+ (ReplOperation *)operationWithType:(ReplOperationType)type managedObjectContext:(NSManagedObjectContext *)mainMoc
{
	ReplOperation *op = [[ReplOperation alloc] init];
	op.replType = type;
	op.psc = mainMoc.persistentStoreCoordinator;
	return op;
}

- (NSURL *)remoteURL
{
	/*
	if (_remoteURL == nil) {

		NSString *hostname = @"yourcloudantid.cloudant.com";
		NSString *dbname = @"recipes";
		NSString *key = @"APIKEY";
		NSString *password = @"APIPASSWORD";

		_remoteURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@:%@@%@/%@",
									   key, password, hostname, dbname]];
	}
	 */
	return _remoteURL;
}

#pragma mark - NSOperation methods

- (BOOL)isConcurrent
{
	/* According to Apple TN2109, concurrent operations "bring their own concurrency. NSOperationQueue does not have to
	 dedicate a thread to running such operations."  Since all query operations will generate messages to the back end,
	 they bring their own concurrency" in this respect, so we return YES. */
	return YES;
}

- (void)main
{
	// Since we provide our own implementation of start, main should never be called.
	NSLog(@"ReplOperation main called for operation %@", self);
}

#pragma mark - NSOperation state handling

// Note that we let the base class handle the "ready" state and KVO notification, but must provide
// our own implementations of executing and finished because we override the start method.

/** Change the state of the operation, sending the appropriate KVO notifications. */
- (void)setState:(ReplOperationState)newState
{
	@synchronized(self)
	{
		ReplOperationState oldState = _state;

		// State must monotonically progress
		assert(newState > oldState);

		if ((newState == ReplOperationStateExecuting) || (oldState == ReplOperationStateExecuting)) {
			[self willChangeValueForKey:@"isExecuting"];
		}
		if (newState == ReplOperationStateFinished) {
			[self willChangeValueForKey:@"isFinished"];
		}
		_state = newState;
		if ((newState == ReplOperationStateExecuting) || (oldState == ReplOperationStateExecuting)) {
			[self didChangeValueForKey:@"isExecuting"];
		}
		if (newState == ReplOperationStateFinished) {
			[self didChangeValueForKey:@"isFinished"];
		}
	}
}

- (BOOL)isExecuting
{
	return (self.state == ReplOperationStateExecuting);
}

- (BOOL)isFinished
{
	return (self.state == ReplOperationStateFinished);
}

#pragma mark - NSOperation methods

/* We override start because the default start method will set isFinished when main returns,
 and we do not want that. */

- (void)start
{
	NSLog(@"Entering ReplOperation start");

	// Always check for cancellation before launching the task.
	if ([self isCancelled]) {
		// Must move the operation to the finished state if it is cancelled.
		self.state = ReplOperationStateFinished;
		return;
	}

	self.state = ReplOperationStateExecuting;

	/* Doc for NSManagedObjectContext says: If you use NSOperation, you must create the context
	 in main (for a serial queue) or start (for a concurrent queue). */

	self.moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	self.moc.persistentStoreCoordinator = self.psc;

	NSArray *stores = [self.psc persistentStores];
	NSUInteger indx = [stores indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return [obj isKindOfClass:[CDTIncrementalStore class]];
	}];
	CDTIncrementalStore *cdtis = (indx != NSNotFound) ? (CDTIncrementalStore *)stores[indx] : nil;

	NSError *err;
	switch (self.replType) {
		case ReplOperationPull:
			self.replicator = [cdtis replicatorThatPullsFromURL:self.remoteURL withError:&err];
			break;
		case ReplOperationPush:
			self.replicator = [cdtis replicatorThatPushesToURL:self.remoteURL withError:&err];
			break;
		default:
			NSLog(@"INTERNAL ERROR: Unknown operation type of %d", self.replType);
			break;
	}

	if (err) {
		NSLog(@"ReplOperation failed - could not create replicator");
		[self finish];
		return;
	}

	self.replicator.replicator.delegate = self;
	if (([self.replicator.replicator startWithError:&err] == NO) || err) {
		NSLog(@"ReplOperation failed - replicator start failed: %@", [err description]);
		[self finish];
		return;
	}
}

- (void)finish
{
	self.state = ReplOperationStateFinished;
}

#pragma mark - CDTReplicatorDelegate methods

- (void)replicatorDidComplete:(CDTReplicator *)replicator
{
	NSLog(@"Entering replicatorDidComplete");

	if (self.replType == ReplOperationPull) {
		// After a successful pull
		NSError *err;
		NSArray *mergeConflicts = [self.replicator processConflictsWithContext:self.moc error:&err];
		NSMergePolicy *mp = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyStoreTrumpMergePolicyType];
		if (![mp resolveConflicts:mergeConflicts error:&err]) {
			NSLog(@"Conflict resolution failed: %@", [err description]);
		}
	}

	[self finish];
}

- (void)replicatorDidError:(CDTReplicator *)replicator info:(NSError *)info
{
	NSLog(@"Replicator failed: %@", [info description]);
	[self finish];
}

@end
