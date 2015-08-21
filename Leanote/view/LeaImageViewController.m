#import "LeaImageViewController.h"

#import <AFNetworking/UIKit+AFNetworking.h>
#import "Common.h"
//#import "WordPressAppDelegate.h"


static CGFloat const MaximumZoomScale = 4.0;
static CGFloat const MinimumZoomScale = 0.1;

@interface LeaImageViewController ()<UIScrollViewDelegate>

@property (nonatomic, assign) BOOL isLoadingImage;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) BOOL shouldHideStatusBar;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UIButton *saveBtn;

@end

@implementation LeaImageViewController

#pragma mark - LifeCycle Methods

- (instancetype)initWithImage:(UIImage *)image
{
    return [self initWithImage:image andURL:nil];
}

- (instancetype)initWithURL:(NSURL *)url
{
    return [self initWithImage:nil andURL: url];
}

- (instancetype)initWithImage:(UIImage *)image andURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _image = [image copy];
        _url = url;
    }
    return self;
}

- (UIImage *) getImage {
	return self.image;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    CGRect frame = self.view.frame;
    frame = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
    self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.scrollView.maximumZoomScale = MaximumZoomScale;
    self.scrollView.minimumZoomScale = MinimumZoomScale;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];

    self.imageView = [[UIImageView alloc] initWithFrame:frame];
    self.imageView.userInteractionEnabled = YES;
    [self.scrollView addSubview:self.imageView];

	// 双击
    UITapGestureRecognizer *tgr2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageDoubleTapped:)];
    [tgr2 setNumberOfTapsRequired:2];
    [self.imageView addGestureRecognizer:tgr2];

	// 整个scroll view单击消失
    UITapGestureRecognizer *tgr1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTapped:)];
    [tgr1 setNumberOfTapsRequired:1];
    [tgr1 requireGestureRecognizerToFail:tgr2];
    [self.scrollView addGestureRecognizer:tgr1];
	
	// loading
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	self.activityIndicatorView.color = [UIColor grayColor];
    self.activityIndicatorView.hidesWhenStopped = YES;
    self.activityIndicatorView.center = self.view.center;
    self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:self.activityIndicatorView];
	
	// 下载按钮
	UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage *image = [[UIImage imageNamed:@"download"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[myButton setImage:image forState:UIControlStateNormal];
//	[myButton setTitle:NSLocalizedString(@"Save as", nil) forState:UIControlStateNormal];
//	[myButton setTitle:@"可以松手~" forState:UIControlStateHighlighted];
	[myButton addTarget:self action:@selector(saveAs:) forControlEvents:UIControlEventTouchUpInside];
	myButton.tintColor = [UIColor whiteColor];
//	myButton.backgroundColor = [UIColor yellowColor];
	myButton.frame = CGRectMake(20, self.view.frame.size.height - 45, 25, 25);
	[self.view addSubview:myButton];
	
	if(self.image) {
		myButton.enabled = YES;
	}
	self.saveBtn = myButton;
	self.saveBtn.hidden = YES;
	
    [self loadImage];
}

- (void)loadImage
{
    if (self.isLoadingImage) {
        return;
    }

    if (self.image != nil) {
        self.imageView.image = self.image;
        [self.imageView sizeToFit];
        self.scrollView.contentSize = self.imageView.image.size;
        [self centerImage];

    } else if (self.url) {
        self.isLoadingImage = YES;
        [self.activityIndicatorView startAnimating];
        __weak __typeof__(self) weakSelf = self;
        [_imageView setImageWithURLRequest:[NSURLRequest requestWithURL:self.url]
                         placeholderImage:self.image
                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                      __typeof__(self) strongSelf = weakSelf;
                                      if (!strongSelf) {
                                          return;
                                      }
                                      [strongSelf.activityIndicatorView stopAnimating];
									  strongSelf.image = image;
									  weakSelf.saveBtn.enabled = YES;
                                      strongSelf.imageView.image = image;
                                      [strongSelf.imageView sizeToFit];
                                      strongSelf.scrollView.contentSize = strongSelf.imageView.image.size;
                                      [strongSelf centerImage];
                                      strongSelf.isLoadingImage = NO;
                                  } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
//                                      DDLogError(@"Error loading image: %@", error);
                                      __typeof__(self) strongSelf = weakSelf;
                                      [strongSelf.activityIndicatorView stopAnimating];
                                      strongSelf.isLoadingImage = NO;
                                  }];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self hideBars:YES animated:animated];
    [self centerImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self hideBars:NO animated:animated];
	
	if(self.willAppear) {
		self.willAppear();
	}
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self centerImage];
}

#pragma mark - Instance Methods

- (void)hideBars:(BOOL)hide animated:(BOOL)animated
{
	return;
	
    self.shouldHideStatusBar = hide;
    
    // Force an update of the status bar appearance and visiblity
    if (animated) {
        [UIView animateWithDuration:0.3
                         animations:^{
                             [self setNeedsStatusBarAppearanceUpdate];
                         }];
    } else {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)centerImage
{
    CGFloat scaleWidth = CGRectGetWidth(self.scrollView.frame) / self.imageView.image.size.width;
    CGFloat scaleHeight = CGRectGetHeight(self.scrollView.frame) / self.imageView.image.size.height;

    self.scrollView.minimumZoomScale = MIN(scaleWidth, scaleHeight);
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;

    [self scrollViewDidZoom:self.scrollView];
}

-(void)saveAs:(id)sender
{
	if(self.image) {
		UIImageWriteToSavedPhotosAlbum(self.image, nil, nil,nil);
		[Common showSuccessMsg:NSLocalizedString(@"Save image successful", nil)];
	}
//	[self dismissViewControllerAnimated:YES completion:nil];
}

// 单击消失
- (void)handleImageTapped:(UITapGestureRecognizer *)tgr
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 双击缩放
- (void)handleImageDoubleTapped:(UITapGestureRecognizer *)tgr
{
    if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
        return;
    }

    CGPoint point = [tgr locationInView:self.imageView];
    CGSize size = self.scrollView.frame.size;

    CGFloat w = size.width / self.scrollView.maximumZoomScale;
    CGFloat h = size.height / self.scrollView.maximumZoomScale;
    CGFloat x = point.x - (w / 2.0f);
    CGFloat y = point.y - (h / 2.0f);

    CGRect rect = CGRectMake(x, y, w, h);
    [self.scrollView zoomToRect:rect animated:YES];
}

#pragma mark - UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGSize size = scrollView.frame.size;
    CGRect frame = self.imageView.frame;

    if (frame.size.width < size.width) {
        frame.origin.x = (size.width - frame.size.width) / 2;
    } else {
        frame.origin.x = 0;
    }

    if (frame.size.height < size.height) {
        frame.origin.y = (size.height - frame.size.height) / 2;
    } else {
        frame.origin.y = 0;
    }

    self.imageView.frame = frame;
}

#pragma mark - Status bar management

- (BOOL)prefersStatusBarHidden
{
    return self.shouldHideStatusBar;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

#pragma mark - Static Helpers

+ (BOOL)isUrlSupported:(NSURL *)url
{
    // Safeguard
    if (!url) {
        return NO;
    }
    
    // We only support: PNG + JPG + JPEG + GIF
    NSString *absoluteURL = url.absoluteString;

    NSArray *types = @[@".png", @".jpg", @".gif", @".jpeg"];
    for (NSString *type in types) {
        if (NSNotFound != [absoluteURL rangeOfString:type].location) {
            return YES;
        }
    }
    
    return NO;
}

@end
