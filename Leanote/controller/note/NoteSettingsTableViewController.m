//
//  NoteSettingsTableViewController.m
//  Leanote
//
//  Created by life on 15/6/2.

#import "NoteSettingsTableViewController.h"
#import "NotebookService.h"
#import "NoteService.h"
#import "NotebookController.h"
#import "Note.h"

#import "Leas.h"

#import "LeaButtonForNavigationBar.h"
#import <WordPress-iOS-Shared/UIImage+Util.h>
#import <WordPress-iOS-Shared/WPFontManager.h>
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPress-iOS-Shared/WPTableViewCell.h>
#import <WordPress-iOS-Shared/UITableViewTextFieldCell.h>

typedef enum {
	PostSettingsSectionTaxonomy = 0,
	PostSettingsSectionMeta,
	PostSettingsSectionFormat,
	PostSettingsSectionFeaturedImage,
	PostSettingsSectionGeolocation
} PostSettingsSection;

typedef enum {
	PostSettingsRowCategories = 0,
	PostSettingsRowTags,
	PostSettingsRowPublishDate,
	PostSettingsRowStatus,
	PostSettingsRowVisibility,
	PostSettingsRowPassword,
	PostSettingsRowFormat,
	PostSettingsRowFeaturedImage,
	PostSettingsRowFeaturedImageAdd,
	PostSettingsRowFeaturedLoading,
	PostSettingsRowGeolocationAdd,
	PostSettingsRowGeolocationMap
} PostSettingsRow;


@interface NoteSettingsTableViewController ()<UITextFieldDelegate>

@property (nonatomic, assign) BOOL preIsBlog;

@property (nonatomic, assign) BOOL shouldHideStatusBar;
@property (nonatomic, strong) NSMutableArray *sections;

@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *tagsTextField;
@property (nonatomic, strong) NSArray *statusList;
@property (nonatomic, strong) NSArray *visibilityList;
@property (nonatomic, strong) NSArray *formatsList;

@property (nonatomic, strong) UILabel *notebookLabel;

@property (assign) BOOL *textFieldDidHaveFocusBeforeOrientationChange;

@end

@implementation NoteSettingsTableViewController

- (instancetype)initWithNote:(Note *)note shouldHideStatusBar:(BOOL)shouldHideStatusBar
{
	self = [super initWithStyle:UITableViewStyleGrouped];
	if (self) {
		self.note = note;
		self.preIsBlog = [note.isBlog boolValue]; // 之前是否是博客
		_shouldHideStatusBar = shouldHideStatusBar;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Options", nil);
	
	[WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
	
	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 44.0)]; // add some vertical padding
	
	// Compensate for the first section's height of 1.0f
	self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0, 0, 0);
	self.tableView.accessibilityIdentifier = @"SettingsTable";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 当消失后, 更新下笔记isBlog
// 为了使view看起来流畅
- (void)viewDidDisappear:(BOOL)animated
{
	if(self.preIsBlog != [self.note.isBlog boolValue]) {
		[Leas.note updateNote:self.note forNotebook:NO forBlog:YES forTags:NO tags:nil];
	}
	
	// tags
	NSString *tags = self.tagsTextField.text;
	if(![tags isEqualToString:self.note.tags]) {
		// 异步
//		[Common async:^{
			[Leas.note updateNote:self.note forNotebook:NO forBlog:NO forTags:YES tags:self.tagsTextField.text];
//		}];
	}
}

#pragma mark - Table view data source

- (void)configureSections
{
	self.sections = [NSMutableArray array];
	[self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionTaxonomy]];
	[self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionMeta]];
}

// 多少个section
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (!self.sections) {
		[self configureSections];
	}
	return [self.sections count];
}

// 每个section多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
	if (sec == PostSettingsSectionTaxonomy) {
		return 2;
	} else if (sec == PostSettingsSectionMeta) {
		return 1;
	}
	return 0;
}

// section title
- (NSString *)titleForHeaderInSection:(NSInteger)section
{
	/*
	NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
	if (sec == PostSettingsSectionTaxonomy) {
		return NSLocalizedString(@"Taxonomy", @"Label for the Taxonomy area (categories, keywords, ...) in post settings.");
		
	} else if (sec == PostSettingsSectionMeta) {
		return NSLocalizedString(@"Publish", @"The grandiose Publish button in the Post Editor! Should use the same translation as core WP.");
		
	}
	*/
	return @"";
}

// 配置每一行
- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger sec = [[self.sections objectAtIndex:indexPath.section] integerValue];
	
	UITableViewCell *cell;
	
	if (sec == PostSettingsSectionTaxonomy) {
		cell = [self configureTaxonomyCellForIndexPath:indexPath];
	} else if (sec == PostSettingsSectionMeta) {
		cell = [self configureMetaPostMetaCellForIndexPath:indexPath];
	}
	
	return cell;
}

// 分类和标签组
- (UITableViewCell *)configureTaxonomyCellForIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	if (indexPath.row == PostSettingsRowCategories) {
		// Categories
		cell = [self getWPTableViewCell];
		cell.textLabel.text = NSLocalizedString(@"Notebook", nil);
		cell.detailTextLabel.text = [Leas.notebook getNotebookTitleByNotebookId:self.note.notebookId];
		cell.tag = PostSettingsRowCategories;
		cell.accessibilityIdentifier = @"Notebook";
		
		self.notebookLabel = cell.detailTextLabel;
		
	} else if (indexPath.row == PostSettingsRowTags) {
		// Tags, 标签啊, 逗号分隔
		UITableViewTextFieldCell *textCell = [self getTextFieldCell];
		textCell.textLabel.text = NSLocalizedString(@"Tags", nil);
		textCell.textField.text = self.note.tags;
		textCell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"Comma separated", nil)) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
		textCell.textField.secureTextEntry = NO;
		textCell.textField.clearButtonMode = UITextFieldViewModeNever;
		textCell.textField.accessibilityIdentifier = @"Tags Value";
		cell = textCell;
		cell.tag = PostSettingsRowTags;
		
		self.tagsTextField = textCell.textField;
	}
	
	return cell;
}


// 文章元数据, 包含: 发布日期, 状态(发布和草稿), 是否可见(公开, 密码查看, 私有)
- (UITableViewCell *)configureMetaPostMetaCellForIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	if (indexPath.row == 0) {
		// Visibility
		cell = [self getWPTableViewCell];
		cell.textLabel.text = NSLocalizedString(@"Public to blog", nil);
		cell.tag = PostSettingsRowVisibility;
		cell.accessibilityIdentifier = @"Public";
		
		UISwitch *sw = [[UISwitch alloc]init];
		[sw addTarget:self action:@selector(switchValueChange:) forControlEvents:UIControlEventValueChanged];
		sw.on = [self.note.isBlog boolValue];
		cell.accessoryView = sw;
		
	}
	return cell;
}

// 保存
- (void)switchValueChange:(id)sender
{
	UISwitch *switchButton = (UISwitch*)sender;
	BOOL isButtonOn = [switchButton isOn];
	
	self.note.isBlog = isButtonOn ? M_YES : M_NO;
//	NSLog(isButtonOn ? @"YES" : @"NO");
	
	// [self showUnsavedChangesAlert];
	
	// [self actionSheet];
}

// cell

- (WPTableViewCell *)getWPTableViewCell
{
	static NSString *wpTableViewCellIdentifier = @"wpTableViewCellIdentifier";
	WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:wpTableViewCellIdentifier];
	if (!cell) {
		cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:wpTableViewCellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		[WPStyleGuide configureTableViewCell:cell];
	}
	cell.tag = 0;
	return cell;
}

// 含文本输入框的cell
- (UITableViewTextFieldCell *)getTextFieldCell
{
	static NSString *textFieldCellIdentifier = @"textFieldCellIdentifier";
	UITableViewTextFieldCell *cell = [self.tableView dequeueReusableCellWithIdentifier:textFieldCellIdentifier];
	if (!cell) {
		cell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:textFieldCellIdentifier];
		cell.textField.returnKeyType = UIReturnKeyDone;
		cell.textField.delegate = self;
		[WPStyleGuide configureTableViewTextCell:cell];
		cell.textField.textAlignment = NSTextAlignmentRight;
	}
	cell.tag = 0;
	return cell;
}

// 选择某一行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	
	// 配置每一行? 为什么?
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	// 然后, 触发动作
	if (cell.tag == PostSettingsRowCategories) {
		[self showNotebookSelection];
	}
}

// 跳转到
- (void)showNotebookSelection
{
	NSString *storyboardName = @"MainStoryboard_iPhone";
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
	NotebookController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Notebook"];

	[vc initWithNote:self.note fromSetting:YES setSettingNotebook:^(Notebook *notebook) {
		self.notebookLabel.text = notebook.title;

		// 然后异步去保存之
//		[Common async:^{
			[Leas.note updateNoteNotebook:self.note notebook:notebook];
//		}];
	}];
	
	vc.hidesBottomBarWhenPushed = YES;

	// 设置返回按钮
	UIBarButtonItem *newBackButton =
	[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Options", nil)
									 style:UIBarButtonItemStyleBordered
									target:nil
									action:nil];
	[[self navigationItem] setBackBarButtonItem:newBackButton];
	
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TextField Delegate Methods 标签

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	if (self.textFieldDidHaveFocusBeforeOrientationChange) {
		self.textFieldDidHaveFocusBeforeOrientationChange = NO;
		return NO;
	}
	return YES;
}

// tag, 保存
- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == self.tagsTextField) {
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
	replacementString:(NSString *)string
{
	if (textField == self.tagsTextField) {
		//self.note.tags = [self.tagsTextField.text stringByReplacingCharactersInRange:range withString:string];
	}
	return YES;
}

@end
