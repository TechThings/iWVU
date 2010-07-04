//
//  MainScreen.m
//  iWVU
//
//  Created by Jared Crawford on 1/2/10.
//  Copyright Jared Crawford 2009. All rights reserved.
//

/*
 Copyright (c) 2009 Jared Crawford
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 The trademarks owned or managed by the West Virginia 
 University Board of Governors (WVU) are used under agreement 
 between the above copyright holder(s) and WVU. The West 
 Virginia University Board of Governors maintains ownership of all 
 trademarks. Reuse of this software or software source code, in any 
 form, must remove all references to any trademark owned or 
 managed by West Virginia University.
 */ 

#import "MainScreen.h"


#import "BuildingList.h"
#import "LibraryHours.h"
#import "PRTinfo.h"
#import "U92Controller.h"
#import "BusesMain.h"
#import "EmergencyServices.h"
#import "DirectorySearch.h"
#import "DiningList.h"
#import "NewspaperSourcesViewController.h"
#import "MapFromBuildingListDriver.h"
#import "TwitterUserListViewController.h"
#import "CalendarSourcesViewController.h"
#import "SportsListViewController.h"
#import "SettingsViewController.h"

//a tag to be used for identifying view controllers which are iPad ready
#define iPAD_COMPATIBLE 53


#define BAR_SLIDE_INOUT_DURATION .5

@implementation MainScreen



- (void)loadView {
	[super loadView];
	
	self.navigationBarTintColor = [UIColor WVUBlueColor];
	
	/*
	UIBarButtonItem *infoButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"InfoIcon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(infoButtonPressed)] autorelease];
	infoButton.style = UIBarButtonItemStylePlain;
	self.navigationItem.rightBarButtonItem = infoButton;
	*/
	 
	self.view.backgroundColor = [UIColor viewBackgroundColor];
	
	
	float tickerBarHeight = 35;
	CGRect launcherViewRect = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, self.view.bounds.size.height-tickerBarHeight);
	
	NSURL *rssURL = [NSURL URLWithString:@"http://wvutoday.wvu.edu/n/rss/"];
	tickerBar = [[[TickerBar alloc] initWithURL:rssURL andFeedName:@"WVU Today"] autorelease];
	[self.view addSubview:tickerBar];
	tickerBar.frame = CGRectMake(0, self.view.bounds.size.height-tickerBarHeight, self.view.bounds.size.width, tickerBarHeight);
	tickerBar.delegate = self;
	
	[tickerBar startTicker];
	

	 
	
	launcherView = [[TTLauncherView alloc] initWithFrame:launcherViewRect];
	launcherView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin);
	launcherView.backgroundColor = [UIColor clearColor];
	launcherView.delegate = self;
	launcherView.columnCount = 3;
	
	//Now we need to load the user's layout preferences
  	NSArray *features = [self loadHomeScreenPosition];
	
	//We need to make sure the stored layout is from the current version
	static NSString *storedVersionKey = @"CurrentVersion";
	NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	BOOL storedFeaturesAreCurrent = [version isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:storedVersionKey]];
	//if it is not, delete their layout and start fresh
	if(storedFeaturesAreCurrent == NO){
		[[NSUserDefaults standardUserDefaults] setObject:version forKey:storedVersionKey];
		features = nil;
	}
	   
	
	if (features != nil) {
		launcherView.pages = features;
	}
	else {
		//the user does not have a usable stored layout
		//create the default view
		[self createDefaultView];
	}
	[self.view addSubview:launcherView];
	[self.view sendSubviewToBack:launcherView];
}


-(void)infoButtonPressed{
	
}


-(void)createDefaultView{
	NSArray *defaultFeatures = [NSArray arrayWithObjects:
								@"Athletics",
								@"Calendar",
								@"Directory",
								@"Newspaper",
								@"Twitter",
								@"Map",
								@"PRT",
								@"Buses",
								@"Libraries",
								@"Dining",
								@"U92",
								@"Emergency",
								@"WVU Mobile",
								@"WVU Today",
								@"WVU Alert",
								@"eCampus",
								@"MIX",
								@"WVU.edu",
								@"Settings",
								nil];
	
	NSMutableArray *pageItems = [NSMutableArray array];
	NSMutableArray *pageList = [NSMutableArray array];
	int itemsInPage = 9;
	int i = 0;
	
	
	for (NSString *feature in defaultFeatures) {
		if ((i%itemsInPage == 0)&&(i!=0)) {
			[pageList addObject:[NSArray arrayWithArray:pageItems]];
			pageItems = [NSMutableArray array];
		}
		
		NSString *escapedString = [feature stringByReplacingOccurrencesOfString:@" " withString:@"_"];
		escapedString = [escapedString stringByReplacingOccurrencesOfString:@"." withString:@"_"];
		
		NSString *imageURL = [NSString stringWithFormat:@"bundle://Main_%@.png",escapedString];
		
		NSString *selectorURL = [NSString stringWithFormat:@"bundle://mainScreen/%@", feature];
		
		TTLauncherItem *item = [[[TTLauncherItem alloc] initWithTitle:feature
																image:imageURL
																  URL:selectorURL canDelete:NO] autorelease];
		
		item.style = @"mainScreenLauncherButton:";
		[pageItems addObject:item];
		i++;
		
	}
	[pageList addObject:[NSArray arrayWithArray:pageItems]];
	launcherView.pages = [NSArray arrayWithArray:pageList];	
	[self saveHomeScreenPosition:launcherView.pages];
}

-(NSString *)filePathForHomeScreenPosition{	
	NSArray *multiplePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = [[multiplePaths objectAtIndex:0] stringByAppendingPathComponent:@"mainScreenPages"];
	return path;
}

-(void)resetHomeScreenPositions{
	NSString *aPath = [self filePathForHomeScreenPosition];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *err;
	[fileManager removeItemAtPath:aPath error:&err];
	[self createDefaultView];
	
}

-(void)saveHomeScreenPosition:(NSArray *)data{
	[NSKeyedArchiver archiveRootObject:data toFile:[self filePathForHomeScreenPosition]];
}

-(NSArray *)loadHomeScreenPosition{
	return [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePathForHomeScreenPosition]];
}

- (void)launcherView:(TTLauncherView*)launcher didSelectItem:(TTLauncherItem*)item{
	NSString *feature = item.title;
	
	UIViewController *viewController;
	
	if([@"Map" isEqualToString:feature]){
		MapFromBuildingListDriver *aDriver = [[MapFromBuildingListDriver alloc] init];
		BuildingList *theBuildingView = [[BuildingList alloc] initWithDelegate:(id<TTThumbsViewControllerDelegate>)aDriver];
		theBuildingView.navigationItem.title = @"Building Finder";
		UIBarButtonItem *backBuildingButton = [[UIBarButtonItem alloc] initWithTitle:@"Buildings" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		theBuildingView.navigationItem.backBarButtonItem = backBuildingButton;
		[backBuildingButton release];
		viewController = theBuildingView;
	}
	else if([@"Buses" isEqualToString:feature]){
		BusesMain *theBusesView = [[BusesMain alloc] initWithStyle:UITableViewStyleGrouped];
		theBusesView.navigationItem.title = @"Mountain Line Buses";
		UIBarButtonItem *backBusesButton = [[UIBarButtonItem alloc] initWithTitle:@"Buses" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		theBusesView.navigationItem.backBarButtonItem = backBusesButton;
		[backBusesButton release];
		viewController = theBusesView;
	}
	else if([@"U92" isEqualToString:feature]){
		U92Controller *u92view = [[U92Controller alloc] initWithNibName:@"U92Controller" bundle:nil];
		u92view.navigationItem.title = @"U92";
		viewController = u92view;
	}
	else if([@"PRT" isEqualToString:feature]){
		PRTinfo *PRTview = [[PRTinfo alloc] initWithStyle:UITableViewStyleGrouped];
		PRTview.navigationItem.title = @"PRT";
		UIBarButtonItem *PRTviewButton = [[UIBarButtonItem alloc] initWithTitle:@"PRT" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		PRTview.navigationItem.backBarButtonItem = PRTviewButton;
		[PRTviewButton release];
		viewController = PRTview;
	}
	else if([@"Libraries" isEqualToString:feature]){
		LibraryHours *theView = [[LibraryHours alloc] initWithStyle:UITableViewStyleGrouped];
		theView.navigationItem.title = @"WVU Libraries";
		UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Library" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		theView.navigationItem.backBarButtonItem = backButton;
		[backButton release];
		viewController = theView;
	}
	else if([@"Athletics" isEqualToString:feature]){
		SportsListViewController *viewController = [[SportsListViewController alloc] initWithStyle:UITableViewStyleGrouped];
		viewController.navigationItem.title = @"WVU Athletics";
		UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Athletics" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		viewController.navigationItem.backBarButtonItem = backButton;
		[backButton release];
	}
	else if([@"Emergency" isEqualToString:feature]){
		EmergencyServices *theServView = [[EmergencyServices alloc] initWithStyle:UITableViewStyleGrouped];
		theServView.navigationItem.title = @"Emergency Services";
		UIBarButtonItem *abackButton = [[UIBarButtonItem alloc] initWithTitle:@"Emergency" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		theServView.navigationItem.backBarButtonItem = abackButton;
		[abackButton release];
		viewController = theServView;
	}
	else if([@"Directory" isEqualToString:feature]){
		DirectorySearch *dirSer = [[DirectorySearch alloc] initWithNibName:@"DirectorySearch" bundle:nil];
		dirSer.navigationItem.title = @"Directory Search";
		UIBarButtonItem *abackButton = [[UIBarButtonItem alloc] initWithTitle:@"Directory" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		dirSer.navigationItem.backBarButtonItem = abackButton;
		[abackButton release];
		viewController = dirSer;
		viewController.view.tag = iPAD_COMPATIBLE;
	}
	else if([@"Dining" isEqualToString:feature]){
		DiningList *dinList = [[DiningList alloc] initWithNibName:@"DiningList" bundle:nil];
		dinList.navigationItem.title = @"On-Campus Dining";
		UIBarButtonItem *abackButton = [[UIBarButtonItem alloc] initWithTitle:@"Dining" style:UIBarButtonItemStyleBordered	target:nil action:nil];
		dinList.navigationItem.backBarButtonItem = abackButton;
		[abackButton release];
		viewController = dinList;
	}
	else if([@"WVU Mobile" isEqualToString:feature]){
		OPENURL(@"http://m.wvu.edu")
	}
	else if([@"Newspaper" isEqualToString:feature]){
		NewspaperSourcesViewController *viewController = [[NewspaperSourcesViewController alloc] initWithStyle:UITableViewStyleGrouped];
		viewController.title = @"Newspaper";
	}
	else if([@"Settings" isEqualToString:feature]){
		SettingsViewController *viewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
		viewController.title = @"Settings";
	}
	else if([@"Twitter" isEqualToString:feature]){
		TwitterUserListViewController *twitterUsers = [[TwitterUserListViewController alloc] initWithStyle:UITableViewStyleGrouped];
		twitterUsers.navigationItem.title = @"WVU on Twitter";
		UIImage *flyingWVTwitter = [UIImage imageNamed:@"WVOnTwitter.png"];
		twitterUsers.navigationItem.titleView = [[[UIImageView alloc] initWithImage:flyingWVTwitter] autorelease];
		UIBarButtonItem *aBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Twitter" style:UIBarButtonItemStyleBordered target:nil action:nil];
		twitterUsers.navigationItem.backBarButtonItem = aBackButton;
		[aBackButton release];
		viewController = twitterUsers;
	}
	else if([@"Calendar" isEqualToString:feature]){
		CalendarSourcesViewController *viewController = [[CalendarSourcesViewController alloc] initWithStyle:UITableViewStyleGrouped];
		viewController.navigationItem.title = @"Calendar Sources";
		UIBarButtonItem *aBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Sources" style:UIBarButtonItemStyleBordered target:nil action:nil];
		viewController.navigationItem.backBarButtonItem = aBackButton;
		[aBackButton release];
	}
	else if([@"WVU.edu" isEqualToString:feature]){
		OPENURL(@"http://www.wvu.edu/?nomobi=true")
	}
	else if([@"WVU Today" isEqualToString:feature]){
		OPENURL(@"http://wvutoday.wvu.edu")
		//
	}
	else if([@"WVU Alert" isEqualToString:feature]){
		OPENURL(@"http://alert.wvu.edu")
	}
	else if([@"MIX" isEqualToString:feature]){
		OPENURL(@"http://mix.wvu.edu/")
	}
	else if([@"eCampus" isEqualToString:feature]){
		OPENURL(@"http://ecampus.wvu.edu/")
	}
	else if([@"Weather" isEqualToString:feature]){
		OPENURL(@"http://i.wund.com/cgi-bin/findweather/getForecast?brand=iphone&query=morgantown%2C+wv#conditions")
	}
	
	
	
	

	if (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)||(viewController.view.tag == iPAD_COMPATIBLE)) {
		[self.navigationController pushViewController:viewController animated:YES];
	}
	else {
		viewController.modalPresentationStyle = UIModalPresentationPageSheet;
		viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		viewController.contentSizeForViewInPopover = CGSizeMake(320, 460);
		[self presentModalViewController:viewController animated:YES];
	}

	[viewController release];	
	
	
}

- (void)launcherViewDidBeginEditing:(TTLauncherView*)launcher {
	doneEditingBar = [[DoneEditingBar createBar] retain];
	doneEditingBar.delegate = self;
	[self.view addSubview:doneEditingBar];
	doneEditingBar.frame = tickerBar.frame;
	doneEditingBar.hidden = YES;
	
	[tickerBar slideOutTo:kFTAnimationBottom duration:BAR_SLIDE_INOUT_DURATION delegate:self startSelector:nil stopSelector:@selector(displayDoneEditingBar)];
	
	
	
}

- (void) launcherView:(TTLauncherView  *)launcher didMoveItem:(TTLauncherItem *)item{
	[self saveHomeScreenPosition:launcherView.pages];
}

- (void)launcherViewDidEndEditing:(TTLauncherView*)launcher {
	[self saveHomeScreenPosition:launcherView.pages];
}

-(void)displayDoneEditingBar{
	doneEditingBar.hidden = NO;
	[doneEditingBar slideInFrom:kFTAnimationBottom duration:BAR_SLIDE_INOUT_DURATION delegate:nil];
}

-(void)doneEditingBarHasFinished:(DoneEditingBar *)bar{
	[launcherView endEditing];
	[doneEditingBar slideOutTo:kFTAnimationBottom duration:BAR_SLIDE_INOUT_DURATION delegate:self startSelector:nil stopSelector:@selector(displayTickerBar)];
}

-(void)displayTickerBar{
	[tickerBar slideInFrom:kFTAnimationBottom duration:BAR_SLIDE_INOUT_DURATION delegate:nil];
	[doneEditingBar release];
	doneEditingBar = nil;
}


-(void)tickerBar:(TickerBar *)ticker itemSelected:(NSString *)aURL{
	OPENURL(aURL);
}




- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
