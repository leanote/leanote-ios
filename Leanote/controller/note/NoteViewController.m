//
//  NoteViewController.m
//  Leanote
//
//  Created by life on 15/5/31.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "NoteViewController.h"
#import "BaseViewController.h"

@import AssetsLibrary;
@import AVFoundation;
#import <CocoaLumberjack/CocoaLumberjack.h>

#import "SVProgressHUD.h"

#import "WPEditorField.h"
#import "WPEditorView.h"

#import "LeaAlert.h"

#import "LeaButtonForNavigationBar.h"
#import <WordPress-iOS-Shared/WordPressShared/UIImage+Util.h>
#import <WordPress-iOS-Shared/WordPressShared/WPFontManager.h>
#import <WordPress-iOS-Shared/WordPressShared/WPStyleGuide.h>
#import <QBImagePickerController/QBImagePickerController.h>

#import "NoteSettingsTableViewController.h"
#import "LeaWebViewController.h"

//#import "NoteService.h"
//#import "NotebookService.h"
#import "FileService.h"
#import "Leas.h"

#import "UserService.h"

#import "Common.h"
#import "ApiMsg.h"

#import "LeaImageViewController.h"
#import "LeaImagePagerViewController.h"
#import "LeaImageSliderViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>


typedef NS_ENUM(NSUInteger,  WPViewControllerActionSheet) {
    WPViewControllerActionSheetImageUploadStop = 200,
    WPViewControllerActionSheetImageUploadRetry = 201,
    WPViewControllerActionSheetVideoUploadStop = 202,
    WPViewControllerActionSheetVideoUploadRetry = 203
};

// 按钮大小, 间距
const CGRect NavigationBarButtonRect = {
    .origin.x = 0.0f,
    .origin.y = 0.0f,
    .size.width = 30.0f,
    .size.height = 30.0f
};
static CGFloat const SpacingBetweeenNavbarButtons = 20.0f;
//static CGFloat const RightSpacingOnExitNavbarButton = 5.0f;
static NSDictionary *DisabledButtonBarStyle;
static NSDictionary *EnabledButtonBarStyle;
static NSInteger const MaximumNumberOfPictures = 10;


@interface NoteViewController () <CTAssetsPickerControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, QBImagePickerControllerDelegate, UIAlertViewDelegate>

@property(nonatomic, strong) NSMutableDictionary *mediaAdded;
@property(nonatomic, strong) NSString *selectedMediaID;
@property(nonatomic, strong) NSCache *videoPressCache;

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextView *textView; // 为什么要有?

// 按钮
@property (nonatomic, strong) UIBarButtonItem *cancelButton; // 取消, 即返回
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem; // 编辑按钮
@property (nonatomic, strong) UIBarButtonItem *saveBarButtonItem; // 保存按钮
@property (nonatomic, strong) UIBarButtonItem *previewBarButtonItem; // 预览按钮
@property (nonatomic, strong) UIBarButtonItem *optionsBarButtonItem; // 配置按钮

@property (nonatomic, strong) UIActionSheet* actionSheet;

@property (nonatomic) BOOL isMarkdown;

@property (nonatomic) BOOL edited;
@property (nonatomic) BOOL isClosed;

@property BOOL isInited;

@end;

@implementation NoteViewController

@synthesize textView = _textView;  // 为什么要有?
@synthesize note = _note;


// 将要结束编辑, 保存笔记
// force, 强制保存, 不管title, content有没有变化
- (BOOL)saveNote:(BOOL)force
{
    NSString *title = [Common trimNewLine:[self titleText]];
    NSString *content = [self bodyText];
    
    // 更新笔记
    if(self.note != nil) {
        if(self.edited) {
            BOOL contentIsDirty = ![self.note.content isEqualToString:content];
            BOOL titleIsDirty = ![self.note.title isEqualToString:title];
            if(contentIsDirty || titleIsDirty)
            {
                [Leas.note updateNote:self.note title:title content:content];
            }
            else {
                NSLog(@" not need UPDATE");
                return NO;
            }
        }
        else {
            NSLog(@" not need UPDATE readonly");
            return NO;
        }
        
        // 新建一个笔记
    } else {
        if(force || (![Common isBlankString:title] || ![Common isBlankString:content])) {
            NSLog(@"add note");
            
            self.note = [Leas.note addNote:title content:content
                                  notebook:self.notebook tag:self.tag];
        }
    }
    
    return YES;
}


#pragma mark - Setter

// Master View调用
- (void)setNote:(Note *)note
{
    if (_note != note)
    {
        _note = note;
        // Update the view.
        // [self configureView];
    }
}

- (void)viewDidLoad
{
    self.isMarkdown = NO;
    if(self.note) {
        self.isMarkdown = [self.note.isMarkdown boolValue];
    }
    // 表示是新增, hide status bar
    else {
        self.isMarkdown = ![UserService isNormalEditor];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        // kWPEditorViewControllerModeEdit
    }
    [super initWithMode:kWPEditorViewControllerModePreview isMarkdown:self.isMarkdown];
    
    [super viewDidLoad];
    
    self.delegate = self;
    
    [self restoreBarStyle];
    
    // 按钮初始化
    [self initNavigationBarRightButtons];
}

// 这里, 有大问题, 如果是新建的
// 图片pick消失后还是会执行这个, 会startEditing, 会focus title
- (void)viewDidAppear:(BOOL)animated
{
    // 必须要, 不然插入图片会找不到selection问题
    [super viewDidAppear:animated];
    
    // 当都显示完后, 才开始编辑, 显示键盘
    if(!self.note && !self.isInited) {
        [self startEditing];
        [self enableRightButtons];
    }
    
    // 确保只执行一次
    // 放这里, 为了速度快
    if(!self.isInited) {
        self.mediaAdded = [NSMutableDictionary dictionary];
        self.videoPressCache = [[NSCache alloc] init];
        
        // 样式缓存
        DisabledButtonBarStyle = @{NSFontAttributeName: [WPStyleGuide regularTextFontSemiBold], NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.25]};
        EnabledButtonBarStyle = @{NSFontAttributeName: [WPStyleGuide regularTextFontSemiBold], NSForegroundColorAttributeName: [UIColor whiteColor]};
    }
    
    self.isInited = YES;
}

// 消失后再save, 笔记内容会消失吗?
-(void) viewWillDisappear:(BOOL)animated {
    // 是从本view消息的
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.
        
        NSLog(@"pop");
        
        [self saveNote:NO];
        
        [Leas.note pushNoteAndWrite:self.note success:^{
            // tips 提示同步成功
            [self showSuccessMsg:NSLocalizedString(@"Synchronize note successful", @"")];
        } fail:^(id ret) {
            [self showErrorMsg:NSLocalizedString(@"Synchronize note failed", @"") ret:ret];
        }];
    }
    
    // 一直在loading 内容
    [self hideProgress];
    self.isClosed = YES;
    [super viewWillDisappear:animated];
}

// 当笔记内容load后才enable
- (void) enableRightButtons
{
    self.saveBarButtonItem.enabled = YES;
    self.optionsBarButtonItem.enabled = YES;
}

- (void)initNavigationBarRightButtons
{
    NSArray* rightBarButtons = @[
                                 [self saveBarButtonItem],
                                 [self optionsBarButtonItem],
                                 ];
    // 初始时disable
    self.saveBarButtonItem.enabled = NO;
    self.optionsBarButtonItem.enabled = NO;
    
    [self.navigationItem setRightBarButtonItems:rightBarButtons animated:YES];
}

# pragma mark - Custom UI elements

// 保存之后 -> 只读状态
- (void)refreshNavigationBarRightButtons:(BOOL)editingChanged
{
    if ([self isEditing]) {
        self.edited = YES;
        self.saveBarButtonItem.title = NSLocalizedString(@"Save", @"");
    } else {
        self.saveBarButtonItem.title = NSLocalizedString(@"Edit", @"");
        if (!self.saveBarButtonItem.enabled) {
            self.saveBarButtonItem.enabled = YES;
        }
    }
}

// 生成按钮通用方法
- (LeaButtonForNavigationBar*)buttonForBarWithImageNamed:(NSString*)imageName
                                                   frame:(CGRect)frame
                                                  target:(id)target
                                                selector:(SEL)selector
{
    NSAssert([imageName isKindOfClass:[NSString class]],
             @"Expected imageName to be a non nil string.");
    
    UIImage* image = [UIImage imageNamed:imageName];
    
    LeaButtonForNavigationBar* button = [[LeaButtonForNavigationBar alloc] initWithFrame:frame];
    
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

// 配置按钮
- (UIBarButtonItem *)optionsBarButtonItem
{
    if (!_optionsBarButtonItem) {
        LeaButtonForNavigationBar *button = [self buttonForBarWithImageNamed:@"icon-posts-editor-options"
                                                                       frame:NavigationBarButtonRect
                                                                      target:self
                                                                    selector:@selector(showSettings)];
        
        button.removeDefaultRightSpacing = YES;
        button.rightSpacing = SpacingBetweeenNavbarButtons / 2.0f;
        button.removeDefaultLeftSpacing = YES;
        button.leftSpacing = SpacingBetweeenNavbarButtons / 2.0f;
        NSString *optionsTitle = NSLocalizedString(@"Options", @"Title of the Post Settings navigation button in the Post Editor. Tapping shows settings and options related to the post being edited.");
        button.accessibilityLabel = optionsTitle;
        button.accessibilityIdentifier = @"Options";
        _optionsBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    
    return _optionsBarButtonItem;
}

// 编辑/完成按钮
- (UIBarButtonItem *)saveBarButtonItem
{
    if (!_saveBarButtonItem) {
        NSString *buttonTitle = NSLocalizedString(@"Edit", @"");
        
        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:buttonTitle
                                                                       style:[WPStyleGuide barButtonStyleForDone]
                                                                      target:self
                                                                      action:@selector(editTouchedUpInside)];
        
        // Seems to be an issue witht the appearance proxy not being respected, so resetting these here
        [saveButton setTitleTextAttributes:EnabledButtonBarStyle forState:UIControlStateNormal];
        [saveButton setTitleTextAttributes:DisabledButtonBarStyle forState:UIControlStateDisabled];
        _saveBarButtonItem = saveButton;
    }
    
    return _saveBarButtonItem;
}

#pragma mark - Navigation Bar

// 不加 不能隐藏状态栏
BOOL hiddenBar = NO;
//- (BOOL)prefersStatusBarHidden
//{
//	return hiddenBar;
//}

- (void)editTouchedUpInside
{
    // isEditting, stopEditing是继承过来的
    if (self.isEditing) {
        [self stopEditing];
        hiddenBar = NO;
    } else {
        [self startEditing];
        hiddenBar = YES;
    }
    
    //	[self prefersStatusBarHidden];
    //	[self setNeedsStatusBarAppearanceUpdate];
    
    [[UIApplication sharedApplication] setStatusBarHidden:hiddenBar withAnimation:UIStatusBarAnimationSlide];
    
    [self refreshNavigationBarRightButtons:YES];
}

// 显示配置
- (void)showSettings
{
    [self saveNote:YES];
    NoteSettingsTableViewController *vc = [[[NoteSettingsTableViewController class] alloc] initWithNote:self.note shouldHideStatusBar:YES];
    
    vc.hidesBottomBarWhenPushed = YES;
    
    [self.editorView saveSelection];
    
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [self.editorView saveSelection];
    [super prepareForSegue:segue sender:sender];
}

#pragma mark - IBActions

- (IBAction)exit:(UIStoryboardSegue*)segue
{
}

// 编辑方法
#pragma mark - WPEditorViewControllerDelegate

- (void)editorDidBeginEditing:(WPEditorViewController *)editorController
{
    //	DDLogInfo(@"Editor did begin editing.");
    [self refreshNavigationBarRightButtons:YES];
}

- (void)editorDidEndEditing:(WPEditorViewController *)editorController
{
    //	DDLogInfo(@"Editor did end editing.");
    //	DDLogInfo(self.bodyText);
    [self saveNote:NO];
}

// 编辑器加载后设置内容
- (void)editorDidFinishLoadingDOM:(WPEditorViewController *)editorController
{
    // NSString *path = [[NSBundle mainBundle] pathForResource:@"content" ofType:@"html"];
    // NSString *htmlParam = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    //	self.titleText = self.note.title;
    //	self.bodyText = self.note.content;
    
    if(self.note) {
        [self setTitleText:self.note.title];
        
        [self showProgress];
        
        [Leas.note getNoteContent:self.note success:^(NSString * content) {
            // 如果已经不在本页了 不要设置
            if(self.isClosed) {
                return;
            }
            [self setBodyText:content];
            [self enableRightButtons];
            [self hideProgress];
        } fail:^{
            // 如果已经不在本页了, 不要alert
            if(self.isClosed) {
                return;
            }
            [self hideProgress];
            
            [LeaAlert showAlertWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Cannot fetch note's content", nil) withSupportButton:NO okPressedBlock:^() {
                if(self.isClosed) {
                    return;
                }
                // 返回
                // 这里, 可能已不是本页
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }];
    }
}

- (BOOL)editorShouldDisplaySourceView:(WPEditorViewController *)editorController
{
    [self.editorView pauseAllVideos];
    return YES;
}

- (void)editorDidPressMedia:(WPEditorViewController *)editorController
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"添加照片" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"从相册选择",@"拍照", nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
            //取消
            break;
        case 1:
            //相册
            [self showPhotoPicker];
            break;
        case 2:
            //拍照
            [self takePhoto];
            break;
        default:
            break;
    }
}


- (void)editorTitleDidChange:(WPEditorViewController *)editorController
{
    //	DDLogInfo(@"Editor title did change: %@", self.titleText);
}

- (void)editorTextDidChange:(WPEditorViewController *)editorController
{
    //	DDLogInfo(@"Editor body text changed: %@", self.bodyText);
}

- (void)editorViewController:(WPEditorViewController *)editorViewController fieldCreated:(WPEditorField*)field
{
    //	DDLogInfo(@"Editor field created: %@", field.nodeId);
}

// 点击图片时的操作
// 怎么让图片不可点?
- (void)editorViewController:(WPEditorViewController*)editorViewController
                 imageTapped:(NSString *)imageId
                         url:(NSURL *)url
                   imageMeta:(WPImageMeta *)imageMeta
{
    // 1表示是editable的, 0表示不可editable
    if ([imageId isEqualToString:@"1"]) {
        // [self showImageDetailsForImageMeta:imageMeta];
    } else {
        [self showActionTapImage:[url absoluteString]];
    }
}

// 非编辑模式下点击链接
- (void)editorViewController:(WPEditorViewController*)editorViewController
                  linkTapped:(NSString *)url
{
    LeaWebViewController *webViewController = [[LeaWebViewController alloc] init];
    webViewController.url = [NSURL URLWithString:url];
    //	[self.navigationController pushViewController:webViewController animated:YES];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)editorViewController:(WPEditorViewController*)editorViewController
                 videoTapped:(NSString *)videoId
                         url:(NSURL *)url
{
    [self showPromptForVideoWithID:videoId];
}

- (void)editorViewController:(WPEditorViewController *)editorViewController imageReplaced:(NSString *)imageId
{
    [self.mediaAdded removeObjectForKey:imageId];
}

- (void)editorViewController:(WPEditorViewController *)editorViewController videoReplaced:(NSString *)videoId
{
    [self.mediaAdded removeObjectForKey:videoId];
}

- (void)editorViewController:(WPEditorViewController *)editorViewController videoPressInfoRequest:(NSString *)videoID
{
    NSDictionary * videoPressInfo = [self.videoPressCache objectForKey:videoID];
    NSString * videoURL = videoPressInfo[@"source"];
    NSString * posterURL = videoPressInfo[@"poster"];
    if (videoURL) {
        [self.editorView setVideoPress:videoID source:videoURL poster:posterURL];
    }
}

- (void)editorViewController:(WPEditorViewController *)editorViewController mediaRemoved:(NSString *)mediaID
{
    NSProgress * progress = self.mediaAdded[mediaID];
    [progress cancel];
}

#pragma mark - Media actions

// 查看图片的详细信息
/*
 - (void)showImageDetailsForImageMeta:(WPImageMeta *)imageMeta
 {
	return;
	
	WPImageMetaViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WPImageMetaViewController"];
	controller.imageMeta = imageMeta;
	controller.delegate = self;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
	[self.navigationController presentViewController:navController animated:YES completion:nil];
 }
 */

// image gallery
- (void)showActionTapImage:(NSString *)url
{
    NSArray *urlArr = [url componentsSeparatedByString:@"L$L"]; // 以'L$L'分隔, 最后一个是当前url
    
    // 最后一个是当前位置
    int curUrlIndex = [[urlArr lastObject] intValue];
    
    NSMutableArray *realUrls = [[NSMutableArray alloc] init];
    
    // fix url, 整理出可以显示的图片
    for(int i = 0; i < [urlArr count] - 1; ++i) {
        NSString *each = urlArr[i];
        
        // 只要是图片, 都行, 因为有些图片是没有.png后缀的
        //		NSString *fileId = [Common getFileIdFromUrl:each];
        //		if(fileId || [LeaImageViewController isUrlSupported:[NSURL URLWithString:each]]) {
        [realUrls addObject:each];
        //		}
    }
    
    // 得到当前的url
    NSUInteger count = [realUrls count];
    if(count < 1) {
        return;
    }
    if (curUrlIndex > count) {
        curUrlIndex = 0;
    }
    
    /*
     int curIndex = 0;
     // 如果有多张图片是一样的url呢?
     NSString *curUrl = realUrls[0];
     for(int i = 0; i < count; ++i) {
     NSString *each = realUrls[i];
     if([each isEqualToString:curUrlStr]) {
     curUrl = each;
     curIndex = i;
     break;
     }
     }
     */
    
    LeaImageSliderViewController *vc2 = [[LeaImageSliderViewController alloc] init];
    vc2.curUrl = realUrls[curUrlIndex];
    [vc2 setUrlArr:realUrls];
    vc2.curIndex = curUrlIndex;
    vc2.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    vc2.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc2 animated:YES completion:nil];
    
    return;
    
    NSString *fileId = [Common getFileIdFromUrl:url];
    if (!fileId) {
        //		return;
    }
    //	self.selectedMediaID = fileId;
    /*
     // 表示已经有了
     if(self.actionSheet) {
     return;
     }
     UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Save Image", nil), nil];
     [actionSheet showInView:self.view];
     actionSheet.tag = WPViewControllerActionSheetImageUploadRetry;
     self.actionSheet = actionSheet;
     */
    
    NSURL *urlU = [NSURL URLWithString:url];
    UIViewController *controller = nil;
    BOOL isSupportedNatively = [LeaImageViewController isUrlSupported:urlU];
    
    UIImage *img;
    if(fileId) {
        NSString *absPath = [FileService getFileAbsPathByFileIdOrServerFileId:fileId];
        img = [[UIImage alloc] initWithContentsOfFile:absPath];
    }
    if (isSupportedNatively) {
        controller = [[LeaImageViewController alloc] initWithImage:img andURL:urlU];
    }
    /*
     else if (imageControl.linkURL) {
     LeaWebViewController *webViewController = [LeaWebViewController webViewControllerWithURL:imageControl.linkURL];
     controller = [[UINavigationController alloc] initWithRootViewController:webViewController];
     }*/
    else {
        controller = [[LeaImageViewController alloc] initWithImage:img];
    }
    
    if ([controller isKindOfClass:[LeaImageViewController class]]) {
        controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        controller.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    //	LeaImagePagerViewController *vc = [[LeaImagePagerViewController alloc] init];
    LeaImageSliderViewController *vc = [[LeaImageSliderViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showPromptForVideoWithID:(NSString *)videoId
{
    if (videoId.length == 0){
        return;
    }
    NSProgress *progress = self.mediaAdded[videoId];
    if (!progress.cancelled){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Stop Upload" otherButtonTitles:nil];
        [actionSheet showInView:self.view];
        actionSheet.tag = WPViewControllerActionSheetVideoUploadStop;
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove Video" otherButtonTitles:@"Retry Upload", nil];
        [actionSheet showInView:self.view];
        actionSheet.tag = WPViewControllerActionSheetVideoUploadRetry;
    }
    self.selectedMediaID = videoId;
}

// 选择图片
- (void)showPhotoPicker
{
    [self.editorView saveSelection];
    QBImagePickerController *imagePickerController = [QBImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.allowsMultipleSelection = YES;
    imagePickerController.maximumNumberOfSelection = 6;
    imagePickerController.showsNumberOfSelectedAssets = YES;
    imagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:imagePickerController animated:YES completion:NULL];
    
    /*
     
     CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
     picker.delegate = self;
     
     UIBarButtonItem *barButtonItem = [UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], [CTAssetsPickerController class], nil];
     [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
     [barButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateDisabled];
     
     // Only show photos for now (not videos)
     picker.assetsFilter = [ALAssetsFilter allPhotos];
     
     [self presentViewController:picker animated:YES completion:nil];
     picker.childNavigationController.navigationBar.translucent = NO;
     */
    
    /*
     
     UIImagePickerController *picker = [[UIImagePickerController alloc] init];
     picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
     picker.delegate = self;
     picker.allowsEditing = NO;
     picker.navigationBar.translucent = NO;
     picker.modalPresentationStyle = UIModalPresentationCurrentContext;
     picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
     [self.navigationController presentViewController:picker animated:YES completion:nil];
     
     */
}

#pragma mark - WPMediaPickerViewControllerDelegate
-(void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAsset:(ALAsset *)asset{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self addMediaAssets:@[asset]];
}

-(void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAssets:(NSArray *)assets{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self addMediaAssets:assets];
}
-(void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController{
    [self dismissViewControllerAnimated:YES completion:nil];
}


/*
 #pragma mark - CTAssetsPickerControllerDelegate
 
 - (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
 {
	[self dismissViewControllerAnimated:YES completion:^{
 [self addMediaAssets:assets];
	}];
 }
 
 - (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
 {
	if ([asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
 // If the image is from a shared photo stream it may not be available locally to be used
 if (!asset.defaultRepresentation) {
 [LeaAlert showAlertWithTitle:NSLocalizedString(@"Image unavailable", @"The title for an alert that says the image the user selected isn't available.")
 message:NSLocalizedString(@"This Photo Stream image cannot be added to note. Try saving it to your Camera Roll before.", @"User information explaining that the image is not available locally. This is normally related to share photo stream images.")  withSupportButton:NO];
 return NO;
 }
 if (picker.selectedAssets.count >= MaximumNumberOfPictures) {
 [LeaAlert showAlertWithTitle:nil
 message:[NSString stringWithFormat:NSLocalizedString(@"You can only add %i photos at a time.", @"User information explaining that you can only select an x number of images."), MaximumNumberOfPictures] withSupportButton:NO];
 return NO;
 }
 return YES;
	} else {
 return NO;
	}
 }
 */

- (NSString *) getImageUrl:(NSString *) fileId
{
    return [NSString stringWithFormat:@"leanote://getImage?fileId=%@", fileId];
}
- (void)addMediaAssets:(NSArray *)assets
{
    NSString *urls = @"[";
    for (ALAsset *asset in assets) {
        NSString *fileId = [self addImageAssetToContent:asset];
        urls = [NSString stringWithFormat:@"%@'%@',", urls, [self getImageUrl:fileId]];
    }
    urls = [NSString stringWithFormat:@"%@]", urls];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.editorView insertImage:urls alt:@""];
    });
}

// 添加图片到内容中
- (NSString *)addImageAssetToContent:(ALAsset *)asset
{
    UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
    NSData *data = UIImageJPEGRepresentation(image, 0.7);
    NSString *imageID = [Common newObjectId];
    
    NSString *relativePath = [NSString stringWithFormat:@"%@/%@.jpg", @"images", imageID];
    
    // 图片写到doc/images目录下
    NSString *path = [NSString stringWithFormat:@"%@/%@", [Common getDocPath], relativePath];
    [data writeToFile:path atomically:YES];
    
    // 一条本地记录
    File *file = [FileService addLocalFile:relativePath];
    
    return file.fileId;
}

// 视频, 不允许!!
/*
 - (void)addVideoAssetToContent:(ALAsset *)originalAsset
 {
 UIImage *image = [UIImage imageWithCGImage:originalAsset.defaultRepresentation.fullScreenImage];
 NSData *data = UIImageJPEGRepresentation(image, 0.7);
 NSString *posterImagePath = [NSString stringWithFormat:@"%@/%@.jpg", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString]];
 [data writeToFile:posterImagePath atomically:YES];
 NSString *videoID = [[NSUUID UUID] UUIDString];
 [self.editorView insertInProgressVideoWithID:videoID
 usingPosterImage:[[NSURL fileURLWithPath:posterImagePath] absoluteString]];
 ALAssetRepresentation *representation = originalAsset.defaultRepresentation;
 AVAsset *asset = [AVURLAsset URLAssetWithURL:representation.url options:nil];
 NSString *videoPath = [NSString stringWithFormat:@"%@%@.mov", NSTemporaryDirectory(), videoID];
 NSString *presetName = AVAssetExportPresetPassthrough;
 AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:presetName];
 session.outputFileType = representation.UTI;
 session.shouldOptimizeForNetworkUse = YES;
 session.outputURL = [NSURL fileURLWithPath:videoPath];
 [session exportAsynchronouslyWithCompletionHandler:^{
 if (session.status != AVAssetExportSessionStatusCompleted) {
 return;
 }
 dispatch_async(dispatch_get_main_queue(), ^{
 NSProgress *progress = [[NSProgress alloc] initWithParent:nil
 userInfo:@{@"videoID": videoID, @"url": videoPath, @"poster": posterImagePath }];
 progress.cancellable = YES;
 progress.totalUnitCount = 100;
 [NSTimer scheduledTimerWithTimeInterval:0.1
 target:self
 selector:@selector(timerFireMethod:)
 userInfo:progress
 repeats:YES];
 self.mediaAdded[videoID] = progress;
 });
 }];
 }
 */


- (void)timerFireMethod:(NSTimer *)timer
{
    NSProgress *progress = (NSProgress *)timer.userInfo;
    progress.completedUnitCount++;
    NSString *imageID = progress.userInfo[@"imageID"];
    if (imageID) {
        [self.editorView setProgress:progress.fractionCompleted onImage:imageID];
        // Uncomment this code if you need to test a failed image upload
        //    if (progress.fractionCompleted >= 0.15){
        //        [progress cancel];
        //        [self.editorView markImage:imageID failedUploadWithMessage:@"Failed"];
        //        [timer invalidate];
        //    }
        if (progress.fractionCompleted >= 1) {
            [self.editorView replaceLocalImageWithRemoteImage:[[NSURL fileURLWithPath:progress.userInfo[@"url"]] absoluteString] uniqueId:imageID];
            [timer invalidate];
        }
        return;
    }
    
    return;
    // 以下是视频
    
    NSString *videoID = progress.userInfo[@"videoID"];
    if (videoID) {
        [self.editorView setProgress:progress.fractionCompleted onVideo:videoID];
        // Uncomment this code if you need to test a failed video upload
        //        if (progress.fractionCompleted >= 0.15) {
        //            [progress cancel];
        //            [self.editorView markVideo:videoID failedUploadWithMessage:@"Failed"];
        //            [timer invalidate];
        //        }
        if (progress.fractionCompleted >= 1) {
            NSString * videoURL = [[NSURL fileURLWithPath:progress.userInfo[@"url"]] absoluteString];
            NSString * posterURL = [[NSURL fileURLWithPath:progress.userInfo[@"poster"]] absoluteString];
            [self.editorView replaceLocalVideoWithID:videoID
                                      forRemoteVideo:videoURL
                                        remotePoster:posterURL
                                          videoPress:videoID];
            [self.videoPressCache setObject:@ {@"source":videoURL, @"poster":posterURL} forKey:videoID];
            [timer invalidate];
        }
        return;
    }
}

// 选择图片代理
#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if ([info[UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeImage]) {
            UIImage *theImage = info[UIImagePickerControllerOriginalImage];
            // 保存图片到相册中
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
            [library writeImageToSavedPhotosAlbum:theImage.CGImage metadata:info[UIImagePickerControllerMediaMetadata] completionBlock:^(NSURL *assetURL, NSError *error) {
                //添加
                [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                    [self addMediaAssets:@[asset]];
                } failureBlock:nil];
            }];
        }
    }];
}

// 点击工具栏
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.actionSheet = nil;
    
    if (actionSheet.tag == WPViewControllerActionSheetImageUploadStop){
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self.editorView removeImage:self.selectedMediaID];
        }
        
        // 下载图片
    } else if (actionSheet.tag == WPViewControllerActionSheetImageUploadRetry){
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            //			[self.editorView removeImage:self.selectedMediaID];
        }
        else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            NSString *absPath = [FileService getFileAbsPathByFileIdOrServerFileId:self.selectedMediaID];
            if(!absPath) {
                [self showErrorMsg:NSLocalizedString(@"Save image failed", nil) ret:nil];
                return;
            }
            UIImage *image = [UIImage imageWithContentsOfFile:absPath];
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil,nil);
            
            [self showSuccessMsg:NSLocalizedString(@"Save image successful", nil)];
        }
        
    } else if (actionSheet.tag == WPViewControllerActionSheetVideoUploadStop){
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self.editorView removeVideo:self.selectedMediaID];
        }
    } else if (actionSheet.tag == WPViewControllerActionSheetVideoUploadRetry){
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self.editorView removeVideo:self.selectedMediaID];
        } else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            NSProgress * progress = [[NSProgress alloc] initWithParent:nil userInfo:@{@"videoID":self.selectedMediaID}];
            progress.totalUnitCount = 100;
            [NSTimer scheduledTimerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(timerFireMethod:)
                                           userInfo:progress
                                            repeats:YES];
            self.mediaAdded[self.selectedMediaID] = progress;
            [self.editorView unmarkVideoFailedUpload:self.selectedMediaID];
        }
    }
    
}

-(void)takePhoto{
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self showPhotoPicker];
    }else{
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];//初始化
        picker.delegate = self;
        picker.allowsEditing = NO;//设置可编辑
        [picker setSourceType:sourceType];
        [self presentViewController:picker animated:YES completion:nil];//进入照相界面
    }
}


@end
