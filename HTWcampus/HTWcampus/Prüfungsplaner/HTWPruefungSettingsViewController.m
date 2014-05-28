//
//  HTWPruefungSettingsViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 28.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWPruefungSettingsViewController.h"
#import "HTWNeueStudiengruppe.h"
#import "HTWDozentEingebenTableViewController.h"

@interface HTWPruefungSettingsViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *switchViewControllers;

@property (nonatomic, copy) NSArray *allViewControllers;

@property (nonatomic, strong) UIViewController *currentViewController;

@end

@implementation HTWPruefungSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create the score view controller
    UINavigationController *vcA = [self.storyboard instantiateViewControllerWithIdentifier:@"studienGruppeEingeben"];

    // Create the penalty view controller
    UINavigationController *vcB = [self.storyboard instantiateViewControllerWithIdentifier:@"dozentEingeben"];

    // Add A and B view controllers to the array
    self.allViewControllers = [[NSArray alloc] initWithObjects:vcA, vcB, nil];

    // Ensure a view controller is loaded
    self.switchViewControllers.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"pruefungsPlanTyp"];
    [self cycleFromViewController:self.currentViewController toViewController:[self.allViewControllers objectAtIndex:self.switchViewControllers.selectedSegmentIndex]];
}

#pragma mark - View controller switching and saving

- (void)cycleFromViewController:(UIViewController*)oldVC toViewController:(UIViewController*)newVC {

    // Do nothing if we are attempting to swap to the same view controller
    if (newVC == oldVC) return;

    // Check the newVC is non-nil otherwise expect a crash: NSInvalidArgumentException
    if (newVC) {

        // Set the new view controller frame (in this case to be the size of the available screen bounds)
        // Calulate any other frame animations here (e.g. for the oldVC)
        newVC.view.frame = CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMinY(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));

        // Check the oldVC is non-nil otherwise expect a crash: NSInvalidArgumentException
        if (oldVC) {

            // Start both the view controller transitions
            [oldVC willMoveToParentViewController:nil];
            [self addChildViewController:newVC];

            // Swap the view controllers
            // No frame animations in this code but these would go in the animations block
            [self transitionFromViewController:oldVC
                              toViewController:newVC
                                      duration:0.25
                                       options:UIViewAnimationOptionLayoutSubviews
                                    animations:^{}
                                    completion:^(BOOL finished) {
                                        // Finish both the view controller transitions
                                        [oldVC removeFromParentViewController];
                                        [newVC didMoveToParentViewController:self];
                                        // Store a reference to the current controller
                                        self.currentViewController = newVC;
                                    }];

        } else {

            // Otherwise we are adding a view controller for the first time
            // Start the view controller transition
            [self addChildViewController:newVC];

            // Add the new view controller view to the ciew hierarchy
            [self.view addSubview:newVC.view];

            // End the view controller transition
            [newVC didMoveToParentViewController:self];

            // Store a reference to the current controller
            self.currentViewController = newVC;
        }
    }
}

- (IBAction)indexDidChangeForSegmentedControl:(UISegmentedControl *)sender {

    NSUInteger index = sender.selectedSegmentIndex;

    if (UISegmentedControlNoSegment != index) {
        UIViewController *incomingViewController = [self.allViewControllers objectAtIndex:index];
        [self cycleFromViewController:self.currentViewController toViewController:incomingViewController];
    }
    
}
- (IBAction)fertigPressed:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:_switchViewControllers.selectedSegmentIndex forKey:@"pruefungsPlanTyp"];
    switch (_switchViewControllers.selectedSegmentIndex) {
        case 0: // Studiengruppe
            [[NSUserDefaults standardUserDefaults] setObject:[(HTWNeueStudiengruppe*)[_allViewControllers[0] viewControllers][0] jahrTextField].text forKey:@"pruefungJahr"];
            [[NSUserDefaults standardUserDefaults] setObject:[(HTWNeueStudiengruppe*)[_allViewControllers[0] viewControllers][0] gruppeTextField].text forKey:@"pruefungGruppe"];
            break;
        case 1: // Prüfender
            [[NSUserDefaults standardUserDefaults] setObject:[(HTWDozentEingebenTableViewController*)[_allViewControllers[1] viewControllers][0] dozentTextField].text forKey:@"pruefungDozent"];
            break;

        default:
            break;
    }
    if(_delegate) [_delegate HTWPruefungsSettingsDone];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
