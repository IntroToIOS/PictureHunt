//
//  FirstViewController.m
//  Pictures
//
//  Created by Charlie Jacobson on 2/26/16.
//  Copyright © 2016 IntroToiOS. All rights reserved.
//

#import "FirstViewController.h"
#import "ClarifaiClient.h"

static NSString * const kClientId = @"_vRYR7vlXhxDpZlYL0aBm2i1ho7ZZczFW46gWL5h";
static NSString * const kClientSecret = @"WtaYtFb3ZQ83PL7htg6mOUEbgspE8Ycg4PeUboaq";
static NSString * const kAccessToken = @"V1wdXOrv9fIx1z0nnIaIbQDEX15FyV";

@interface FirstViewController ()

@property (nonatomic, strong)  ClarifaiClient *client;

@property (nonatomic, strong) UILabel *resultsLabel;

@property (nonatomic, strong) UILabel *gameLabel;

@end

@implementation FirstViewController


- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	// Create Camera View Controller
	UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
	imagePickerController.editing = YES;
	imagePickerController.delegate = self;
	
	// Change frame of camera to account for status bar and tab bar
	CGFloat statusBarHeight = 20;
	CGFloat tabBarHeight = 44;
	CGFloat cameraHeight = self.view.frame.size.height - statusBarHeight - tabBarHeight;
	imagePickerController.view.frame = CGRectMake(0, statusBarHeight, self.view.frame.size.width, cameraHeight);
	
	// Add Camera to FirstViewController
	[imagePickerController willMoveToParentViewController:self];
	[self.view addSubview:imagePickerController.view];
	[self addChildViewController:imagePickerController];
	[imagePickerController didMoveToParentViewController:self];
	
	// Create game label
	self.gameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, statusBarHeight, self.view.frame.size.width, 40)];
	self.gameLabel.textAlignment = NSTextAlignmentCenter;
	self.gameLabel.backgroundColor = [UIColor whiteColor];
	self.gameLabel.text = @"Tap for new game";
	[self.view addSubview:self.gameLabel];
	
	// Add tap action to game label
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapGameLabel:)];
	[self.gameLabel addGestureRecognizer:tapGesture];
	self.gameLabel.userInteractionEnabled = YES;
}

/** Method called when a user taps the game label. */
-(void) didTapGameLabel: (UILabel *) gameLabel
{
	// all possible game choices
	NSMutableArray *gameChoices = [NSMutableArray arrayWithArray: @[@"coffee", @"banana", @"iPhone", @"phone", @"blackboard", @"projector", @"glasses", @"notebook", @"running", @"person"]];

	// number of items to include in game
	int gameSize = 1;
	
	// compile list of items for game
	NSMutableArray *gameItems = [[NSMutableArray alloc] init];
	for (int i = 0; i < gameSize; i++) {
		// random item from game choices
		NSUInteger randomIndex = rand()*[gameChoices count]/RAND_MAX;
		NSString *randomItem = [gameChoices objectAtIndex:randomIndex];
		[gameChoices removeObjectAtIndex:randomIndex];
		[gameItems addObject:randomItem];
	}
	
	// update game label to show new game items
	NSString *gameDescription = [gameItems componentsJoinedByString:@" "];
	self.gameLabel.text = gameDescription;
	self.gameLabel.backgroundColor = [UIColor whiteColor];
	
	self.resultsLabel.hidden = YES;
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSLog(@"Picture taken!");
	
	// Get image from camera
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	
	// Create text label to show results
	CGFloat tabBarHeight = 44;
	CGFloat labelHeight = 100;
	self.resultsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - tabBarHeight - labelHeight, self.view.frame.size.width, labelHeight)];
	self.resultsLabel.backgroundColor = [UIColor whiteColor];
	self.resultsLabel.textAlignment = NSTextAlignmentCenter;
	self.resultsLabel.text = @"Loading...";
	self.resultsLabel.numberOfLines = 0;
	[self.view addSubview:self.resultsLabel];
	
	// Run image recognition
	[self recognizeImage:image];
	
	[picker takePicture];

}

/** Runs image recognition with the ClarifaiClient. */
- (void)recognizeImage:(UIImage *)image {
	
	// Scale down the image. This step is optional. However, sending large images over the
	CGSize size = CGSizeMake(320, 320 * image.size.height / image.size.width);
	UIGraphicsBeginImageContext(size);
	[image drawInRect:CGRectMake(0, 0, size.width, size.height)];
	UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	// Encode as a JPEG.
	NSData *jpeg = UIImageJPEGRepresentation(scaledImage, 0.9);
	
	// Send the JPEG to Clarifai for standard image tagging.
	[self.client recognizeJpegs:@[jpeg] completion:^(NSArray *results, NSError *error) {
		
		// Handle the response from Clarifai. This happens asynchronously.
		if (error) {
			
			NSLog(@"Error: %@", error);
			self.resultsLabel.text = @"Sorry, there was an error recognizing the image.";
			
		} else {
			
			// Update the results label with the results from Clarifai
			ClarifaiResult *result = results.firstObject;
			self.resultsLabel.text = [NSString stringWithFormat:@"Tags: %@", [result.tags componentsJoinedByString:@", "]];
			
			// Check game results
			BOOL didWinGame = YES;
			NSArray *gameItems = [self.gameLabel.text componentsSeparatedByString:@" "];
			for (NSString *gameItem in gameItems) {
				didWinGame = didWinGame && [result.tags containsObject:gameItem];
			}
			
			// Update game label
			if (didWinGame) {
				self.gameLabel.backgroundColor = [UIColor greenColor];
			}
			else {
				self.gameLabel.backgroundColor = [UIColor redColor];
			}
		}
		
	}];
	
}

/** Provides a ClarifaiClient to use. */
- (ClarifaiClient *)client {
	if (!_client) {
		_client = [[ClarifaiClient alloc] initWithAppID:kClientId appSecret:kClientSecret];
	}
	return _client;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end
