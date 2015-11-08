#import "LeaAlert.h"

NSInteger const SupportButtonIndex = 0;

@interface LeaAlert () <UIAlertViewDelegate>
@property (nonatomic, assign) BOOL alertShowing;
@property (nonatomic, copy) void (^okPressedBlock)();

@end

@implementation LeaAlert

+ (instancetype)internalInstance
{
    static LeaAlert *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LeaAlert alloc] init];
    });
    return instance;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	self.alertShowing = NO;
	
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	if([title isEqualToString:NSLocalizedString(@"NO", nil)])
	{
	}
	else if([title isEqualToString:NSLocalizedString(@"OK", nil)])
	{
		if(self.okPressedBlock) {
			self.okPressedBlock(nil);
			self.okPressedBlock = nil;
		}
	}
}

+ (void)showNetworkingAlertWithError:(NSError *)error
{
    [self showNetworkingAlertWithError:error title:nil];
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    [self showAlertWithTitle:title message:message withSupportButton:NO okPressedBlock:nil];
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message withSupportButton:(BOOL)showSupport
{
    [self showAlertWithTitle:title message:message withSupportButton:showSupport okPressedBlock:nil];
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message withSupportButton:(BOOL)showSupport okPressedBlock:(void (^)()) okBlock
{
    if ([LeaAlert internalInstance].alertShowing) {
        return;
    }
    [LeaAlert internalInstance].alertShowing = YES;

//    DDLogInfo(@"Showing alert with title: %@ and message %@", title, message);
    NSString *supportText = showSupport ? NSLocalizedString(@"Need Help?", nil) : nil;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:[LeaAlert internalInstance]
                                          cancelButtonTitle:supportText
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    [alert show];
    [LeaAlert internalInstance].okPressedBlock = okBlock;
}


@end
