#import <UIKit/UIKit.h>

@interface LeaImageViewController : UIViewController

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) void (^willAppear)(void);

- (instancetype)initWithImage:(UIImage *)image;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithImage:(UIImage *)image andURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (void)loadImage;
- (void)hideBars:(BOOL)hide animated:(BOOL)animated;
- (void)centerImage;

+ (BOOL)isUrlSupported:(NSURL *)url;
- (UIImage *) getImage;
@end
