#import <UIKit/UIKit.h>
#import <UIKit/UIKit2.h>
#import <CaptainHook/CaptainHook.h>

CHDeclareClass(UIApplication)

__attribute__((visibility("hidden")))
@interface WebPreviewRotateableViewController : UIViewController {
}
@end

@implementation WebPreviewRotateableViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end

__attribute__((visibility("hidden")))
@interface WebPreviewViewController : WebPreviewRotateableViewController<UIWebViewDelegate> {
@private
	UIWindow *formerKeyWindow;
	UIWindow *window;
	UIWebView *webView;
	UIViewController *wrapper;
	UINavigationController *navigationController;
}
- (id)initWithURL:(NSURL *)url;
- (void)show;
- (void)dismiss;
@end

static WebPreviewViewController *current;

@implementation WebPreviewViewController

- (id)initWithURL:(NSURL *)url
{
	if ((self = [super init])) {
		UINavigationItem *item = self.navigationItem;
		item.title = @"Loading…";
		item.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
		item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Open in Safari" style:UIBarButtonItemStylePlain target:self action:@selector(loadInSafari)];
		webView = [[UIWebView alloc] initWithFrame:(CGRect){ { 0.0f, 0.0f }, { 0.0f, 0.0f } }];
		webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		webView.delegate = self;
		[webView loadRequest:[NSURLRequest requestWithURL:url]];
	}
	return self;
}

- (void)dealloc
{
	webView.delegate = nil;
	[webView release];
	[super dealloc];
}

- (void)viewDidLoad
{
	UIView *view = self.view;
	CGRect frame = view.bounds;
	webView.frame = frame;
	[view addSubview:webView];
}

- (void)show
{
	if (window)
		return;
	window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	wrapper = [[UIViewController alloc] init];
	[window addSubview:wrapper.view];
	navigationController = [[UINavigationController alloc] initWithRootViewController:self];
	formerKeyWindow = [[UIWindow keyWindow] retain];
	[window makeKeyAndVisible];
	[wrapper presentModalViewController:navigationController animated:YES];
	current = [self retain];
}

- (void)finishDismiss
{
	[formerKeyWindow makeKeyWindow];
	[formerKeyWindow release];
	formerKeyWindow = nil;
	[webView removeFromSuperview];
	window.hidden = YES;
	[window release];
	window = nil;
	if (current == self)
		current = nil;
	[self autorelease];
}

- (void)dismiss
{
	if (wrapper) {
		[wrapper dismissModalViewControllerAnimated:YES];
		[wrapper release];
		wrapper = nil;
		[self performSelector:@selector(finishDismiss) withObject:nil afterDelay:1.0];
	}
}

- (void)loadInSafari
{
	[self dismiss];
	[[UIApplication sharedApplication] openURL:webView.request.URL];
}

- (void)webViewDidFinishLoad:(UIWebView *)w
{
	NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
	if ([title length] == 0) {
		title = [webView.request.URL absoluteString];
	}
	self.navigationItem.title = title;
}

@end

CHOptimizedMethod(1, self, BOOL, UIApplication, openURL, NSURL *, url)
{
	if (current)
		[current dismiss];
	else {
		NSString *scheme = [url scheme];
		if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
			WebPreviewViewController *vc = [[WebPreviewViewController alloc] initWithURL:url];
			[vc show];
			[vc release];
			return YES;
		}
	}
	return CHSuper(1, UIApplication, openURL, url);
}

CHConstructor {
	CHLoadLateClass(UIApplication);
	CHHook(1, UIApplication, openURL);
}