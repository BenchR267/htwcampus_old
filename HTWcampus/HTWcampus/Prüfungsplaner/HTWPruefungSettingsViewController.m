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

    UINavigationController *vcA = [self.storyboard instantiateViewControllerWithIdentifier:@"studienGruppeEingeben"];
    UINavigationController *vcB = [self.storyboard instantiateViewControllerWithIdentifier:@"dozentEingeben"];

    self.allViewControllers = [[NSArray alloc] initWithObjects:vcA, vcB, nil];

    self.switchViewControllers.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"pruefungsPlanTyp"];
    [self cycleFromViewController:self.currentViewController toViewController:[self.allViewControllers objectAtIndex:self.switchViewControllers.selectedSegmentIndex]];
}

#pragma mark - View controller switching and saving

- (void)cycleFromViewController:(UIViewController*)oldVC toViewController:(UIViewController*)newVC {

    if (newVC == oldVC) return;

    if (newVC)
    {
        newVC.view.frame = CGRectMake(CGRectGetMinX(self.view.bounds), CGRectGetMinY(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        if (oldVC)
        {
            [oldVC willMoveToParentViewController:nil];
            [self addChildViewController:newVC];
            [self transitionFromViewController:oldVC
                              toViewController:newVC
                                      duration:0.25
                                       options:UIViewAnimationOptionLayoutSubviews
                                    animations:^{}
                                    completion:^(BOOL finished) {

                                        [oldVC removeFromParentViewController];
                                        [newVC didMoveToParentViewController:self];
                                        self.currentViewController = newVC;

                                    }];

        }
        else
        {

            [self addChildViewController:newVC];
            [self.view addSubview:newVC.view];
            [newVC didMoveToParentViewController:self];
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
            if ([[(HTWNeueStudiengruppe*)[_allViewControllers[0] viewControllers][0] jahrTextField].text isEqualToString:@""]) {
                [[NSUserDefaults standardUserDefaults] setObject:@"12" forKey:@"pruefungJahr"];
            }
            [[NSUserDefaults standardUserDefaults] setObject:[(HTWNeueStudiengruppe*)[_allViewControllers[0] viewControllers][0] gruppeTextField].text forKey:@"pruefungGruppe"];
            if ([[(HTWNeueStudiengruppe*)[_allViewControllers[0] viewControllers][0] gruppeTextField].text isEqualToString:@""]) {
                [[NSUserDefaults standardUserDefaults] setObject:@"041" forKey:@"pruefungGruppe"];
            }
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
