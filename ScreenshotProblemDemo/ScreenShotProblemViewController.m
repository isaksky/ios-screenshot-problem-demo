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
    NSTimer *_screenShotTimer;
    int _numScreenShots;
}

@end

@implementation ScreenShotProblemViewController{
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.textField becomeFirstResponder];

//    _screenShotTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self
//                                                      selector:@selector(takeScreenShot)
//                                                      userInfo:nil repeats:YES];
    UIWebView *webview = [[UIWebView alloc] initWithFrame:CGRectMake(50, 50, 300, 400)];
    [self.view addSubview:webview];
    [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.imdb.com"]]];
    
    
    [UIView animateWithDuration:10 animations:^{
        self.box.frame = [[UIScreen mainScreen] applicationFrame];
    }];
    
    [self tick];
}

- (void) tick{
    [self takeScreenShot];
    
    if (_numScreenShots < 20){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self tick];
        });
    }
}

-(void) takeScreenShot{
    NSLog(@"In takeScreenShot");
    CALayer* copy = [self.view.layer presentationLayer];
    UIGraphicsBeginImageContextWithOptions( self.view.bounds.size, YES, self.view.layer.contentsScale );
    CGContextRef context = UIGraphicsGetCurrentContext();
    [copy renderInContext:context];
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self saveScreenShot:image];
    
    _numScreenShots += 1;
    NSLog(@"_numScreenShots = %d", _numScreenShots);
    
    if (_numScreenShots >= 10) {
        [_screenShotTimer invalidate];
        _screenShotTimer = nil;
    }
}

-(void)saveScreenShot:(UIImage *)screenShot {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *screenShotPath = [documentsPath stringByAppendingPathComponent:
                                [NSString stringWithFormat:@"screenShot%d.png", _numScreenShots]];
    
    NSData *screenShotData = UIImagePNGRepresentation(screenShot);
    [[NSFileManager defaultManager] removeItemAtPath:screenShotPath error:nil];
    assert([screenShotData writeToFile:screenShotPath atomically:YES]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
