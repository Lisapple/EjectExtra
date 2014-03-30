//
//  Eject_ExtraAppDelegate.m
//  Eject Extra
//
//  Created by Max on 20/01/2010.
//  Copyright 2010 Lis@cintosh. All rights reserved.
//

#import "Eject_ExtraAppDelegate.h"

#import "NSMenu+addition.h"

@implementation Eject_ExtraAppDelegate

@synthesize window;
@synthesize versionLabel, copyrightLabel;

@synthesize ejectSound;

const NSInteger kDeviceMenuItemTag = 1234;
const NSInteger kErrorMenuItemTag = 2345;
const NSInteger kEjectAllMenuItemTag = 3456;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	
	if ([self mountedRemovableVolumes].count > 0)
		[statusItem setImage:[NSImage imageNamed:@"Eject.pdf"]];
	else
		[statusItem setImage:[NSImage imageNamed:@"Eject_inactive.pdf"]];
	
	[statusItem setAlternateImage:[NSImage imageNamed:@"Eject_alt.pdf"]];
	[statusItem setHighlightMode:YES];
	
	menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	NSMenu * moreMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	
	NSMenuItem * launchOptionItem = [[NSMenuItem alloc] initWithTitle:@"Launch at Login" action:@selector(launchOptionAction:) keyEquivalent:@""];
	
	BOOL lauchAtLogin = [self applicationIsLaunchedAtLogin];
	[launchOptionItem setState:(lauchAtLogin)? NSOnState: NSOffState];
	[moreMenu addItem:launchOptionItem];
	
	[moreMenu addItem:[NSMenuItem separatorItem]];
	[moreMenu addItemWithTitle:NSLocalizedString(@"Feedback...", nil) action:@selector(showFeedback:) keyEquivalent:@""];
	[moreMenu addItemWithTitle:NSLocalizedString(@"About...", nil) action:@selector(about) keyEquivalent:@""];
	
	[moreMenu addItem:[NSMenuItem separatorItem]];
	[moreMenu addItemWithTitle:NSLocalizedString(@"Quit", nil) action:@selector(quit) keyEquivalent:@""];
	
	NSMenuItem * moreMenuItem = [[NSMenuItem alloc] initWithTitle:@"More" action:nil keyEquivalent:@""];
	[moreMenuItem setSubmenu:moreMenu];
	[menu addItem:moreMenuItem];
	
	[menu setAutoenablesItems:NO];
	[menu setDelegate:self];
	[statusItem setMenu:menu];
	
	NSNotificationCenter * center = [[NSWorkspace sharedWorkspace] notificationCenter];
	[center addObserver:self selector:@selector(deviceDidMount:) name:NSWorkspaceDidMountNotification object:nil];
	[center addObserver:self selector:@selector(deviceDidUnmount:) name:NSWorkspaceDidUnmountNotification object:nil];
	
	
	NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString * shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	[versionLabel setStringValue:[NSString stringWithFormat:@"Version %@ (%@)", version, shortVersion]];
	
	NSString * copyright = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
	[copyrightLabel setStringValue:copyright];
}

#pragma mark -
#pragma mark Notification Handler

- (void)deviceDidMount:(NSNotification *)aNotification
{
	NSDebugLog(@"deviceDidMount: %@", [[aNotification userInfo] objectForKey:@"NSDevicePath"]);
	//NSString *path = [[aNotification userInfo] objectForKey:@"NSDevicePath"];
	
	if ([self mountedRemovableVolumes].count > 0)
		[statusItem setImage:[NSImage imageNamed:@"Eject.pdf"]];
	else
		[statusItem setImage:[NSImage imageNamed:@"Eject_inactive.pdf"]];
	
	[[menu delegate] menuNeedsUpdate:menu];
}

- (void)deviceDidUnmount:(NSNotification *)aNotification
{
	NSDebugLog(@"deviceDidUnmount");
	
	if ([self mountedRemovableVolumes].count > 0)
		[statusItem setImage:[NSImage imageNamed:@"Eject.pdf"]];
	else
		[statusItem setImage:[NSImage imageNamed:@"Eject_inactive.pdf"]];
	
	[[menu delegate] menuNeedsUpdate:menu];
}

#pragma mark -
#pragma mark NSMenuDegate

- (void)menuNeedsUpdate:(NSMenu *)aMenu
{
	NSInteger index = [menu itemsWithTag:kErrorMenuItemTag].count;
	
	NSArray * mountedRemovableVolumes = [self mountedRemovableVolumes];
	if (mountedRemovableVolumes.count > 0) {
		NSDebugLog(@"mountedDevices: %@", mountedRemovableVolumes);
	}
	
	[menu removeAllItemsWithTag:kDeviceMenuItemTag];
	if (mountedRemovableVolumes.count == 0) {
		NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"NO_DEVICES_CONNECTED", nil)
														   action:nil
													keyEquivalent:@""];
		[menuItem setTag:kDeviceMenuItemTag];
		[menuItem setEnabled:NO];
		[menu insertItem:menuItem atIndex:index];
	} else {
		for (NSString * fullpath in mountedRemovableVolumes) {
			NSDictionary * attributes = [self attributesForDeviceAtPath:fullpath];
			BOOL isRemovable = [[attributes objectForKey:@"Removable"] boolValue];
			if (isRemovable) {
				NSString * displayName = [[NSFileManager defaultManager] displayNameAtPath:fullpath];
				NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:displayName
																   action:@selector(eject:)
															keyEquivalent:@""];
				[menuItem setTag:kDeviceMenuItemTag];
				[menuItem setImage:[NSImage imageNamed:@"Eject.pdf"]];
				[menu insertItem:menuItem atIndex:index];
			}
		}
	}
	
	[menu removeItemWithTag:kEjectAllMenuItemTag];
	if ([NSEvent modifierFlags] == NSAlternateKeyMask && (mountedRemovableVolumes.count > 0)) {
		NSMenuItem * ejectAllItem = [[NSMenuItem alloc] initWithTitle:@"Eject All" action:@selector(ejectAll:) keyEquivalent:@""];
		[ejectAllItem setTag:kEjectAllMenuItemTag];
		[menu insertItem:ejectAllItem atIndex:index];
	}
}

- (void)menu:(NSMenu *)aMenu willHighlightItem:(NSMenuItem *)item
{
	static NSMenuItem * oldMenuItem = nil;
	
	if ([oldMenuItem tag] == kDeviceMenuItemTag)
		[oldMenuItem setImage:[NSImage imageNamed:@"Eject.pdf"]];
	
	if ([item tag] == kDeviceMenuItemTag) {
		[item setImage:[NSImage imageNamed:@"Eject_alt.pdf"]];
		
		oldMenuItem = item;
	}
}

- (NSDictionary *)attributesForDeviceAtPath:(NSString *)aPath
{
	BOOL isRemovable = NO;
	BOOL isWritable = NO;
	BOOL isUnmountable = NO;
	NSString * description = nil;
	NSString * fileSystemType = nil;
	[[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:aPath
												isRemovable:&isRemovable
												 isWritable:&isWritable
											  isUnmountable:&isUnmountable 
												description:&description
													   type:&fileSystemType];
	NSArray * objects = [NSArray arrayWithObjects:aPath, [NSNumber numberWithBool:isRemovable], [NSNumber numberWithBool:isWritable],
						 [NSNumber numberWithBool:isUnmountable], description, fileSystemType, nil];
	NSArray * keys = [NSArray arrayWithObjects:@"Path", @"Removable", @"Writable", @"Unmountable", @"Description", @"FileSystemType", nil];
	NSDictionary * attributes = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	return attributes;
}

- (NSArray *)mountedRemovableVolumes
{
	NSArray * properties = [[NSArray alloc] initWithObjects:NSURLLocalizedNameKey, NSURLVolumeURLKey, NSURLIsHiddenKey, NSURLEffectiveIconKey, nil];
	NSArray * volumesURLs = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:properties options:0];
	
	NSMutableArray * mountedDevices = [NSMutableArray arrayWithCapacity:volumesURLs.count];
	for (NSURL * volumeURL in volumesURLs) {
		[mountedDevices addObject:[volumeURL path]];
	}
	
	NSArray * mountedDevicesCopy = [mountedDevices copy];
	NSInteger length = @"/Volumes/".length;
	for (NSString * device in mountedDevicesCopy) {
		if (device.length <= length || (device.length > length && ![[device substringWithRange:NSMakeRange(0, length)] isEqualToString:@"/Volumes/"]))
			[mountedDevices removeObject:device];
	}
	
	return mountedDevices;
}

- (void)unmountDeviceWithPath:(NSString *)path
{
	@autoreleasepool {
	
		NSDebugLog(@"Eject device at Path: %@", path);
		
		[statusItem setImage:[NSImage imageNamed:@"Ejecting.pdf"]];
		
		NSError * error = nil;
		BOOL succeed = NO;
		NSWorkspace * workspace = [NSWorkspace sharedWorkspace];
		if ([workspace respondsToSelector:@selector(unmountAndEjectDeviceAtURL:error:)]) {
			succeed = [workspace unmountAndEjectDeviceAtURL:[NSURL fileURLWithPath:path] error:&error];
		} else {
			succeed = [workspace unmountAndEjectDeviceAtPath:[NSURL fileURLWithPath:path]];
		}
		
		[menu removeAllItemsWithTag:kErrorMenuItemTag];
		
		if (!succeed) {
			NSLog(@"unmountDeviceWithPath Failed: %@ -> %@", [error localizedDescription], [error localizedRecoverySuggestion]);
			
			NSString * title = [NSString stringWithFormat:@"Ejecting %@ Failed: %@", [path lastPathComponent], [error localizedRecoverySuggestion]];
			NSMenuItem * errorItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
			[errorItem setTag:kErrorMenuItemTag];
			[errorItem setEnabled:NO];
			[menu insertItem:errorItem atIndex:0];
			
			NSMenuItem * separator = [NSMenuItem separatorItem];
			[separator setTag:kErrorMenuItemTag];
			[menu insertItem:separator atIndex:1];// Add separator
			
			[statusItem setImage:[NSImage imageNamed:@"Eject_failed.pdf"]];
		} else {
			
			if (![ejectSound isPlaying]) {
				NSString * path = [[NSBundle mainBundle] pathForResource:@"eject" ofType:@"mp3"];
				ejectSound = [[NSSound alloc] initWithContentsOfFile:path byReference:YES];
				[ejectSound setVolume:0.5];
				[ejectSound play];
			}
			
			if ([self mountedRemovableVolumes].count > 0)
				[statusItem setImage:[NSImage imageNamed:@"Eject.pdf"]];
			else
				[statusItem setImage:[NSImage imageNamed:@"Eject_inactive.pdf"]];
		}
		
		[(NSObject *)[menu delegate] performSelectorOnMainThread:@selector(menuNeedsUpdate:) withObject:menu waitUntilDone:NO];
	
	}
}

- (void)ejectAll:(id)sender
{
	NSArray * mountedRemovableVolumes = [self mountedRemovableVolumes];
	for (NSString * devicePath in mountedRemovableVolumes) {
		[NSThread detachNewThreadSelector:@selector(unmountDeviceWithPath:) toTarget:self withObject:devicePath];
	}
}

- (void)eject:(id)sender
{
	NSString * fullpath = [NSString stringWithFormat:@"/Volumes/%@/", [sender title]];
	[NSThread detachNewThreadSelector:@selector(unmountDeviceWithPath:) toTarget:self withObject:fullpath];
}

- (BOOL)applicationIsLaunchedAtLogin
{
	return ([self indexOfLoginPreferenceEntry] != -1);
}

- (IBAction)launchOptionAction:(id)sender
{
	NSMenuItem * menuItem = (NSMenuItem *)sender;
	
	/* (des)activate the launch at login and (un)check the menuItem (from sender) depending if app launch at login */
	BOOL lauchAtLogin = [self applicationIsLaunchedAtLogin];
	if (lauchAtLogin) {
		[menuItem setState:NSOffState];
		[self unlaunchAtLogin];
	} else {
		[menuItem setState:NSOnState];
		[self launchAtLogin];
	}
}

- (void)launchAtLogin
{
	CFArrayRef prefArrayRef = CFPreferencesCopyAppValue(CFSTR("AutoLaunchedApplicationDictionary"), CFSTR("loginwindow"));
	CFMutableArrayRef prefArrayRefCopy = CFArrayCreateMutableCopy(kCFAllocatorDefault, 0, prefArrayRef);
	CFRelease(prefArrayRef);
	
	CFMutableDictionaryRef theDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
	CFDictionaryAddValue(theDict, CFSTR("Hide"), kCFBooleanFalse);
	
	NSString * path = [[NSBundle mainBundle] bundlePath];
	
	const char * cPath = [path cStringUsingEncoding:NSUTF8StringEncoding];
	CFStringRef pathRef = CFStringCreateWithCString(kCFAllocatorDefault, cPath, kCFStringEncodingUTF8);
	
	CFDictionaryAddValue(theDict, CFSTR("Path"), pathRef);
	CFRelease(pathRef);
	
#if defined(MAC_OS_X_VERSION_10_6)
	/* From Mac OS X.6, add AliasData attribute */
	
	CFURLRef urlRef = (__bridge CFURLRef)[[NSBundle mainBundle] bundleURL];
	
	CFErrorRef errorRef = NULL;
	CFDataRef dataRef = CFURLCreateBookmarkData(kCFAllocatorDefault, urlRef, kCFURLBookmarkCreationPreferFileIDResolutionMask, NULL, NULL, &errorRef);
	
	CFDictionaryAddValue(theDict, CFSTR("AliasData"), dataRef);
	CFRelease(dataRef);
	
#endif
	
	CFArrayAppendValue(prefArrayRefCopy, theDict);
	CFRelease(theDict);
	
	CFPreferencesSetAppValue(CFSTR("AutoLaunchedApplicationDictionary"), prefArrayRefCopy, CFSTR("loginwindow"));
	CFRelease(prefArrayRefCopy);
	
	CFPreferencesAppSynchronize(CFSTR("loginwindow"));
}

- (void)unlaunchAtLogin
{
	NSInteger index = [self indexOfLoginPreferenceEntry];
	
	if (index != -1) {
		
		CFArrayRef prefArrayRef = CFPreferencesCopyAppValue(CFSTR("AutoLaunchedApplicationDictionary"), CFSTR("loginwindow"));
		CFMutableArrayRef prefArrayRefCopy = CFArrayCreateMutableCopy(kCFAllocatorDefault, 0, prefArrayRef);
		CFRelease(prefArrayRef);
		
		CFArrayRemoveValueAtIndex(prefArrayRefCopy, index);
		
		CFPreferencesSetAppValue(CFSTR("AutoLaunchedApplicationDictionary"), prefArrayRefCopy, CFSTR("loginwindow"));
		CFRelease(prefArrayRefCopy);
		
		CFPreferencesAppSynchronize(CFSTR("loginwindow"));
	}
}

- (NSInteger)indexOfLoginPreferenceEntry
{
	CFArrayRef prefArrayRef = CFPreferencesCopyAppValue(CFSTR("AutoLaunchedApplicationDictionary"), CFSTR("loginwindow"));
	
	/* For all entries... */
	for (CFIndex index = 0; index < CFArrayGetCount(prefArrayRef); index++) {
		
		CFStringRef bundlePathRef = (__bridge CFStringRef)[[NSBundle mainBundle] bundlePath];
		
		CFDictionaryRef dict = CFArrayGetValueAtIndex(prefArrayRef, index);
		CFStringRef pathRef = CFDictionaryGetValue(dict, CFSTR("Path"));
		
		/* ...find the correct bundle reference and returns the index */
		if (CFStringCompare(bundlePathRef, pathRef, kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
			
			CFRelease(prefArrayRef);
			return (NSInteger)index;
		}
	}
	
	CFRelease(prefArrayRef);
	return -1;
}

- (IBAction)showFeedback:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://support.lisacintosh.com/other"]];
}

- (void)about
{
	[window makeKeyAndOrderFront:self];
	
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)quit
{
	[NSApp terminate:self];
}

- (IBAction)showWebsite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://lisacintosh.com/old-projects/"]];
}

@end
