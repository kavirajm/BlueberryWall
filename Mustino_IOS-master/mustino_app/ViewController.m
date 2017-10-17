//
//  ViewController.m
//
//
//
//  Created by Kaviraj Murugesan on 10/05/14.
//  Copyright (c) 2014 Morning Zoo. All rights reserved.
//


#import "ViewController.h"
#import "Constants.h"
#import "HelpViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize backgroundImage;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Adjust the background to fill the phone space
    if (is4InchesIPhone)
    {
        // 4 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background4.png"];
        [backgroundImage setImage:image];
    }
    else
    {
        // 3.5 inches iPhone
        UIImage *image = [UIImage imageNamed:@"Background35.png"];
        [backgroundImage setImage:image];
    }
    [self performSegueWithIdentifier:@"musitnoview" sender:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"prepareForSegue");
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if ([[segue identifier] isEqualToString:@"help"]) {
        NSLog(@"correct segue");
        HelpViewController *helpVC = [segue destinationViewController];
        helpVC.helpText = [NSString stringWithFormat:@"Add new apps %@",version];
    }
}

@end
