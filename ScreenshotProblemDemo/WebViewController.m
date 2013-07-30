//
//  WebViewController.m
//  mob-web-harness
//
//  Created by Isak Sky on 6/12/13.
//  Copyright (c) 2013 Isak Sky. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "WebViewController.h"
#import "Util.h"

const float WEB_VIEW_TASK_BAR_HEIGHT = 44.f;
const float WEB_VIEW_CONTROL_BAR_HEIGHT = 44.f;

@interface WebViewController () <UIWebViewDelegate> {
    unsigned long _taskIdx;
    UILabel *_task_title_lbl;
    NSTimer *_screenShotTimer;
    int _numScreenShots;

    // GCD
    dispatch_source_t _timer_source;
    dispatch_queue_t _queue;
}

@property(nonatomic, strong) UIWebView *webView;
@property(nonatomic, strong) UIToolbar *taskBar;
@property(nonatomic, strong) UIToolbar *bottomToolbar;

@property(nonatomic, strong, readonly) UIBarButtonItem *taskInfoBtn;
@property(nonatomic, strong, readonly) UIBarButtonItem *taskForwardBtn;
@property(nonatomic, strong, readonly) UIBarButtonItem *taskTitleItem;

@property(nonatomic, strong, readonly) UIBarButtonItem *browserBackBtn;
@property(nonatomic, strong, readonly) UIBarButtonItem *browserForwardBtn;
@property(nonatomic, strong, readonly) UIBarButtonItem *browserRefreshBtn;
@property(nonatomic, strong, readonly) UIBarButtonItem *browserStopBtn;

@end

@implementation WebViewController

@synthesize taskInfoBtn, taskForwardBtn, taskTitleItem;
@synthesize browserBackBtn, browserForwardBtn, browserRefreshBtn, browserStopBtn;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)loadView {
    [super loadView];

    CGRect app_frame = [UIScreen mainScreen].applicationFrame;

    CGRect task_bar_frame = CGRectMake(0, 0, app_frame.size.width, WEB_VIEW_TASK_BAR_HEIGHT);
    self.taskBar = [[UIToolbar alloc] initWithFrame:task_bar_frame];
    [self update_task_bar_items];
    self.bottomToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.bottomToolbar.autoresizesSubviews = YES;
    [self.view addSubview:self.taskBar];

    CGRect web_view_bounds = CGRectMake(0, WEB_VIEW_TASK_BAR_HEIGHT,
            app_frame.size.width,
            app_frame.size.height - WEB_VIEW_TASK_BAR_HEIGHT - WEB_VIEW_CONTROL_BAR_HEIGHT);

    CGRect bottom_menu_frame = CGRectMake(0, web_view_bounds.origin.y + web_view_bounds.size.height,
            app_frame.size.width, WEB_VIEW_CONTROL_BAR_HEIGHT);
    self.bottomToolbar = [UIToolbar.alloc initWithFrame:bottom_menu_frame];
    [self update_browser_bar_items];
    self.bottomToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.bottomToolbar.autoresizesSubviews = YES;
    [self.view addSubview:self.bottomToolbar];

    self.webView = [[UIWebView alloc] initWithFrame:web_view_bounds];
    self.webView.scalesPageToFit = YES;
    self.webView.multipleTouchEnabled = YES;

    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.imdb.com"]]];
    [self.view addSubview:self.webView];
    [self show_task_body];


    _queue = dispatch_queue_create("com.youeye.ios.recorders.screen", NULL); // will be a serial queue
    //dispatch_set_target_queue(_queue, dispatch_get_main_queue());
    dispatch_set_target_queue(_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));

    _timer_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    //dispatch_source_t timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

    dispatch_source_set_timer(
            _timer_source,
            dispatch_walltime(NULL, 0),
            100ull * NSEC_PER_MSEC,
            20ull * NSEC_PER_MSEC // leeway
    );

    __block typeof (self) weak_self = self; // using this ref to avoid retain cycle in block below
    dispatch_source_set_event_handler(_timer_source, ^{
        [weak_self takeScreenShotAux:nil];
    });

    dispatch_resume(_timer_source);
//    _screenShotTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self
//                                                      selector:@selector(takeScreenShot)
//                                                      userInfo:nil repeats:YES];
}

- (void)takeScreenShot {
    [self performSelectorInBackground:@selector(takeScreenShotAux:) withObject:nil];

//    also tried this, but same error:
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//        [self takeScreenShotAux:nil];
//    });
}
-(void)takeScreenShotAux:(id)o{
    NSLog(@"In takeScreenShot");
    //CALayer* copy = [self.view.layer presentationLayer];
    CALayer *copy = self.view.layer;//[self.view.layer presentationLayer];
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, self.view.layer.contentsScale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [copy renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self saveScreenShot:image];

    _numScreenShots += 1;
    NSLog(@"_numScreenShots = %d", _numScreenShots);

    if (_numScreenShots >= 1000) {
        [_screenShotTimer invalidate];
        _screenShotTimer = nil;
    }
}

- (void)saveScreenShot:(UIImage *)screenShot {
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsPath = [paths objectAtIndex:0];
//    NSString *screenShotPath = [documentsPath stringByAppendingPathComponent:
//            [NSString stringWithFormat:@"screenShot%d.png", _numScreenShots]];
//
//    NSData *screenShotData = UIImagePNGRepresentation(screenShot);
//    [[NSFileManager defaultManager] removeItemAtPath:screenShotPath error:nil];
//    assert([screenShotData writeToFile:screenShotPath atomically:YES]);
}


#pragma mark Task controls

- (void)update_task_title_lbl {
    _task_title_lbl.text = @"Test task";
}

- (void)update_task_bar_items {
    UIBarButtonItem *next_or_finish_btn = self.taskForwardBtn; //TODO: Different icon when it is the last task.

    UIBarButtonItem *fixed_space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed_space.width = 5.0f;
    UIBarButtonItem *flex_space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    [self update_task_title_lbl];


    NSArray *items = @[
            fixed_space,
            self.taskInfoBtn,
            flex_space,
            self.taskTitleItem,
            flex_space,
            next_or_finish_btn
            , fixed_space
    ];
    //self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
    //self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
    self.taskBar.items = items;


}

- (UIBarButtonItem *)taskInfoBtn {
    if (!taskInfoBtn) {
        UIButton *info_button = [UIButton buttonWithType:UIButtonTypeInfoLight];
        [info_button addTarget:self action:@selector(task_info_clicked:) forControlEvents:UIControlEventTouchUpInside];
        //[UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystem target:<#(id)target#> action:<#(SEL)action#>]
//        task_info_btn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/iPhone/back"]
//                                                         style:UIBarButtonItemStylePlain
//                                                        target:self
//                                                        action:@selector(task_info_clicked:)];
        taskInfoBtn = [UIBarButtonItem .alloc initWithCustomView:info_button];
        // These don't work, gotta do the thing above
        // /task_info_btn.target = self;
        //task_info_btn.action = @selector(task_info_clicked:);
        taskInfoBtn.width = 18.0f;
    }
    return taskInfoBtn;
}

- (UIBarButtonItem *)taskTitleItem {
    if (!_task_title_lbl || !taskTitleItem) {
        _task_title_lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [self update_task_title_lbl];
//        _task_title_lbl.text = @"Task 1 / 5";
        _task_title_lbl.backgroundColor = [UIColor clearColor];
        _task_title_lbl.textColor = [UIColor whiteColor];

        [_task_title_lbl sizeToFit];
        taskTitleItem = [[UIBarButtonItem alloc] initWithCustomView:_task_title_lbl];
    }
    return taskTitleItem;
}

- (UIBarButtonItem *)taskForwardBtn {
    if (!taskForwardBtn) {
        taskForwardBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/iPhone/forward"]
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(task_forward_clicked:)];
        taskForwardBtn.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
        taskForwardBtn.width = 18.0f;
    }
    return taskForwardBtn;
}

#pragma mark - Task actions

- (void)show_task_body {
    NSString *title = @"Hello!";
    NSString *task_body = @"What do you think about this?";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:task_body
                                                       delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    [alertView setAlertViewStyle:UIAlertViewStyleDefault];
    [alertView show];
}

- (void)step_with_task_skipped:(BOOL)skipped {
}

- (void)task_forward_clicked:(UIBarButtonItem *)sender {
    [self step_with_task_skipped:NO];
    [self show_task_body];
}

- (void)task_info_clicked:(UIBarButtonItem *)sender {
    [self show_task_body];
}

#pragma mark Browser buttons

- (void)update_browser_bar_items {
    //UIBarButtonItem *refresh_or_stop_btn = self.web_view.isLoading ? self.browser_stop_btn : self.browser_refresh_btn;

    UIBarButtonItem *fixed_space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed_space.width = 5.0f;
    UIBarButtonItem *flex_space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    NSArray *items = @[
            flex_space,
            self.browserBackBtn,
            flex_space,
            self.browserForwardBtn,
            flex_space,
            self.browserRefreshBtn
            , flex_space
    ];
    //self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
    //self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
    self.bottomToolbar.items = items;

}

- (UIBarButtonItem *)browserBackBtn {

    if (!browserBackBtn) {
        browserBackBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(browser_back_clicked:)];
        browserBackBtn.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
        browserBackBtn.width = 18.0f;
    }
    return browserBackBtn;
}

- (UIBarButtonItem *)browserForwardBtn {

    if (!browserForwardBtn) {
        browserForwardBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"] style:UIBarButtonItemStylePlain target:self action:@selector(browser_forward_clicked:)];
        browserForwardBtn.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
        browserForwardBtn.width = 18.0f;
    }
    return browserForwardBtn;
}

- (UIBarButtonItem *)browserRefreshBtn {

    if (!browserRefreshBtn) {
        browserRefreshBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(browser_reload_clicked:)];
    }

    return browserRefreshBtn;
}

- (UIBarButtonItem *)browserStopBtn {

    if (!browserStopBtn) {
        browserStopBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(browser_stop_clicked:)];
    }
    return browserStopBtn;
}

#pragma mark - Browser actions

- (void)browser_back_clicked:(UIBarButtonItem *)sender {
    [self.webView goBack];
}

- (void)browser_forward_clicked:(UIBarButtonItem *)sender {
    [self.webView goForward];
}

- (void)browser_reload_clicked:(UIBarButtonItem *)sender {
    [self.webView reload];
}

- (void)browser_stop_clicked:(UIBarButtonItem *)sender {
    [self.webView stopLoading];
    [self update_browser_bar_items];
}

#pragma mark - weh

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];

    taskForwardBtn = nil;
    taskTitleItem = nil;
    _task_title_lbl = nil;
    taskInfoBtn = nil;

    browserBackBtn = nil;
    browserForwardBtn = nil;
    browserRefreshBtn = nil;
    browserStopBtn = nil;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Error"]) { //ghetto
        exit(0);
    }
}

- (void)dealloc {
    self.webView = nil;
    self.taskBar = nil;
    self.bottomToolbar = nil;
}

@end
