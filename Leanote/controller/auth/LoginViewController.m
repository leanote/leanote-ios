//
//  LoginViewController.m
//  Leanote
//
//  Created by life
//

#import "LoginViewController.h"
#import "WPNUXHelpBadgeLabel.h"
#import "WPWalkthroughTextField.h"
#import "WPNUXMainButton.h"
#import "WPNUXSecondaryButton.h"
#import "RegisterController.h"
#import "WPWalkthroughOverlayView.h"

#import <WordPress-iOS-Shared/WordPressShared/WPFontManager.h>
#import <WordPress-iOS-Shared/WordPressShared/UIColor+Helpers.h>
#import <WordPress-iOS-Shared/WordPressShared/WPNUXUtility.h>
#import <WordPress-iOS-Shared/WordPressShared/WPStyleGuide.h>

#import "ReachabilityUtils.h"
#import "LeaAlert.h"

#import "UserService.h"

// 一些常量 与UI相关

static CGFloat const GeneralWalkthroughStandardOffset           = 15.0;
static CGFloat const GeneralWalkthroughMaxTextWidth             = 290.0;
static CGSize const GeneralWalkthroughTextFieldSize             = {320.0, 44.0};
static CGFloat const GeneralWalkthroughTextFieldOverlapY        = 1.0;
static CGSize const GeneralWalkthroughButtonSize                = {290.0, 41.0};
static CGFloat const GeneralWalkthroughSecondaryButtonHeight    = 33.0;
static CGFloat const GeneralWalkthroughStatusBarOffset          = 20.0;

static NSTimeInterval const GeneralWalkthroughAnimationDuration = 0.3f;
static CGFloat const GeneralWalkthroughAlphaHidden              = 0.0f;
static CGFloat const GeneralWalkthroughAlphaDisabled            = 0.5f;
static CGFloat const GeneralWalkthroughAlphaEnabled             = 1.0f;

static CGPoint const LoginOnePasswordPadding                    = {9.0, 0.0f};
static NSInteger const LoginVerificationCodeNumberOfLines       = 2;


@interface LoginViewController ()<UITextFieldDelegate>

@property (nonatomic, assign) BOOL isFromAddAccount;
@property (nonatomic, assign) BOOL noAnyUser;

// views
@property (nonatomic, strong) UIView                    *mainView;
@property (nonatomic, strong) UITapGestureRecognizer    *tapGestureRecognizer;
@property (nonatomic, strong) WPNUXSecondaryButton      *skipToCreateAccount;
@property (nonatomic, strong) WPNUXSecondaryButton      *toggleSelfHost;
@property (nonatomic, strong) WPNUXSecondaryButton      *forgotPassword;
@property (nonatomic, strong) UIButton                  *helpButton;
@property (nonatomic, strong) WPNUXHelpBadgeLabel       *helpBadge;
@property (nonatomic, strong) UIImageView               *icon;
@property (nonatomic, strong) WPWalkthroughTextField    *usernameText;
@property (nonatomic, strong) WPWalkthroughTextField    *passwordText;
@property (nonatomic, strong) UIButton                  *onePasswordButton;
@property (nonatomic, strong) WPWalkthroughTextField    *multifactorText;
@property (nonatomic, strong) WPWalkthroughTextField    *siteUrlText;
@property (nonatomic, strong) WPNUXMainButton           *signInButton;
@property (nonatomic, strong) WPNUXSecondaryButton      *sendVerificationCodeButton;
@property (nonatomic, strong) WPNUXSecondaryButton      *cancelButton;
@property (nonatomic, strong) UILabel                   *statusLabel;


// Measurements
@property (nonatomic, assign) CGFloat                   keyboardOffset;
@property (nonatomic, assign) BOOL                      userIsDotCom;
@property (nonatomic, assign) BOOL                      hasDefaultAccount;
@property (nonatomic, assign) BOOL                      shouldDisplayMultifactor;
@property (nonatomic, assign) BOOL                      authenticating;

@property (nonatomic, strong) void (^loginOkCb)();

@end

@implementation LoginViewController

// 从添加帐户按钮中跳到该界面
-(void)fromAddAccount:(BOOL)ok noAnyUser:(BOOL)noAnyUser loginOkCb:(void (^)())loginOkCb
{
	self.isFromAddAccount = ok;
	self.noAnyUser = noAnyUser;
	self.loginOkCb = loginOkCb;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.userIsDotCom = YES;
	self.view.backgroundColor = [WPStyleGuide wordPressBlue];
	
	[self addMainView];
	[self addControls];
	[self reloadInterface];
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	//	[nc addObserver:self selector:@selector(helpshiftUnreadCountUpdated:) name:HelpshiftUnreadCountUpdatedNotification object:nil];
	[nc addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
	
	// reload
//	[self reloadInterface];
	
	return;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark LoginView

- (void)addMainView
{
	NSAssert(self.view, @"The view should be loaded by now");
	
	UIView *mainView = [[UIView alloc] initWithFrame:self.view.bounds];
	mainView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	// 手势
	/*
	 UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapGestureAction:)];
	 gestureRecognizer.numberOfTapsRequired = 1;
	 gestureRecognizer.cancelsTouchesInView = YES;
	 [mainView addGestureRecognizer:gestureRecognizer];
	 self.tapGestureRecognizer = gestureRecognizer;
	 */
	
	// Attach + Keep the Reference
	[self.view addSubview:mainView];
	self.mainView = mainView;
	
}

// 都是用代码来实现的啊
- (void)addControls
{
	NSAssert(self.view, @"The view should be loaded by now");
	NSAssert(self.mainView, @"Please, initialize the mainView first");
	
	// Add Icon
	UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"leanote-icon-circle"]]; // icon-wp
	icon.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	
	// Add Info button
	UIImage *infoButtonImage = [UIImage imageNamed:@"btn-help"];
	UIButton *helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
	helpButton.accessibilityLabel = NSLocalizedString(@"Help", @"Help button");
	[helpButton setImage:infoButtonImage forState:UIControlStateNormal];
	helpButton.frame = CGRectMake(GeneralWalkthroughStandardOffset, GeneralWalkthroughStandardOffset, infoButtonImage.size.width, infoButtonImage.size.height);
	helpButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	[helpButton addTarget:self action:@selector(helpButtonAction:) forControlEvents:UIControlEventTouchUpInside];
	[helpButton sizeToFit];
	[helpButton setExclusiveTouch:YES];
	// 帮助按钮隐藏
	helpButton.hidden = YES;
	
	// Help badge, 小圆点(未读消息)
	WPNUXHelpBadgeLabel *helpBadge = [[WPNUXHelpBadgeLabel alloc] initWithFrame:CGRectMake(0, 0, 12, 10)];
	helpBadge.layer.masksToBounds = YES;
	helpBadge.layer.cornerRadius = 6;
	helpBadge.textAlignment = NSTextAlignmentCenter;
	helpBadge.backgroundColor = [UIColor UIColorFromHex:0xdd3d36];
	helpBadge.textColor = [UIColor whiteColor];
	helpBadge.font = [WPFontManager openSansRegularFontOfSize:8.0];
	helpBadge.hidden = YES;
	
	// Add Username
	WPWalkthroughTextField *usernameText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-username-field"]];
	usernameText.backgroundColor = [UIColor whiteColor];
	usernameText.placeholder = NSLocalizedString(@"Username / Email", @"NUX First Walkthrough Page 2 Username Placeholder");
	usernameText.font = [WPNUXUtility textFieldFont];
	usernameText.adjustsFontSizeToFitWidth = YES;
	usernameText.returnKeyType = UIReturnKeyNext;
	usernameText.delegate = self;
	usernameText.autocorrectionType = UITextAutocorrectionTypeNo;
	usernameText.autocapitalizationType = UITextAutocapitalizationTypeNone;
	usernameText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	usernameText.accessibilityIdentifier = @"Username / Email";
	
	// Add OnePassword ??
	/*
	 UIButton *onePasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
	 [onePasswordButton setImage:[UIImage imageNamed:@"onepassword-button"] forState:UIControlStateNormal];
	 [onePasswordButton addTarget:self action:@selector(findLoginFromOnePassword:) forControlEvents:UIControlEventTouchUpInside];
	 [onePasswordButton sizeToFit];
	 
	 usernameText.rightView = onePasswordButton;
	 usernameText.rightViewPadding = LoginOnePasswordPadding;
	 */
	
	// Add Password
	WPWalkthroughTextField *passwordText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
	passwordText.backgroundColor = [UIColor whiteColor];
	passwordText.placeholder = NSLocalizedString(@"Password", nil);
	passwordText.font = [WPNUXUtility textFieldFont];
	passwordText.delegate = self;
	passwordText.secureTextEntry = YES;
	passwordText.returnKeyType = self.userIsDotCom ? UIReturnKeyDone : UIReturnKeyNext;
	passwordText.showSecureTextEntryToggle = YES;
	passwordText.showTopLineSeparator = YES;
	passwordText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	passwordText.accessibilityIdentifier = @"Password";
	
	
	// Add Site Url
	// 自建服务输入框
	WPWalkthroughTextField *siteUrlText = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-url-field"]];
	siteUrlText.backgroundColor = [UIColor whiteColor];
	siteUrlText.placeholder = NSLocalizedString(@"Site Address (URL)", @"NUX First Walkthrough Page 2 Site Address Placeholder");
	siteUrlText.font = [WPNUXUtility textFieldFont];
	siteUrlText.adjustsFontSizeToFitWidth = YES;
	siteUrlText.delegate = self;
	siteUrlText.keyboardType = UIKeyboardTypeURL;
	siteUrlText.returnKeyType = UIReturnKeyDone;
	siteUrlText.autocorrectionType = UITextAutocorrectionTypeNo;
	siteUrlText.autocapitalizationType = UITextAutocapitalizationTypeNone;
	siteUrlText.showTopLineSeparator = YES;
	siteUrlText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	siteUrlText.accessibilityIdentifier = @"Site Address (URL)";
	
	// Add Sign In Button
	WPNUXMainButton *signInButton = [[WPNUXMainButton alloc] init];
	[signInButton addTarget:self action:@selector(signInButtonAction:) forControlEvents:UIControlEventTouchUpInside];
	signInButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	signInButton.accessibilityIdentifier = @"Sign In";
	
	/*
	 // Text: Verification Code SMS
	 // 短信, 没用
	 NSString *codeText = NSLocalizedString(@"Enter the code on your authenticator app or ", @"Message displayed when a verification code is needed");
	 NSMutableAttributedString *attributedCodeText = [[NSMutableAttributedString alloc] initWithString:codeText];
	 
	 NSString *smsText = NSLocalizedString(@"send the code via text message.", @"Sends an SMS with the Multifactor Auth Code");
	 NSMutableAttributedString *attributedSmsText = [[NSMutableAttributedString alloc] initWithString:smsText];
	 [attributedSmsText applyUnderline];
	 
	 [attributedCodeText appendAttributedString:attributedSmsText];
	 [attributedCodeText applyFont:[WPNUXUtility confirmationLabelFont]];
	 [attributedCodeText applyForegroundColor:[UIColor whiteColor]];
	 
	 NSMutableAttributedString *attributedCodeHighlighted = [attributedCodeText mutableCopy];
	 [attributedCodeHighlighted applyForegroundColor:[WPNUXUtility confirmationLabelColor]];
	 
	 // Add Verification Code SMS Button
	 WPNUXSecondaryButton *sendVerificationCodeButton = [[WPNUXSecondaryButton alloc] init];
	 
	 sendVerificationCodeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	 sendVerificationCodeButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
	 sendVerificationCodeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
	 sendVerificationCodeButton.titleLabel.numberOfLines = LoginVerificationCodeNumberOfLines;
	 [sendVerificationCodeButton setAttributedTitle:attributedCodeText forState:UIControlStateNormal];
	 [sendVerificationCodeButton setAttributedTitle:attributedCodeHighlighted forState:UIControlStateHighlighted];
	 [sendVerificationCodeButton addTarget:self action:@selector(sendVerificationCode:) forControlEvents:UIControlEventTouchUpInside];
	 
	 // Add Multifactor 验证码, 没用
	 WPWalkthroughTextField *multifactorText = [[WPWalkthroughTextField alloc] init];
	 multifactorText.backgroundColor = [UIColor whiteColor];
	 multifactorText.placeholder = NSLocalizedString(@"Verification Code", nil);
	 multifactorText.font = [WPNUXUtility textFieldFont];
	 multifactorText.delegate = self;
	 multifactorText.keyboardType = UIKeyboardTypeNumberPad;
	 multifactorText.textAlignment = NSTextAlignmentCenter;
	 multifactorText.returnKeyType = UIReturnKeyDone;
	 multifactorText.showTopLineSeparator = YES;
	 multifactorText.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	 multifactorText.accessibilityIdentifier = @"Verification Code";
	 
	 
	 */
	
	// Add Cancel Button
	WPNUXSecondaryButton *cancelButton = [[WPNUXSecondaryButton alloc] init];
	[cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
	[cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
	[cancelButton setExclusiveTouch:YES];
	[cancelButton sizeToFit];
	
	// Add status label
	UILabel *statusLabel = [[UILabel alloc] init];
	statusLabel.font = [WPNUXUtility confirmationLabelFont];
	statusLabel.textColor = [WPNUXUtility confirmationLabelColor];
	statusLabel.textAlignment = NSTextAlignmentCenter;
	statusLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	statusLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
	
	// Add Account type toggle
	WPNUXSecondaryButton *toggleSelfHost = [[WPNUXSecondaryButton alloc] init];
	[toggleSelfHost addTarget:self action:@selector(toggleSelfHostAction:) forControlEvents:UIControlEventTouchUpInside];
	toggleSelfHost.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	
	// Add Skip to Create Account Button
	// 添加帐户
	WPNUXSecondaryButton *skipToCreateAccount = [[WPNUXSecondaryButton alloc] init];
	skipToCreateAccount.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	[skipToCreateAccount setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];
	[skipToCreateAccount addTarget:self action:@selector(skipToCreateAction:) forControlEvents:UIControlEventTouchUpInside];
	
	// Add Lost Password Button
	WPNUXSecondaryButton *forgotPassword = [[WPNUXSecondaryButton alloc] init];
	forgotPassword.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	[forgotPassword setTitle:NSLocalizedString(@"Lost your password?", nil) forState:UIControlStateNormal];
	[forgotPassword addTarget:self action:@selector(forgotPassword:) forControlEvents:UIControlEventTouchUpInside];
	forgotPassword.titleLabel.font = [WPNUXUtility tosLabelFont];
	[forgotPassword setTitleColor:[WPNUXUtility tosLabelColor] forState:UIControlStateNormal];
	
	// Attach Subviews
	[self.view addSubview:cancelButton];
	[self.mainView addSubview:icon];
	[self.mainView addSubview:helpButton];
	[self.mainView addSubview:helpBadge];
	[self.mainView addSubview:usernameText];
	[self.mainView addSubview:passwordText];
	//	[self.mainView addSubview:multifactorText];
	//	[self.mainView addSubview:sendVerificationCodeButton];
	[self.mainView addSubview:siteUrlText];
	[self.mainView addSubview:signInButton];
	[self.mainView addSubview:statusLabel];
	[self.mainView addSubview:toggleSelfHost];
	[self.mainView addSubview:skipToCreateAccount];
	[self.mainView addSubview:forgotPassword];
	
	// Keep the references!
	self.cancelButton = cancelButton;
	self.icon = icon;
	self.helpButton = helpButton;
	self.helpBadge = helpBadge;
	self.usernameText = usernameText;
	self.passwordText = passwordText;
	//	self.onePasswordButton = onePasswordButton;
	//	self.multifactorText = multifactorText;
	//	self.sendVerificationCodeButton = sendVerificationCodeButton;
	self.siteUrlText = siteUrlText;
	self.signInButton = signInButton;
	self.statusLabel = statusLabel;
	self.toggleSelfHost = toggleSelfHost;
	self.skipToCreateAccount = skipToCreateAccount;
	self.forgotPassword = forgotPassword;
}


- (void)reloadInterface
{
	[self updateControls];
	[self layoutControls];
}

- (void)updateControls
{
	// Spinner!
	[self.signInButton showActivityIndicator:self.authenticating];
	
	// One Password
	//	BOOL isOnePasswordAvailable             = [[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
	//	self.usernameText.rightViewMode         = isOnePasswordAvailable ? UITextFieldViewModeAlways : UITextFieldViewModeNever;
	
	// TextFields
	self.usernameText.alpha                 = self.usernameAlpha;
	self.passwordText.alpha                 = self.passwordAlpha;
	self.siteUrlText.alpha                  = self.siteAlpha;
	//	self.multifactorText.alpha              = self.multifactorAlpha;
	
	self.usernameText.enabled               = self.isUsernameEnabled;
	self.passwordText.enabled               = self.isPasswordEnabled;
	self.siteUrlText.enabled                = self.isSiteUrlEnabled;
	//	self.multifactorText.enabled            = self.isMultifactorEnabled;
	
	// Buttons
	self.cancelButton.hidden                = !self.isFromAddAccount || self.noAnyUser;
//	NSLog(self.isFromAddAccount ? @"isFromAddAccount" : @"NO");
	self.forgotPassword.hidden              = self.isForgotPasswordHidden;
	//	self.sendVerificationCodeButton.hidden  = self.isSendCodeHidden;
	self.skipToCreateAccount.hidden         = self.isAccountCreationHidden;
	
	// SignIn Button
	NSString *signInTitle                   = self.signInButtonTitle;
	self.signInButton.enabled               = self.isSignInEnabled;
	self.signInButton.accessibilityIdentifier = signInTitle;
	[self.signInButton setTitle:signInTitle forState:UIControlStateNormal];
	
	// Dotcom / SelfHosted Button
	NSString *toggleTitle                 = self.toggleAddSelfHostTitle;
	self.toggleSelfHost.accessibilityIdentifier = toggleTitle;
	[self.toggleSelfHost setTitle:toggleTitle forState:UIControlStateNormal];
}

- (void)layoutControls
{
	CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
	CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
	
	CGFloat textFieldX = (viewWidth - GeneralWalkthroughTextFieldSize.width) * 0.5f;
	CGFloat textLabelX = (viewWidth - GeneralWalkthroughMaxTextWidth) * 0.5f;
	CGFloat buttonX = (viewWidth - GeneralWalkthroughButtonSize.width) * 0.5f;
	
	// Layout Help Button
	CGFloat helpButtonX = viewWidth - CGRectGetWidth(self.helpButton.frame) - GeneralWalkthroughStandardOffset;
	CGFloat helpButtonY = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset;
	self.helpButton.frame = CGRectIntegral(CGRectMake(helpButtonX, helpButtonY, CGRectGetWidth(self.helpButton.frame), GeneralWalkthroughButtonSize.height));
	
	//	 layout help badge
	/*
	 CGFloat helpBadgeX = viewWidth - CGRectGetWidth(self.helpBadge.frame) - GeneralWalkthroughStandardOffset + 5;
	 CGFloat helpBadgeY = 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset + CGRectGetHeight(self.helpBadge.frame) - 5;
	 self.helpBadge.frame = CGRectIntegral(CGRectMake(helpBadgeX, helpBadgeY, CGRectGetWidth(self.helpBadge.frame), CGRectGetHeight(self.helpBadge.frame)));
	 */
	
	// Layout Cancel Button
	CGFloat cancelButtonX = 0;
	CGFloat cancelButtonY = helpButtonY; // 0.5 * GeneralWalkthroughStandardOffset + GeneralWalkthroughStatusBarOffset;
	self.cancelButton.frame = CGRectIntegral(CGRectMake(cancelButtonX, cancelButtonY, CGRectGetWidth(self.cancelButton.frame), GeneralWalkthroughButtonSize.height));
	
	// Calculate total height and starting Y origin of controls
	CGFloat heightOfControls = CGRectGetHeight(self.icon.frame) + GeneralWalkthroughStandardOffset + (self.userIsDotCom ? 2 : 3) * GeneralWalkthroughTextFieldSize.height + GeneralWalkthroughStandardOffset + GeneralWalkthroughButtonSize.height;
	// 开始Y位置
	CGFloat startingYForCenteredControls = floorf((viewHeight - 2 * GeneralWalkthroughSecondaryButtonHeight - heightOfControls)/2.0);
	
	// icon
	CGFloat iconX = (viewWidth - CGRectGetWidth(self.icon.frame)) * 0.5f; // 居中之
	CGFloat iconY = startingYForCenteredControls;
	self.icon.frame = CGRectIntegral(CGRectMake(iconX, iconY, CGRectGetWidth(self.icon.frame), CGRectGetHeight(self.icon.frame)));
	
	// Layout Username CGRectGetMaxY 返回矩形底部y坐标, 基于icon坐标+offset
	CGFloat usernameTextY = CGRectGetMaxY(self.icon.frame) + GeneralWalkthroughStandardOffset;
	self.usernameText.frame = CGRectIntegral(CGRectMake(textFieldX, usernameTextY,
														GeneralWalkthroughTextFieldSize.width,
														GeneralWalkthroughTextFieldSize.height));
	
	// Layout Password
	CGFloat passwordTextY = CGRectGetMaxY(self.usernameText.frame) - GeneralWalkthroughTextFieldOverlapY;
	self.passwordText.frame = CGRectIntegral(CGRectMake(textFieldX, passwordTextY,
														GeneralWalkthroughTextFieldSize.width,
														GeneralWalkthroughTextFieldSize.height));
	
	// Layout Site URL
	// 自建服务
	CGFloat siteUrlTextY = CGRectGetMaxY(self.passwordText.frame) - GeneralWalkthroughTextFieldOverlapY;
	self.siteUrlText.frame = CGRectIntegral(CGRectMake(textFieldX, siteUrlTextY, GeneralWalkthroughTextFieldSize.width, GeneralWalkthroughTextFieldSize.height));
	
	// Layout Sign in Button, 在最后一个textFiled下面
	CGFloat signInButtonY = [self lastTextfieldMaxY] + GeneralWalkthroughStandardOffset;
	self.signInButton.frame = CGRectIntegral(CGRectMake(buttonX, signInButtonY, GeneralWalkthroughButtonSize.width, GeneralWalkthroughButtonSize.height));
	
	// Layout Lost password Button
	CGFloat forgotPasswordY = CGRectGetMaxY(self.signInButton.frame) + 0.5 * GeneralWalkthroughStandardOffset;
	CGFloat forgotPasswordHeight = [self.forgotPassword.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.forgotPassword.titleLabel.font}].height;
	self.forgotPassword.frame = CGRectIntegral(CGRectMake(buttonX, forgotPasswordY, GeneralWalkthroughButtonSize.width, forgotPasswordHeight));
	
	
	// Layout Skip to Create Account Button
	// 相对于底部而言的位置
	CGFloat skipToCreateAccountY = viewHeight - GeneralWalkthroughStandardOffset - GeneralWalkthroughSecondaryButtonHeight;
	self.skipToCreateAccount.frame = CGRectIntegral(CGRectMake(buttonX, skipToCreateAccountY, GeneralWalkthroughButtonSize.width, GeneralWalkthroughSecondaryButtonHeight));
	
	// Layout Status Label
	CGFloat statusLabelY = CGRectGetMaxY(self.signInButton.frame) + 0.5 * GeneralWalkthroughStandardOffset;
	self.statusLabel.frame = CGRectIntegral(CGRectMake(textLabelX, statusLabelY, GeneralWalkthroughMaxTextWidth, self.statusLabel.font.lineHeight));
	
	// Layout Toggle Button
	CGFloat toggleSignInY = CGRectGetMinY(self.skipToCreateAccount.frame) - 0.5 * GeneralWalkthroughStandardOffset - GeneralWalkthroughSecondaryButtonHeight;
	self.toggleSelfHost.frame = CGRectIntegral(CGRectMake(textLabelX, toggleSignInY, GeneralWalkthroughMaxTextWidth, GeneralWalkthroughSecondaryButtonHeight));
}

// 关闭
- (void)cancelButtonAction {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Validation Helpers

- (BOOL)areFieldsValid
{
	if ([self areSelfHostedFieldsFilled] && !self.userIsDotCom) {
		return [self isUrlValid];
	}
	
	return [self areDotComFieldsFilled];
}

- (BOOL)isUsernameFilled
{
	return [[self trim:self.usernameText.text] length] != 0;
}

- (NSString *) trim:(NSString *) t {
	[t stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	return t;
}

- (BOOL)isPasswordFilled
{
	return [[self trim:self.passwordText.text] length] != 0;
}

- (BOOL)isSiteUrlFilled
{
	return [[self trim:self.siteUrlText.text] length] != 0;
}

// leanote.com要输入的用户名和密码是否都输完
- (BOOL)areDotComFieldsFilled
{
	BOOL areCredentialsFilled = [self isUsernameFilled] && [self isPasswordFilled];
	return areCredentialsFilled;
}

- (BOOL)areSelfHostedFieldsFilled
{
	return [self areDotComFieldsFilled] && [self isSiteUrlFilled];
}

- (BOOL)isUrlValid
{
	NSString *url = self.siteUrlText.text;
	if (url.length == 0) {
		return NO;
	}
	// 判断是否合法 http://leanote.com
	// http://www.no-ip.biz
	NSString *urlRegEx = @"(http|https)://((\\w)*([0-9]*)|([-|_])*)+\\.([\\w0-9\\-|_\\./:])*";
	NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
	return [urlTest evaluateWithObject:url];
	//	NSURL *siteURL = [NSURL URLWithString:[NSURL IDNEncodedURL:self.siteUrlText.text]];
	//	return siteURL != nil;
}

- (BOOL)isUserNameReserved
{
	if (!self.userIsDotCom) {
		return NO;
	}
	//	NSString *username = [[self.usernameText.text trim] lowercaseString];
	//	NSArray *reservedUserNames = @[@"admin",@"administrator",@"root"];
	
	//	return [reservedUserNames containsObject:username];
}


#pragma mark - Interface Helpers: TextFields

- (BOOL)isUsernameEnabled
{
	return !self.shouldDisplayMultifactor;
}

- (BOOL)isPasswordEnabled
{
	return !self.shouldDisplayMultifactor;
}

- (BOOL)isSiteUrlEnabled
{
	return !self.userIsDotCom;
}

- (BOOL)isMultifactorEnabled
{
	return self.shouldDisplayMultifactor;
}

- (CGFloat)usernameAlpha
{
	return self.isUsernameEnabled ? GeneralWalkthroughAlphaEnabled : GeneralWalkthroughAlphaDisabled;
}

- (CGFloat)passwordAlpha
{
	return self.isPasswordEnabled ? GeneralWalkthroughAlphaEnabled : GeneralWalkthroughAlphaDisabled;
}

// 添加自建服务是否隐藏
- (CGFloat)siteAlpha
{
	if (self.isSiteUrlEnabled) {
		return self.isMultifactorEnabled ? GeneralWalkthroughAlphaDisabled : GeneralWalkthroughAlphaEnabled;
	}
	
	return GeneralWalkthroughAlphaHidden;
}


#pragma mark - Interface Helpers: Buttons

- (BOOL)isSignInEnabled
{
	return self.userIsDotCom ? [self areDotComFieldsFilled] : [self areSelfHostedFieldsFilled];
}

- (BOOL)isSignInToggleHidden
{
	//	return self.onlyDotComAllowed || self.hasDefaultAccount || self.authenticating;
	return NO;
}


- (BOOL)isAccountCreationHidden
{
	return self.hasDefaultAccount || self.authenticating;
}

- (BOOL)isForgotPasswordHidden
{
	BOOL isEnabled = self.userIsDotCom || self.isUrlValid;
	return !isEnabled || self.authenticating || self.shouldDisplayMultifactor;
}


#pragma mark - Text Helpers

- (NSString *)signInButtonTitle
{
	if (self.shouldDisplayMultifactor) {
		return NSLocalizedString(@"Verify", @"Button title for Two Factor code verification");
	} else if (self.userIsDotCom) {
		return NSLocalizedString(@"Sign In", @"Button title for Sign In Action");
	}
	
	return NSLocalizedString(@"Add Site", @"Button title for Add SelfHosted Site");
}

- (NSString *)toggleAddSelfHostTitle
{
	if (self.userIsDotCom) {
		return NSLocalizedString(@"Add Self-Hosted Service", @"Button title for Toggle Sign Mode (Self Hosted vs DotCom");
	}
	
	return NSLocalizedString(@"Sign in to Leanote.com", @"Button title for Toggle Sign Mode (Self Hosted vs DotCom");
}

// sign in按钮是在最后一个input后面
- (CGFloat)lastTextfieldMaxY
{
	if (self.userIsDotCom) {
		return CGRectGetMaxY(self.passwordText.frame);
	}
	
	return CGRectGetMaxY(self.siteUrlText.frame);
}

// 编辑模式下至少要显示sign button
- (CGFloat)editionModeMaxY
{
	UIView *bottomView = self.signInButton;
	return CGRectGetMaxY(bottomView.frame);
}


#pragma mark - Auth Helpers

- (void)startedAuthenticatingWithMessage:(NSString *)status
{
	[self setAuthenticating:YES status:status];
}

- (void)finishedAuthenticating
{
	[self setAuthenticating:NO status:nil];
}

- (void)setAuthenticating:(BOOL)authenticating status:(NSString *)status
{
	self.authenticating = authenticating;
	
	self.statusLabel.hidden = !(status.length > 0);
	self.statusLabel.text = status;
	
	self.view.userInteractionEnabled = !authenticating;
	
	[self updateControls];
}


#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == self.usernameText) {
		[self.passwordText becomeFirstResponder];
	}
	else if (textField == self.passwordText) {
		if (self.userIsDotCom) {
			[self signInButtonAction:nil];
		} else {
			[self.siteUrlText becomeFirstResponder];
		}
		
	}
	else if (textField == self.siteUrlText) {
		if (self.signInButton.enabled) {
			[self signInButtonAction:nil];
		}
	}
	
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	return YES;
}

- (void)textFieldDidChange:(NSNotification *)note
{
	[self updateControls];
}

#pragma mark - Keyboard Handling 链接显示时要移动view

- (void)keyboardWillShow:(NSNotification *)notification
{
	NSDictionary *keyboardInfo = notification.userInfo;
	CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
	
	CGFloat newKeyboardOffset = (self.editionModeMaxY - CGRectGetMinY(keyboardFrame)) + GeneralWalkthroughStandardOffset;
	
	if (newKeyboardOffset < 0) {
		return;
	}
	
	[UIView animateWithDuration:animationDuration animations:^{
		for (UIControl *control in [self controlsToHideWithKeyboardOffset:newKeyboardOffset]) {
			control.alpha = GeneralWalkthroughAlphaHidden;
		}
		
		// 每一个控制都移下位置, 向上移动
		for (UIControl *control in [self controlsToMoveForTextEntry]) {
			CGRect frame = control.frame;
			frame.origin.y -= newKeyboardOffset;
			control.frame = frame;
		}
		
	} completion:^(BOOL finished) {
		
		self.keyboardOffset += newKeyboardOffset;
	}];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	NSDictionary *keyboardInfo = notification.userInfo;
	CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	
	CGFloat currentKeyboardOffset = self.keyboardOffset;
	self.keyboardOffset = 0;
	
	[UIView animateWithDuration:animationDuration animations:^{
		for (UIControl *control in [self controlsToHideWithKeyboardOffset:currentKeyboardOffset]) {
			control.alpha = GeneralWalkthroughAlphaEnabled;
		}
		
		for (UIControl *control in [self controlsToMoveForTextEntry]) {
			CGRect frame = control.frame;
			frame.origin.y += currentKeyboardOffset;
			control.frame = frame;
		}
		
	}];
}

- (NSArray *)controlsToMoveForTextEntry
{
	return @[ self.icon, self.usernameText, self.passwordText, self.siteUrlText, self.signInButton, self.statusLabel ];
}

// 显示键盘时, help按钮隐藏掉
- (NSArray *)controlsToHideWithKeyboardOffset:(CGFloat)offset
{
	// Always hide the Help + Badge
	NSMutableArray *controlsToHide = [NSMutableArray array];
	[controlsToHide addObjectsFromArray:@[ self.helpButton, self.helpBadge ]];
	
	// Find  controls that fall off the screen
	for (UIView *control in self.controlsToMoveForTextEntry) {
		if (control.frame.origin.y - offset <= 0) {
			[controlsToHide addObject:control];
		}
	}
	
	return controlsToHide;
}


# pragma 动作

- (IBAction)forgotPassword:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://leanote.com/findPassword"]];
}

// 自建服务按钮
- (IBAction)toggleSelfHostAction:(id)sender
{
	self.userIsDotCom = !self.userIsDotCom;
	self.passwordText.returnKeyType = self.userIsDotCom ? UIReturnKeyDone : UIReturnKeyNext;
	
	// 重新relayout, 有动画
	// Controls are layed out in initializeView. Calling this method in an animation block will animate the controls
	// to their new positions.
	[UIView animateWithDuration:GeneralWalkthroughAnimationDuration
					 animations:^{
						 [self reloadInterface];
					 }];
}

// 登录
- (IBAction)signInButtonAction:(id)sender
{
	[self.view endEditing:YES];
	
	// 是否有网络
	if (![ReachabilityUtils isInternetReachable]) {
		[ReachabilityUtils showAlertNoInternetConnection];
		return;
	}
	
	if ([self areSelfHostedFieldsFilled] && !self.userIsDotCom) {
		if(![self isUrlValid]) {
			[LeaAlert showAlertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Self hosted url is invalid", nil) withSupportButton:NO];
			return;
		}
	}
	
	if (![self areDotComFieldsFilled]) {
		[self displayErrorMessages];
		return;
	}
	
	/*
	 if ([self isUserNameReserved]) {
		[self displayReservedNameErrorMessage];
		[self toggleSignInFormAction:nil];
		[self.siteUrlText becomeFirstResponder];
		return;
	 }
	 */
	
	[self signIn];
}

- (void)signIn
{
	NSString *username = self.usernameText.text;
	NSString *password = self.passwordText.text;
	NSString *siteUrl = self.siteUrlText.text;
	
	[self startedAuthenticatingWithMessage:NSLocalizedString(@"Authenticating", nil)];
	
	[UserService login:username pwd: password host: siteUrl success:^(id ret) {
		[self finishedAuthenticating];
		
		if(!self.isFromAddAccount) {
			self.loginOkCb();
			// 跳到首页
			// [self.delegate WidgetsVC:self loginOK:nil];
		}
		else {
			self.loginOkCb();
			// [self cancelButtonAction];
		}
	} fail:^{
		[self displayRemoteError];
		[self finishedAuthenticating];
	}];
	
	// [self.userIsDotCom];
	
	/*
	 WordPressComOAuthClient *client = [WordPressComOAuthClient client];
	 [client authenticateWithUsername:username
	 password:password
	 multifactorCode:multifactor
	 success:^(NSString *authToken) {
	 
	 [self finishedAuthenticating];
	 [self removeLegacyAccountIfNeeded:username];
	 [self createWordPressComAccountForUsername:username authToken:authToken];
	 
	 } failure:^(NSError *error) {
	 
	 // Remove the Spinner + Status Message
	 [self finishedAuthenticating];
	 
	 // If needed, show the multifactor field
	 if (error.code == WordPressComOAuthErrorNeedsMultifactorCode) {
	 [self displayMultifactorTextfield];
	 } else {
	 NSDictionary *properties = @{ @"multifactor" : @(self.shouldDisplayMultifactor) };
	 [WPAnalytics track:WPAnalyticsStatLoginFailed withProperties:properties];
	 
	 [self displayRemoteError:error];
	 }
	 }];
	 */
	/*
	 void (^guessXMLRPCURLSuccess)(NSURL *) = ^(NSURL *xmlRPCURL) {
		WordPressXMLRPCApi *api = [WordPressXMLRPCApi apiWithXMLRPCEndpoint:xmlRPCURL username:username password:password];
		
		[api getBlogOptionsWithSuccess:^(id options){
	 [self finishedAuthenticating];
	 
	 if ([options objectForKey:@"wordpress.com"] != nil) {
	 [self signInWithWPComForUsername:username password:password multifactor:multifactor];
	 } else {
	 NSString *xmlrpc = [xmlRPCURL absoluteString];
	 [self createSelfHostedAccountAndBlogWithUsername:username password:password xmlrpc:xmlrpc options:options];
	 }
		} failure:^(NSError *error){
	 [WPAnalytics track:WPAnalyticsStatLoginFailed];
	 [self finishedAuthenticating];
	 [self displayRemoteError:error];
		}];
	 };
	 
	 void (^guessXMLRPCURLFailure)(NSError *) = ^(NSError *error){
		[WPAnalytics track:WPAnalyticsStatLoginFailedToGuessXMLRPC];
		[self handleGuessXMLRPCURLFailure:error];
	 };
	 
	 [self startedAuthenticatingWithMessage:NSLocalizedString(@"Authenticating", nil)];
	 
	 NSString *siteUrl = [NSURL IDNEncodedURL:self.siteUrlText.text];
	 [WordPressXMLRPCApi guessXMLRPCURLForSite:siteUrl success:guessXMLRPCURLSuccess failure:guessXMLRPCURLFailure];
	 */
}

- (IBAction)skipToCreateAction:(id)sender
{
	[self register];
}

- (void) register {
	NSLog(@"skipToCreateAction");
	// TestViewController.h
	RegisterController *createAccountViewController = [[RegisterController alloc] init];
	[createAccountViewController cb:^{
		self.loginOkCb();
	}];
	[self.navigationController pushViewController:createAccountViewController animated:YES];
}

#pragma mark - Displaying of Error Messages

- (void)displayErrorMessages
{
	[LeaAlert showAlertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Please fill out all the fields", nil) withSupportButton:NO];
}

- (void)showError:(NSString *)message
{
	WPWalkthroughOverlayView *overlayView = [[WPWalkthroughOverlayView alloc] initWithFrame:self.view.bounds];
	overlayView.overlayTitle = NSLocalizedString(@"Error", nil);
	overlayView.overlayDescription = message;
	overlayView.dismissCompletionBlock = ^(WPWalkthroughOverlayView *overlayView){
		[overlayView dismiss];
	};
	[self.view addSubview:overlayView];
}

- (void)displayRemoteError
{
	NSString *errorMessage = NSLocalizedString(@"Username or password is not valid", nil);
	[self showError:NSLocalizedString(errorMessage, nil)];
}

@end
