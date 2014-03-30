//
//  NSMenuItem+addition.m
//  Eject Extra
//
//  Created by Max on 08/06/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NSMenu+addition.h"


@implementation NSMenu (addition)

- (NSArray *)itemsWithTag:(NSInteger)tag
{
	NSMutableArray * items = [NSMutableArray arrayWithCapacity:3];
	for (NSMenuItem * item in [self itemArray]) {
		if ([item tag] == tag)
			[items addObject:item];
	}
	
	return (NSArray *)items;
}

- (void)removeItemWithTag:(NSInteger)tag
{
	NSMenuItem * item = [self itemWithTag:tag];
	if (item) {
		[self removeItem:item];
	}
}

- (void)removeAllItemsWithTag:(NSInteger)tag
{
	NSArray * items = [self itemsWithTag:tag];
	for (NSMenuItem * item in items) {
		[self removeItem:item];
	}
}

@end
