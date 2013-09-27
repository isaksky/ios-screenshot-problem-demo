//
//  ScreenShotProblemViewController.m
//  ScreenshotProblemDemo
//
//  Created by Isak Sky on 7/5/13.
//  Copyright (c) 2013 YouEye. All rights reserved.
//

#import "ScreenShotProblemViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ScreenShotProblemViewController (){
    int _numScreenShots;
    UIWebView *_webview;
}

@end

@implementation ScreenShotProblemViewController{
}

- (void)loadView{
    [super loadView];
    
    _webview = [[UIWebView alloc] initWithFrame:CGRectZero];
    _webview.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_webview];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_webview]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webview)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webview]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webview)]];
    [_webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.imdb.com"]]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        [self tick];
    });
}

- (void) tick{
    [self takeScreenShot];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self tick];
    });
}

-(void) takeScreenShot{
    CALayer* copy = self.view.layer;
    UIGraphicsBeginImageContextWithOptions( self.view.bounds.size, YES, self.view.layer.contentsScale );
    CGContextRef context = UIGraphicsGetCurrentContext();
    [copy renderInContext:context];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _numScreenShots += 1;
    printf("ss_%d ", _numScreenShots);
}

@end
