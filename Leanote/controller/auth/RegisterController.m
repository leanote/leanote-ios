//
//  LoginViewController.m
//  Leanote
//
//  Created by life
//

#import "WPNUXHelpBadgeLabel.h"
#import "WPWalkthroughTextField.h"
#import "WPNUXMainButton.h"
#import "WPNUXBackButton.h"
#import "WPNUXSecondaryButton.h"
#import "WPWalkthroughOverlayView.h"

#import "RegisterController.h"

#import <WordPress-iOS-Shared/WPFontManager.h>
#import <WordPress-iOS-Shared/UIColor+Helpers.h>
#import <WordPress-iOS-Shared/WPNUXUtility.h>
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPress-iOS-Shared/NSString+Util.h>

#import "UILabel+SuggestSize.h"

#import "ReachabilityUtils.h"
#import "LeaAlert.h"
#import "Common.h"

#import "UserService.h"

@interface RegisterController () <UITextFieldDelegate,UIGestureRecognizerDelegate> {
	// Page 1
	WPNUXBackButton *_backButton;
	UIButton *_helpButton;
	UILabel *_titleLabel;
	UILabel *_TOSLabel;
	UILabel *_siteAddressWPComLabel;
	WPWalkthroughTextField *_emailField;
	WPWalkthroughTextField *_usernameField;
	WPWalkthroughTextField *_passwordField;
	UIButton *_onePasswordButton;
	WPNUXMainButton *_createAccountButton;
//	WPWalkthroughTextField *_siteAddressField;
	
	NSOperationQueue *_operationQueue;
	
	BOOL _authenticating;
	BOOL _keyboardVisible;
	BOOL _shouldCorrectEmail;
	BOOL _userDefinedSiteAddress;
	CGFloat _keyboardOffset;
	NSString *_defaultSiteUrl;
	
	NSDictionary *_currentLanguage;
}

@property (nonatomic, strong) void (^registerOkCb)();

@end

@implementation RegisterController

static CGFloat const CreateAccountAndBlogStandardOffset = 15.0;
static CGFloat const CreateAccountAndBlogMaxTextWidth = 260.0;
static CGFloat const CreateAccountAndBlogTextFieldWidth = 320.0;
static CGFloat const CreateAccountAndBlogTextFieldHeight = 44.0;
static CGFloat const CreateAccountAndBlogTextFieldPhoneHeight = 44.0;
static CGFloat const CreateAccountAndBlogiOS7StatusBarOffset = 20.0;
static CGFloat const CreateAccountAndBlogButtonWidth = 290.0;
static CGFloat const CreateAccountAndBlogButtonHeight = 40.0;
static CGPoint const CreateAccountAndBlogOnePasswordPadding = {9.0, 0.0};

// 回调
-(void)cb:(void (^)())registerOkCb
{
	self.registerOkCb = registerOkCb;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.view.backgroundColor = [WPStyleGuide wordPressBlue];
	
	[self addControls];
	[self reloadInterface];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow)
												 name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide)
												 name:UIKeyboardDidHideNotification object:nil];
	
	// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
}


-(void)viewDidAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

#pragma mark LoginView


// 都是用代码来实现的啊
- (void)addControls
{
	// Add Help Button
	UIImage *helpButtonImage = [UIImage imageNamed:@"btn-help"];
	if (_helpButton == nil) {
		_helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_helpButton.accessibilityLabel = NSLocalizedString(@"Help", @"Help button");
		[_helpButton setImage:helpButtonImage forState:UIControlStateNormal];
		_helpButton.frame = CGRectMake(0, 0, helpButtonImage.size.width, helpButtonImage.size.height);
		[_helpButton addTarget:self action:@selector(helpButtonAction) forControlEvents:UIControlEventTouchUpInside];
		_helpButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		[self.view addSubview:_helpButton];
		
		// 帮助按钮隐藏
		_helpButton.hidden = YES;
	}
	
	// Add Cancel Button
	if (_backButton == nil) {
		_backButton = [[WPNUXBackButton alloc] init];
		[_backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
		[_backButton sizeToFit];
		_backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		[self.view addSubview:_backButton];
	}
	
	// Add Title
	if (_titleLabel == nil) {
		_titleLabel = [[UILabel alloc] init];
		_titleLabel.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Create an account on Leanote.com", @"NUX Create Account Page 1 Title")
																	 attributes:[WPNUXUtility titleAttributesWithColor:[UIColor whiteColor]]];
		_titleLabel.numberOfLines = 0;
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		[self.view addSubview:_titleLabel];
	}
	
	// Add Email
	if (_emailField == nil) {
		_emailField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-email-field"]];
		_emailField.backgroundColor = [UIColor whiteColor];
		_emailField.placeholder = NSLocalizedString(@"Email Address", @"NUX Create Account Page 1 Email Placeholder");
		_emailField.font = [WPNUXUtility textFieldFont];
		_emailField.adjustsFontSizeToFitWidth = YES;
		_emailField.delegate = self;
		_emailField.autocorrectionType = UITextAutocorrectionTypeNo;
		_emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		_emailField.keyboardType = UIKeyboardTypeEmailAddress;
		_emailField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		_emailField.accessibilityIdentifier = @"Email Address";
		[self.view addSubview:_emailField];
	}
	
	// Add Username
	if (_usernameField == nil) {
		_usernameField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-username-field"]];
		_usernameField.backgroundColor = [UIColor whiteColor];
		_usernameField.placeholder = NSLocalizedString(@"Username", nil);
		_usernameField.font = [WPNUXUtility textFieldFont];
		_usernameField.adjustsFontSizeToFitWidth = YES;
		_usernameField.delegate = self;
		_usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
		_usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		_usernameField.showTopLineSeparator = YES;
		_usernameField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		_usernameField.accessibilityIdentifier = @"Username";
		[self.view addSubview:_usernameField];
	}
	
	// Add Password
	if (_passwordField == nil) {
		_passwordField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-password-field"]];
		_passwordField.secureTextEntry = YES;
		_passwordField.showSecureTextEntryToggle = YES;
		_passwordField.backgroundColor = [UIColor whiteColor];
		_passwordField.placeholder = NSLocalizedString(@"Password", nil);
		_passwordField.font = [WPNUXUtility textFieldFont];
		_passwordField.adjustsFontSizeToFitWidth = YES;
		_passwordField.delegate = self;
		_passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
		_passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		_passwordField.showTopLineSeparator = YES;
		_passwordField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		_passwordField.accessibilityIdentifier = @"Password";
		[self.view addSubview:_passwordField];
	}
	
	// Add OnePassword
	if (_onePasswordButton == nil) {
		_onePasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_onePasswordButton setImage:[UIImage imageNamed:@"onepassword-button"] forState:UIControlStateNormal];
		[_onePasswordButton addTarget:self action:@selector(saveLoginToOnePassword:) forControlEvents:UIControlEventTouchUpInside];
		[_onePasswordButton sizeToFit];
		
		_passwordField.rightView = _onePasswordButton;
		_passwordField.rightViewPadding = CreateAccountAndBlogOnePasswordPadding;
	}
	
	BOOL isOnePasswordAvailable = NO;
	_passwordField.rightViewMode = isOnePasswordAvailable ? UITextFieldViewModeAlways : UITextFieldViewModeNever;
	_passwordField.showSecureTextEntryToggle = !isOnePasswordAvailable;
	
	/*
	// Add Site Address
	if (_siteAddressField == nil) {
		_siteAddressField = [[WPWalkthroughTextField alloc] initWithLeftViewImage:[UIImage imageNamed:@"icon-url-field"]];
		_siteAddressField.backgroundColor = [UIColor whiteColor];
		_siteAddressField.placeholder = NSLocalizedString(@"Site Address (URL)", nil);
		_siteAddressField.font = [WPNUXUtility textFieldFont];
		_siteAddressField.adjustsFontSizeToFitWidth = YES;
		_siteAddressField.delegate = self;
		_siteAddressField.autocorrectionType = UITextAutocorrectionTypeNo;
		_siteAddressField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		_siteAddressField.showTopLineSeparator = YES;
		_siteAddressField.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		_siteAddressField.accessibilityIdentifier = @"Site Address (URL)";
		[self.view addSubview:_siteAddressField];
		
		// add .wordpress.com label to textfield
		_siteAddressWPComLabel = [[UILabel alloc] init];
		_siteAddressWPComLabel.text = @".wordpress.com";
		_siteAddressWPComLabel.textAlignment = NSTextAlignmentCenter;
		_siteAddressWPComLabel.font = [WPNUXUtility descriptionTextFont];
		_siteAddressWPComLabel.textColor = [WPStyleGuide allTAllShadeGrey];
		[_siteAddressWPComLabel sizeToFit];
		
		UIEdgeInsets siteAddressTextInsets = [(WPWalkthroughTextField *)_siteAddressField textInsets];
		siteAddressTextInsets.right += _siteAddressWPComLabel.frame.size.width + 10;
		[(WPWalkthroughTextField *)_siteAddressField setTextInsets:siteAddressTextInsets];
		[_siteAddressField addSubview:_siteAddressWPComLabel];
	}
	*/
	
	// Add Terms of Service Label
	if (_TOSLabel == nil) {
		
		// Build the string in two parts so the coloring of "Terms of Service." doesn't break when it gets translated
		NSString *plainTosText = NSLocalizedString(@"By creating an account you agree to the fascinating Terms of Service.", @"NUX Create Account TOS Label");
		NSString *tosFindText = NSLocalizedString(@"Terms of Service", @"'Terms of Service' should be the same text that is in 'NUX Create Account TOS Label'");
		
		NSMutableAttributedString *tosText = [[NSMutableAttributedString alloc] initWithString:plainTosText];
		[tosText addAttribute:NSForegroundColorAttributeName
						value:[WPNUXUtility tosLabelColor]
						range:NSMakeRange(0, [tosText length])];
		
		if ([plainTosText rangeOfString:tosFindText options:NSCaseInsensitiveSearch].location != NSNotFound ) {
			[tosText addAttribute:NSForegroundColorAttributeName
							value:[UIColor whiteColor]
							range:[plainTosText rangeOfString:tosFindText options:NSCaseInsensitiveSearch]];
		}
		
		_TOSLabel = [[UILabel alloc] init];
		_TOSLabel.userInteractionEnabled = YES;
		_TOSLabel.textAlignment = NSTextAlignmentCenter;
		_TOSLabel.attributedText = tosText;
		_TOSLabel.numberOfLines = 0;
		_TOSLabel.backgroundColor = [UIColor clearColor];
		_TOSLabel.font = [WPNUXUtility tosLabelFont];
		_TOSLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		[self.view addSubview:_TOSLabel];
		
		UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
																							action:@selector(TOSLabelWasTapped)];
		gestureRecognizer.numberOfTapsRequired = 1;
		[_TOSLabel addGestureRecognizer:gestureRecognizer];
	}
	
	// Add Next Button
	if (_createAccountButton == nil) {
		_createAccountButton = [[WPNUXMainButton alloc] init];
		[_createAccountButton setTitle:NSLocalizedString(@"Create Account", nil) forState:UIControlStateNormal];
		_createAccountButton.enabled = NO;
		[_createAccountButton addTarget:self action:@selector(createAccountButtonAction) forControlEvents:UIControlEventTouchUpInside];
		[_createAccountButton sizeToFit];
		_createAccountButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		[self.view addSubview:_createAccountButton];
	}
}

- (void)layoutControls
{
	CGFloat x,y;
	
	CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
	CGFloat viewHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
	
	// Layout Help Button
	UIImage *helpButtonImage = [UIImage imageNamed:@"btn-help"];
	x = viewWidth - helpButtonImage.size.width - CreateAccountAndBlogStandardOffset;
	y = 0.5 * CreateAccountAndBlogStandardOffset + CreateAccountAndBlogiOS7StatusBarOffset;
	_helpButton.frame = CGRectMake(x, y, helpButtonImage.size.width, CreateAccountAndBlogButtonHeight);
	
	// Layout Cancel Button
	x = 0;
	y = 0.5 * CreateAccountAndBlogStandardOffset + CreateAccountAndBlogiOS7StatusBarOffset;
	_backButton.frame = CGRectMake(x, y, CGRectGetWidth(_backButton.frame), CreateAccountAndBlogButtonHeight);
	
	// Layout the controls starting out from y of 0, then offset them once the height of the controls
	// is accurately calculated we can determine the vertical center and adjust everything accordingly.
	
	// Layout Title
	CGSize titleSize = [_titleLabel suggestedSizeForWidth:CreateAccountAndBlogMaxTextWidth];
	x = (viewWidth - titleSize.width)/2.0;
	y = 0;
	_titleLabel.frame = CGRectMake(x, y, titleSize.width, titleSize.height); // CGRectIntegral();
	
	// In order to fit controls ontol all phones, the textField height is smaller on iPhones
	// versus iPads.
	CGFloat textFieldHeight = IS_IPAD ? CreateAccountAndBlogTextFieldHeight: CreateAccountAndBlogTextFieldPhoneHeight;
	
	// Layout Email
	x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
	y = CGRectGetMaxY(_titleLabel.frame) + CreateAccountAndBlogStandardOffset;
	_emailField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, textFieldHeight));
	
	// Layout Username 不显示
	x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
	y = CGRectGetMaxY(_emailField.frame) - 1;
	_usernameField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, textFieldHeight));
	_usernameField.hidden = YES;
	
	// Layout Password
	x = (viewWidth - CreateAccountAndBlogTextFieldWidth)/2.0;
	y = CGRectGetMaxY(_emailField.frame) - 1;
	_passwordField.frame = CGRectIntegral(CGRectMake(x, y, CreateAccountAndBlogTextFieldWidth, textFieldHeight));
	
	// Layout Create Account Button
	x = (viewWidth - CreateAccountAndBlogButtonWidth)/2.0;
	y = CGRectGetMaxY(_passwordField.frame) + CreateAccountAndBlogStandardOffset;
	_createAccountButton.frame = CGRectIntegral(CGRectMake(x,
														   y,
														   CreateAccountAndBlogButtonWidth,
														   CreateAccountAndBlogButtonHeight));
	
	// Layout Terms of Service
	CGFloat TOSSingleLineHeight = [@"WordPress" sizeWithAttributes:@{NSFontAttributeName:_TOSLabel.font}].height;
	CGSize TOSLabelSize = [_TOSLabel.text boundingRectWithSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX)
													   options:NSStringDrawingUsesLineFragmentOrigin
													attributes:@{NSFontAttributeName: _TOSLabel.font}
													   context:nil].size;
	// If the terms of service don't fit on two lines, then shrink the font to make sure
	// the entire terms of service is visible.
	if (TOSLabelSize.height > 2*TOSSingleLineHeight) {
		_TOSLabel.font = [WPNUXUtility tosLabelSmallerFont];
		TOSLabelSize = [_TOSLabel.text boundingRectWithSize:CGSizeMake(CreateAccountAndBlogMaxTextWidth, CGFLOAT_MAX)
													options:NSStringDrawingUsesLineFragmentOrigin
												 attributes:@{NSFontAttributeName: _TOSLabel.font} context:nil].size;
	}
	x = (viewWidth - TOSLabelSize.width)/2.0;
	y = CGRectGetMaxY(_createAccountButton.frame) + 0.5 * CreateAccountAndBlogStandardOffset;
	_TOSLabel.frame = CGRectIntegral(CGRectMake(x, y, TOSLabelSize.width, TOSLabelSize.height));
	_TOSLabel.hidden = YES;
	
	
	NSArray *controls = @[_titleLabel, _emailField, _usernameField, _passwordField,
						  _TOSLabel, _createAccountButton/*, _siteAddressField*/];
	
	// 让这些view垂直居中
	[WPNUXUtility centerViews:controls withStartingView:_titleLabel andEndingView:_TOSLabel forHeight:viewHeight];
}

- (void)reloadInterface
{
	[self layoutControls];
}

- (IBAction)backButtonAction
{
	[self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == _emailField) {
		[_passwordField becomeFirstResponder];
	} else if (textField == _passwordField) {
		if (_createAccountButton.enabled) {
			[self createAccountButtonAction];
		}
	}
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
	NSArray *fields = @[_emailField, _passwordField];
	
	NSMutableString *updatedString = [[NSMutableString alloc] initWithString:textField.text];
	[updatedString replaceCharactersInRange:range withString:string];
	
	if ([fields containsObject:textField]) {
		[self updateCreateAccountButtonForTextfield:textField andUpdatedString:updatedString];
	}
	
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
//	if ([textField isEqual:_usernameField]) {
//		if ([[_siteAddressField.text trim] length] == 0 || !_userDefinedSiteAddress) {
//			_siteAddressField.text = _defaultSiteUrl = _usernameField.text;
//			_userDefinedSiteAddress = NO;
//			[self updateCreateAccountButtonForTextfield:_siteAddressField andUpdatedString:_siteAddressField.text];
//		}
//	}
	
	_createAccountButton.enabled = [self fieldsValid];
}

- (void)updateCreateAccountButtonForTextfield:(UITextField *)textField andUpdatedString:(NSString *)updatedString
{
	BOOL isEmailFilled = [self isEmailedFilled];
	BOOL isPasswordFilled = [self isPasswordFilled];
	
	BOOL updatedStringHasContent = [[updatedString trim] length] != 0;
	
	if (textField == _emailField) {
		isEmailFilled = updatedStringHasContent;
	}
	else if (textField == _passwordField) {
		isPasswordFilled = updatedStringHasContent;
	}
	
	_createAccountButton.enabled = [self fieldsFilled];
}

// focus
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	_createAccountButton.enabled = [self fieldsFilled];
	return YES;
}

// blur
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	NSLog(@"textFieldShouldEndEditing");
	if (textField == _emailField) {
		// check email validity
//		NSString *suggestedEmail = [EmailChecker suggestDomainCorrection: _emailField.text];
//		if (![suggestedEmail isEqualToString:_emailField.text] && _shouldCorrectEmail) {
//			textField.text = suggestedEmail;
//			_shouldCorrectEmail = NO;
//		}
	}
	_createAccountButton.enabled = [self fieldsFilled];
	return YES;
}
/*
- (void)textFieldDidChange:(NSNotification *)note
{
	BOOL ok = [self fieldsFilled];
	NSLog(@"%@",_createAccountButton.enabled ? @"OK" : @"NO");
	if (_createAccountButton.enabled != ok) {
		_createAccountButton.enabled = ok;
		NSLog(@"@??");
	}
}
*/

#pragma action

- (IBAction)createAccountButtonAction
{
	[self.view endEditing:YES];
	
	if (![self isEmailValid]) {
		[self showFieldsEmailNotValid];
		return;
	}
	
	NSString *email = [_emailField.text trim];
	NSString *pwd = [_passwordField.text trim];
	
	[self setAuthenticating:YES];
	[UserService register:email pwd:pwd success:^(User * user) {
		// 成功!!
		[self setAuthenticating:NO];
		
		self.registerOkCb();
		
	} fail:^(id ret) {
		//  Msg: userHasBeenRegistered-test321@leanote.com
		[self setAuthenticating:NO];
		NSString *msg;
		if (ret) {
			NSString *msg2 = ret[@"Msg"];
			if([msg2 hasPrefix:@"userHasBeenRegistered"]) {
				msg = NSLocalizedString(@"The account has been registered, please choose another one", nil);
			}
		}
		[self displayRemoteError:msg];
	}];
	
//	[self createUserAndSite];
}

- (void)setAuthenticating:(BOOL)authenticating
{
	_authenticating = authenticating;
	_createAccountButton.enabled = !authenticating;
	_onePasswordButton.enabled = !authenticating;
	[_createAccountButton showActivityIndicator:authenticating];
}

- (void)displayRemoteError:(NSString *)msg
{
	if(!msg) {
		msg = NSLocalizedString(@"Create account failed", nil);
	}
	[self showError:msg];
}

- (void)showFieldsEmailNotValid
{
	[self showError:NSLocalizedString(@"Email is not valid", nil)];
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

#pragma valid

- (BOOL)fieldsFilled
{
	return [self isEmailedFilled] && [self isPasswordFilled];
}

- (BOOL)isEmailedFilled
{
	return ([[_emailField.text trim] length] != 0);
}

- (BOOL)isPasswordFilled
{
	return ([[_passwordField.text trim] length] >= 5);
}

- (BOOL)isEmailValid
{
	return [Common validateEmail:[_emailField.text trim]];
}

- (BOOL)fieldsValid
{
	if (![self fieldsFilled]) {
		return NO;
	}
	return YES;
}

#pragma keybord


- (void)keyboardWillShow:(NSNotification *)notification
{
	NSDictionary *keyboardInfo = notification.userInfo;
	CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	CGRect keyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
	
	CGFloat newKeyboardOffset = (CGRectGetMaxY(_createAccountButton.frame) - CGRectGetMinY(keyboardFrame)) + CreateAccountAndBlogStandardOffset;
	
	// make sure keyboard offset is greater than 0, otherwise do not move controls
	if (newKeyboardOffset < 0) {
		return;
	}
	
	[UIView animateWithDuration:animationDuration animations:^{
		for (UIControl *control in [self controlsToMoveDuringKeyboardTransition]) {
			CGRect frame = control.frame;
			frame.origin.y -= newKeyboardOffset;
			control.frame = frame;
		}
		
		for (UIControl *control in [self controlsToShowOrHideDuringKeyboardTransition]) {
			control.alpha = 0.0;
		}
	} completion:^(BOOL finished) {
		_keyboardOffset += newKeyboardOffset;
	}];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	NSDictionary *keyboardInfo = notification.userInfo;
	CGFloat animationDuration = [[keyboardInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	
	CGFloat currentKeyboardOffset = _keyboardOffset;
	_keyboardOffset = 0;
	
	[UIView animateWithDuration:animationDuration animations:^{
		for (UIControl *control in [self controlsToMoveDuringKeyboardTransition]) {
			CGRect frame = control.frame;
			frame.origin.y += currentKeyboardOffset;
			control.frame = frame;
		}
		
		for (UIControl *control in [self controlsToShowOrHideDuringKeyboardTransition]) {
			control.alpha = 1.0;
		}
	}];
}

- (void)keyboardDidShow
{
	_keyboardVisible = YES;
}

- (void)keyboardDidHide
{
	_keyboardVisible = NO;
}

- (NSArray *)controlsToMoveDuringKeyboardTransition
{
	return @[_titleLabel, _emailField, _passwordField, _createAccountButton];
}

- (NSArray *)controlsToShowOrHideDuringKeyboardTransition
{
	return @[_helpButton, _backButton, _TOSLabel];
}


@end
