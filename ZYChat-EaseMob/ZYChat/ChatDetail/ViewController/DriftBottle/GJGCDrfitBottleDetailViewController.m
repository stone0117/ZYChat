//
//  GJGCDrfitBottleDetailViewController.m
//  ZYChat
//
//  Created by ZYVincent QQ:1003081775 on 15/7/1.
//  Copyright (c) 2015年 ZYProSoft.  QQ群:219357847  All rights reserved.
//

#import "GJGCDrfitBottleDetailViewController.h"
#import "GJGCDriftBottleImageScrollView.h"
#import "GJGCProgressView.h"
#import "GJCFFileDownloadManager.h"

@interface GJGCDrfitBottleDetailViewController ()<UIActionSheetDelegate>

@property (nonatomic,strong)GJGCDriftBottleImageScrollView *imageScrollView;

@property (nonatomic,strong)GJCFCoreTextContentView *contentLabel;

@property (nonatomic,strong)NSString *imageUrl;

@property (nonatomic,strong)NSString *contentString;

@property (nonatomic,strong)UIImage *thumbImage;

@property (nonatomic,strong)GJGCProgressView *progressView;

@end

@implementation GJGCDrfitBottleDetailViewController

- (instancetype)initWithThumbImage:(UIImage *)aImage withImageUrl:(NSString *)aImageUrl withContentString:(NSString *)aString
{
    if (self = [super init]) {
        
        self.imageUrl = aImageUrl;
        
        self.contentString = aString;
        
        self.thumbImage = aImage;
    }
    return self;
}

- (void)dealloc
{
    [[GJCFFileDownloadManager shareDownloadManager] clearTaskBlockForObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setStrNavTitle:@"漂流瓶详情"];
    
    [self setRightButtonWithTitle:@"更多"];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self.navigationController.navigationBar setBackgroundImage:GJCFQuickImageByColorWithSize(GJCFQuickHexColor(@"000000"), CGSizeMake(GJCFSystemScreenWidth, 64)) forBarMetrics:UIBarMetricsDefault];
    
    [self setupSubViews];
    
    [self initImageDownloadConfig];
    
    [self startDownloadBigImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar setBackgroundImage:GJCFQuickImageByColorWithSize([GJGCCommonFontColorStyle mainThemeColor], CGSizeMake(GJCFSystemScreenWidth, 64)) forBarMetrics:UIBarMetricsDefault];
}

- (void)setupSubViews
{
    self.imageScrollView = [[GJGCDriftBottleImageScrollView alloc]init];
    self.imageScrollView.backgroundColor = [UIColor clearColor];
    self.imageScrollView.gjcf_width = GJCFSystemScreenWidth;
    self.imageScrollView.gjcf_height = self.imageScrollView.gjcf_width;
    [self.view addSubview:self.imageScrollView];
    [self.imageScrollView setNeedShowImage:self.thumbImage];

    self.contentLabel = [[GJCFCoreTextContentView alloc]init];
    self.contentLabel.gjcf_size = CGSizeMake(10, 10);
    self.contentLabel.gjcf_top = self.imageScrollView.gjcf_bottom + 12.f;
    self.contentLabel.contentBaseWidth = GJCFSystemScreenWidth - 2*12.f;
    self.contentLabel.contentBaseHeight = 10.f;
    [self.view addSubview:self.contentLabel];
    
    NSAttributedString *contentAttributedString = [self contentAttributedString];
    
    CGSize theContentSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:contentAttributedString forBaseContentSize:self.contentLabel.contentBaseSize];
    self.contentLabel.gjcf_size = theContentSize;
    self.contentLabel.gjcf_left = 12.f;
    self.contentLabel.contentAttributedString = contentAttributedString;
    
    self.progressView = [[GJGCProgressView alloc]init];
    self.progressView.gjcf_size = CGSizeMake(100, 100);
    
    self.progressView.gjcf_centerX = GJCFSystemScreenWidth/2;
    self.progressView.gjcf_top = GJCFSystemScreenWidth/2 - 100/2;
    [self.view addSubview:self.progressView];
    
}

- (NSAttributedString *)contentAttributedString
{
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc]init];
    stringStyle.foregroundColor = [UIColor whiteColor];
    stringStyle.font = [UIFont systemFontOfSize:14];
    
    GJCFCoreTextParagraphStyle *paragrpahStyle = [[GJCFCoreTextParagraphStyle alloc]init];
    paragrpahStyle.lineBreakMode = kCTLineBreakByCharWrapping;
    paragrpahStyle.maxLineSpace = 8.f;
    paragrpahStyle.minLineSpace = 8.f;
    
    NSMutableAttributedString *contentAttributedString = [[NSMutableAttributedString alloc]initWithString:self.contentString attributes:[stringStyle attributedDictionary]];
    [contentAttributedString addAttributes:[paragrpahStyle paragraphAttributedDictionary] range:NSMakeRange(0, self.contentString.length)];
    
    return contentAttributedString;
}

- (void)rightButtonPressed:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"保存图片到手机", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"保存图片到手机"]) {
        
        [self saveImage];
    }
}

/**
 *  保存图片
 */
- (void)saveImage
{
    UIImageWriteToSavedPhotosAlbum([self.imageScrollView contentImage], self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
{
    
    NSString *msg = nil ;
    
    if(error != NULL){
        
        msg = @"保存图片失败" ;
        
    }else{
        
        msg = @"保存图片成功" ;
        
    }
}

#pragma mark - 下载大图

- (NSString *)cacheDirectory
{
    NSString *cacheDir = [[GJCFCachePathManager shareManager]mainImageCacheDirectory];
    
    return cacheDir;
}

- (NSString *)cachePathForUrl:(NSString *)imageUrl
{
    NSString *fileName = [imageUrl stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return [[self cacheDirectory]stringByAppendingPathComponent:fileName];
}

- (void)startDownloadBigImage
{
    NSString *cachePath = [self cachePathForUrl:self.imageUrl];
    
    UIImage *cachedImage = GJCFQuickImageByFilePath(cachePath);
    if (cachedImage) {
        
        [self.imageScrollView setNeedShowImage:cachedImage];
        
        [self.progressView dismiss];
        
        return;
    }
    
    GJCFFileDownloadTask *downloadTask = [GJCFFileDownloadTask taskWithDownloadUrl:self.imageUrl withCachePath:cachePath withObserver:self getTaskIdentifer:nil];
    [[GJCFFileDownloadManager shareDownloadManager]addTask:downloadTask];
}

- (void)initImageDownloadConfig
{
    GJCFWeakSelf weakSelf = self;
    
    /* 完成下载 */
    [[GJCFFileDownloadManager shareDownloadManager]setDownloadCompletionBlock:^(GJCFFileDownloadTask *task, NSData *fileData, BOOL isFinishCache) {
        
        [weakSelf downloadCompletion:fileData cacheState:isFinishCache];
        
    } forObserver:self];
    
    /* 下载失败 */
    [[GJCFFileDownloadManager shareDownloadManager]setDownloadFaildBlock:^(GJCFFileDownloadTask *task, NSError *error) {
        
        [weakSelf downloadFaild:error];
        
    } forObserver:self];
    
    /* 下载进度 */
    [[GJCFFileDownloadManager shareDownloadManager]setDownloadProgressBlock:^(GJCFFileDownloadTask *task, CGFloat progress) {
        
        [weakSelf downloadProgress:progress];
        
    } forObserver:self];
    
}

- (void)downloadCompletion:(NSData *)fileData cacheState:(BOOL)finish
{
    [self.progressView dismiss];

    UIImage *image = [UIImage imageWithData:fileData];
    [self.imageScrollView setNeedShowImage:image];
}

- (void)downloadFaild:(NSError *)error
{
    [self.progressView dismiss];
}

- (void)downloadProgress:(CGFloat)progress
{
    self.progressView.progress = progress;
}



@end
