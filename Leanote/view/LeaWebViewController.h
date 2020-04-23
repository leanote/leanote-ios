#import <UIKit/UIKit.h>
@import WebKit;

@interface LeaWebViewController : UIViewController<WKNavigationDelegate>

// Interface
@property (nonatomic,   weak) IBOutlet WKWebView *webView;
//@property (nonatomic,   weak) IBOutlet WKWebView *wkView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIView *loadingView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UILabel *loadingLabel;
@property (nonatomic, strong) IBOutlet UINavigationBar *iPadNavBar;


@property (nonatomic, strong) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *refreshButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *optionsButton;


@property (nonatomic, strong) UIBarButtonItem *spinnerButton;
@property (nonatomic, strong) NSTimer *statusTimer;
@property (nonatomic, assign) BOOL hidesLinkOptions;

// Endpoint!
@property (nonatomic, strong) NSURL *url;

// Authentication
@property (nonatomic, assign) BOOL needsLogin;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *pwd;
@property (nonatomic, strong) NSString *token;

// Reader variables
@property (nonatomic, strong) NSString *detailContent;
@property (nonatomic, strong) NSString *detailHTML;
@property (nonatomic, strong) NSString *readerAllItems;
@property (nonatomic, assign) BOOL shouldScrollToBottom;

// actions
- (IBAction)showLinkOptions;
- (IBAction)goForward;
- (IBAction)goBack;
- (IBAction)reload;

- (IBAction)dismiss;

//- (void) loginLeanote:(NSString *) host email:(NSString *) email pwd:(NSString *) pwd;

@end
