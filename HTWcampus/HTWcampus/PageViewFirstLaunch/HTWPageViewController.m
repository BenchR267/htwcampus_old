//
//  ViewController.m
//  PageViewDemo
//
//  Created by Simon on 24/11/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "HTWPageViewController.h"
#import "HTWAppDelegate.h"

@interface HTWPageViewController ()
@property (weak, nonatomic) IBOutlet UIButton *skipButton;

@end

@implementation HTWPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Create the data model
    _pageTitles = @[@"Erstes Einrichten", @"Der Stundenplan", @"Einstellungen zum Stundenplan", @"Stunden verwalten", @"Schnelle Details anzeigen", @"Stunden bearbeiten"];
    _pageImages = @[@"page1.png", @"page2.png", @"page3.png", @"page4.png", @"page5.png", @"page6.png"];
    
    // Create page view controller
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    self.pageViewController.dataSource = self;
    
    HTWPageContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 30);
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];

}

- (IBAction)skip:(id)sender {
    HTWAppDelegate *appD = [[UIApplication sharedApplication] delegate];
    UITabBarController *tbc = [self.storyboard instantiateViewControllerWithIdentifier:@"tabBarController"];
    [UIView transitionWithView:appD.window
                      duration:0.5
                       options:UIViewAnimationOptionTransitionFlipFromTop
                    animations:^{
                    
                        [appD.window setRootViewController:tbc];
                    
                    }
                    completion:nil];
}

- (HTWPageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    HTWPageContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"HTWPageContentViewController"];
    pageContentViewController.imageFile = self.pageImages[index];
    pageContentViewController.titleText = self.pageTitles[index];
    pageContentViewController.pageIndex = index;
    
    
    
    return pageContentViewController;
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((HTWPageContentViewController*) viewController).pageIndex;
    if(index == self.pageTitles.count - 1) [self.skipButton setTitle:@"Fertig" forState:UIControlStateNormal];
    else [self.skipButton setTitle:@"Überspringen" forState:UIControlStateNormal];
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((HTWPageContentViewController*) viewController).pageIndex;
    if(index == self.pageTitles.count - 1) [self.skipButton setTitle:@"Fertig" forState:UIControlStateNormal];
    else [self.skipButton setTitle:@"Überspringen" forState:UIControlStateNormal];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pageTitles count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.pageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

@end
