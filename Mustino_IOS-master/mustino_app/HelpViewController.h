//
//  HelpViewController.h
//
//
//
//  Created by Kaviraj Murugesan on 10/05/14.
//  Copyright (c) 2014 Morning Zoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController

@property (strong, nonatomic) NSString *helpText;

@property (weak, nonatomic) IBOutlet UITextView *helpTextView;
@end
