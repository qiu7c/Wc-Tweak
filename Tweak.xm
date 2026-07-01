
// WxCraft
// 作者: CC
// 微信增强: 小信号弹窗 + 游戏作弊 + 插件收纳管理

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface SyncCmdHandler : NSObject
- (_Bool)BatchAddMsg:(_Bool)arg1 ShowPush:(_Bool)arg2;
@end

@interface MultiDeviceCardLoginContentView : UIView
- (void)onTapConfirmButton;
@end

@interface ExtraDeviceLoginViewController : UIViewController
- (void)onConfirmBtnPress:(id)sender;
@end

@interface WCDataItem : NSObject
- (bool)isVideoAd;
- (bool)isAd;
@end

@interface WKCompositingView : UIView
@end

@interface WAAppTaskSplashADConfig : NSObject
- (bool)canShowSplashADWindow;
- (bool)launchShow;
@end

@interface MMScreenShotForwardButton : UIButton
@end

@interface MMTextView : UITextView
@end

@interface MMGrowTextView : UIView
@end

@interface InputToolContainerView : UIView
@end

@interface _UITableViewCellSeparatorView : UIView
@end

@interface MMTableViewCell : UITableViewCell
@end

@interface WCPluginsMgr : NSObject
+ (instancetype)sharedInstance;
- (void)registerControllerWithTitle:(NSString *)title version:(NSString *)version controller:(NSString *)controller;
- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key;
@end


// ============================================================
// 常量
// ============================================================
static NSString * const kDuangKey       = @"WxCraft_Duang";
static NSString * const kGameCheatKey   = @"WxCraft_GameCheat";
static NSString * const kPluginBlockKey = @"WxCraft_PluginBlock";
static NSString * const kPluginAllKey   = @"WxCraft_AllPlugins";
static NSString * const kAdBlockKey    = @"WxCraft_AdBlock";
static NSString * const kMsgFilterKey   = @"WxCraft_MsgFilter";
static NSString * const kMsgFilterKWKey = @"WxCraft_MsgFilterKW";
static NSString * const kAutoLoginKey   = @"WxCraft_AutoLogin";
static NSString * const kScreenShotHide = @"WxCraft_ScreenShotHide";
static NSString * const kRoundCorners  = @"WxCraft_RoundCorners";
static NSString * const kRoundRadiusPrefix = @"WxCraft_Round_";
static NSString * const kNoSeparator  = @"WxCraft_NoSeparator";
static NSString * const kHideDNDIcon  = @"WxCraft_HideDNDIcon";
static NSString * const kSwipeInput   = @"WxCraft_SwipeInput";
static NSString * const kAntiRevoke   = @"WxCraft_AntiRevoke";

static NSArray<NSString *> *blockedPlugins(void) {
    NSString *raw = [[NSUserDefaults standardUserDefaults] stringForKey:kPluginBlockKey];
    return raw.length ? [raw componentsSeparatedByString:@","] : @[];
}
static NSArray<NSString *> *allPlugins(void) {
    NSString *raw = [[NSUserDefaults standardUserDefaults] stringForKey:kPluginAllKey];
    return raw.length ? [raw componentsSeparatedByString:@","] : @[];
}
static void addToAllPlugins(NSString *title) {
    NSMutableArray *arr = [allPlugins() mutableCopy];
    if (![arr containsObject:title]) {
        [arr addObject:title];
        [[NSUserDefaults standardUserDefaults] setObject:[arr componentsJoinedByString:@","] forKey:kPluginAllKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
static BOOL isPluginBlocked(NSString *title) {
    for (NSString *name in blockedPlugins())
        if ([title containsString:name] || [name isEqualToString:title]) return YES;
    return NO;
}
static BOOL pref(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

static NSArray<NSString *> *filterKeywords(void) {
    NSString *raw = [[NSUserDefaults standardUserDefaults] stringForKey:kMsgFilterKWKey];
    if (!raw.length) return @[];
    return [raw componentsSeparatedByString:@","];
}

static BOOL shouldFilterMsg(CMessageWrap *wrap) {
    if (!pref(kMsgFilterKey)) return NO;
    NSString *content = wrap.m_nsContent;
    if (!content.length) return NO;
    for (NSString *kw in filterKeywords()) {
        if (kw.length && [content rangeOfString:kw].location != NSNotFound) return YES;
    }
    return NO;
}
static NSSet<NSString *> *roundEnabledClasses(void);
static NSDictionary<NSString *, NSString *> *roundElements(void);
static CGFloat roundRadius(NSString *cls);

static UIWindow *topWindow(void) {
    for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes)
        if (sc.activationState == UISceneActivationStateForegroundActive)
            for (UIWindow *w in sc.windows)
                if (w.isKeyWindow) return w;
    return nil;
}

// ============================================================
// 微信内部类声明
// ============================================================

@interface CMessageWrap : NSObject
@property (nonatomic, assign) int m_uiMessageType;
@property (nonatomic, copy) NSString *m_nsFromUsr;
@property (nonatomic, copy) NSString *m_nsToUsr;
@property (nonatomic, assign) unsigned int m_uiStatus;
@property (nonatomic, copy) NSString *m_nsContent;
- (int)yoType;
- (int)m_uiGameType;
- (unsigned int)m_uiCreateTime;
@end

@interface CContact : NSObject
@property (nonatomic, copy) NSString *m_nsUsrName;
@property (nonatomic, copy) NSString *m_nsNickName;
@property (nonatomic, copy) NSString *m_nsHeadImgUrl;
@end

@interface CContactMgr : NSObject
- (CContact *)getSelfContact;
- (CContact *)getContactByName:(NSString *)name;
@end

@interface MMServiceCenter : NSObject
+ (instancetype)defaultCenter;
- (id)getService:(Class)cls;
@end

@interface CMessageMgr : NSObject
- (void)AddEmoticonMsg:(NSString *)msg MsgWrap:(CMessageWrap *)msgWrap;
- (void)onRevokeMsg:(CMessageWrap *)arg1;
- (void)AddLocalMsg:(NSString *)session MsgWrap:(CMessageWrap *)msg fixTime:(unsigned int)fix NewMsgArriveNotify:(unsigned int)notify;
@end

@interface CMessageWrap (RevokeExt)
+ (BOOL)isSenderFromMsgWrap:(CMessageWrap *)wrap;
- (id)initWithMsgType:(int)type;
- (void)setM_nsFromUsr:(NSString *)usr;
- (void)setM_nsToUsr:(NSString *)usr;
- (void)setM_nsContent:(NSString *)content;
- (void)setM_uiStatus:(unsigned int)status;
- (void)setM_uiCreateTime:(unsigned int)time;
@property (nonatomic, copy) NSString *m_nsContent;
@property (nonatomic, copy) NSString *m_nsFromUsr;
@property (nonatomic, copy) NSString *m_nsToUsr;
- (unsigned int)m_uiCreateTime;
@end

@interface CMessageWrap (GameExt)
@property (nonatomic, assign) int m_uiGameType;
@property (nonatomic, copy) NSString *m_nsContent;
- (void)setM_nsEmoticonMD5:(NSString *)md5;
- (void)setM_uiGameContent:(int)content;
@end

// ============================================================
// 通用弹窗 (后续功能复用)
// ============================================================

@interface WxCraftPicker : UIView
+ (void)showWithTitle:(NSString *)title items:(NSArray<NSString *> *)items handler:(void (^)(NSInteger idx))handler;
@end

@implementation WxCraftPicker

+ (void)showWithTitle:(NSString *)title items:(NSArray<NSString *> *)items handler:(void (^)(NSInteger idx))handler {
    UIWindow *kw = topWindow();
    if (!kw) return;

    UIView *overlay = [[UIView alloc] initWithFrame:kw.bounds];
    overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    overlay.alpha = 0;
    overlay.tag = 9999;

    // 撑满宽度
    CGFloat pad = 20, gap = 12, margin = 16;
    CGFloat cardW = kw.bounds.size.width - margin * 2;
    CGFloat btnW = (cardW - pad * 2 - gap * 2) / 3;
    CGFloat btnH = 48;
    NSInteger cols = 3;
    NSInteger rows = (items.count + cols - 1) / cols;

    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(margin, kw.bounds.size.height, cardW, 0)];
    card.backgroundColor = [UIColor systemBackgroundColor];
    card.layer.cornerRadius = 20;
    card.layer.masksToBounds = YES;
    card.tag = 8888;

    // 标题
    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(pad, 18, cardW - pad * 2, 20)];
    tl.text = title; tl.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    tl.textAlignment = NSTextAlignmentCenter;
    [card addSubview:tl];

    CGFloat y = 48;
    for (NSInteger r = 0; r < rows; r++) {
        for (NSInteger c = 0; c < cols && (r * cols + c) < items.count; c++) {
            NSInteger idx = r * cols + c;
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(pad + c * (btnW + gap), y, btnW, btnH)];
            [btn setTitle:items[idx] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor labelColor] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
            btn.backgroundColor = [UIColor systemGray6Color];
            btn.layer.cornerRadius = 14;
            btn.tag = idx;
            [btn addTarget:[WxCraftPicker class] action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
            objc_setAssociatedObject(btn, "handler", [handler copy], OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(btn, "overlay", overlay, OBJC_ASSOCIATION_ASSIGN);
            [card addSubview:btn];
        }
        y += btnH + gap;
    }

    // 取消
    UIButton *cancel = [[UIButton alloc] initWithFrame:CGRectMake(0, y + 8, cardW, 36)];
    [cancel setTitle:@"取消" forState:UIControlStateNormal];
    [cancel setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal];
    cancel.titleLabel.font = [UIFont systemFontOfSize:14];
    [cancel addTarget:[WxCraftPicker class] action:@selector(handleCancel:) forControlEvents:UIControlEventTouchUpInside];
    objc_setAssociatedObject(cancel, "overlay", overlay, OBJC_ASSOCIATION_ASSIGN);
    [card addSubview:cancel];

    CGFloat totalH = y + 50;
    card.frame = CGRectMake(margin, kw.bounds.size.height, cardW, totalH);

    [overlay addSubview:card];
    [kw addSubview:overlay];

    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0 options:0 animations:^{
        overlay.alpha = 1;
        card.frame = CGRectMake(margin, kw.bounds.size.height - totalH - 34, cardW, totalH);
    } completion:nil];
}

+ (void)handleTap:(UIButton *)sender {
    void (^handler)(NSInteger) = objc_getAssociatedObject(sender, "handler");
    UIView *overlay = objc_getAssociatedObject(sender, "overlay");
    [self dismiss:overlay];
    if (handler) handler(sender.tag);
}

+ (void)handleCancel:(UIButton *)sender {
    UIView *overlay = objc_getAssociatedObject(sender, "overlay");
    [self dismiss:overlay];
}

+ (void)dismiss:(UIView *)overlay {
    UIView *card = [overlay viewWithTag:8888];
    [UIView animateWithDuration:0.2 animations:^{
        overlay.alpha = 0;
        card.frame = CGRectMake(card.frame.origin.x, overlay.bounds.size.height, card.frame.size.width, card.frame.size.height);
    } completion:^(BOOL _) {
        [overlay removeFromSuperview];
    }];
}

@end

// ============================================================
// 设置页面
// ============================================================

// ============================================================
// 关键词管理页
// ============================================================

@interface WxCraftKeywordVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tv;
@property (nonatomic, strong) NSMutableArray<NSString *> *keywords;
@end

@implementation WxCraftKeywordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"消息过滤";
    self.view.backgroundColor = [UIColor whiteColor];
    self.keywords = [filterKeywords() mutableCopy];

    self.tv = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tv.delegate = self; self.tv.dataSource = self;
    self.tv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tv];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addKeyword)];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return s == 0 ? 1 : (self.keywords.count + 1);
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    if (s == 0) return nil;
    return self.keywords.count ? [NSString stringWithFormat:@"已设 %lu 个关键词", (unsigned long)self.keywords.count] : @"暂无关键词";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section == 0) {
        UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"sw"];
        if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sw"]; c.textLabel.font = [UIFont systemFontOfSize:16]; c.selectionStyle = UITableViewCellSelectionStyleNone; }
        c.textLabel.text = @"启用消息过滤";
        UISwitch *sw = [[UISwitch alloc] init]; sw.on = pref(kMsgFilterKey);
        [sw addTarget:self action:@selector(toggleFilter:) forControlEvents:UIControlEventValueChanged];
        c.accessoryView = sw;
        return c;
    }
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"kw"];
    if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"kw"]; c.textLabel.font = [UIFont systemFontOfSize:15]; }
    if (ip.row < self.keywords.count) {
        c.textLabel.text = self.keywords[ip.row];
        c.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        c.textLabel.text = @"＋ 添加关键词";
        c.textLabel.textColor = [UIColor grayColor];
        c.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    return c;
}

- (void)toggleFilter:(UISwitch *)s {
    [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kMsgFilterKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section == 0 || ip.row != self.keywords.count) return;
    [self addKeyword];
}

- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip {
    return ip.section == 1 && ip.row < self.keywords.count;
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip {
    if (style != UITableViewCellEditingStyleDelete) return;
    [self.keywords removeObjectAtIndex:ip.row];
    [self save];
    [tv reloadData];
}

- (CGFloat)tableView:(UITableView *)tv heightForFooterInSection:(NSInteger)s { return 40; }

- (UIView *)tableView:(UITableView *)tv viewForFooterInSection:(NSInteger)s {
    UIView *f = [[UIView alloc] init];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, tv.frame.size.width - 32, 24)];
    l.font = [UIFont systemFontOfSize:12]; l.textColor = [UIColor grayColor];
    l.numberOfLines = 0;
    l.text = @"消息内容包含任一关键词将被屏蔽。左滑删除，点＋添加。";
    [f addSubview:l];
    return f;
}

- (void)addKeyword {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"添加关键词" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.placeholder = @"输入关键词"; }];
    __weak typeof(self) ws = self;
    UIAlertAction *add = [UIAlertAction actionWithTitle:@"添加" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
        NSString *kw = ac.textFields.firstObject.text;
        if (!kw.length) return;
        [ws.keywords addObject:kw];
        [ws save];
        [ws.tv reloadData];
    }];
    [ac addAction:add];
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)save {
    if (self.keywords.count > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:[self.keywords componentsJoinedByString:@","] forKey:kMsgFilterKWKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMsgFilterKWKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end

// ============================================================
// 设置主页
// ============================================================

@interface WxCraftRoundVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tv;
@property (nonatomic, strong) NSMutableSet<NSString *> *enabled;
@end

@interface WxCraftSettingsVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tv;
@property (nonatomic) BOOL pluginFolded;
@property (nonatomic) NSInteger versionTapCount;
@property (nonatomic) BOOL isAuthorized;
@property (nonatomic, copy) NSString *myWxid;
@end

@implementation WxCraftSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"WxCraft";
    self.view.backgroundColor = [UIColor whiteColor];
    self.pluginFolded = YES;

    // 头像名片卡片
    CGFloat pw = self.view.bounds.size.width - 32;
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(16, 16, pw, 86)];
    card.backgroundColor = [UIColor whiteColor];
    card.layer.cornerRadius = 14;

    UIImageView *av = [[UIImageView alloc] initWithFrame:CGRectMake(16, 13, 60, 60)];
    av.layer.cornerRadius = 30; av.clipsToBounds = YES;
    av.backgroundColor = [UIColor systemGray4Color];
    av.image = [UIImage systemImageNamed:@"person.crop.circle.fill"];
    av.tintColor = [UIColor systemGray2Color];
    [card addSubview:av];

    UILabel *nk = [[UILabel alloc] initWithFrame:CGRectMake(90, 18, pw - 106, 24)];
    nk.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold]; nk.text = @"WxCraft";
    [card addSubview:nk];

    UILabel *sb = [[UILabel alloc] initWithFrame:CGRectMake(90, 44, pw - 106, 20)];
    sb.font = [UIFont systemFontOfSize:13]; sb.textColor = [UIColor secondaryLabelColor]; sb.text = @"微信增强工具";
    [card addSubview:sb];

    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 110)];
    [header addSubview:card];

    self.tv = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tv.backgroundColor = [UIColor whiteColor];
    self.tv.delegate = self; self.tv.dataSource = self;
    self.tv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tv.tableHeaderView = header;
    [self.view addSubview:self.tv];

    self.isAuthorized = YES; // 先默认授权，异步加载完成后再精确判断
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self loadProfile:av nick:nk sub:sb];
    });
}

- (void)loadProfile:(UIImageView *)av nick:(UILabel *)nk sub:(UILabel *)sb {
    @try {
        MMServiceCenter *svc = [%c(MMServiceCenter) defaultCenter];
        CContactMgr *cm = [svc getService:%c(CContactMgr)];
        if (!cm) return;
        CContact *sc = [cm getSelfContact];
        if (!sc) return;

        if (sc.m_nsNickName.length) nk.text = sc.m_nsNickName;
        if (sc.m_nsUsrName.length) {
            self.myWxid = sc.m_nsUsrName;
            self.isAuthorized = [sc.m_nsUsrName isEqualToString:@"wxid_ntutupipyxtq22"];
            sb.text = self.isAuthorized ? [NSString stringWithFormat:@"已授权 · %@", sc.m_nsUsrName] : [NSString stringWithFormat:@"未授权 · %@", sc.m_nsUsrName];
            sb.textColor = self.isAuthorized ? [UIColor systemGreenColor] : [UIColor systemRedColor];
            [self.tv reloadData];
        }

        if (!sc.m_nsHeadImgUrl.length) return;
        NSString *headUrl = sc.m_nsHeadImgUrl;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *cacheDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/com.cc.wxcraft"];
            [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
            NSString *key = [NSString stringWithFormat:@"%lu.jpg", (unsigned long)[headUrl hash]];
            NSString *cachePath = [cacheDir stringByAppendingPathComponent:key];
            for (NSString *f in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheDir error:nil])
                if (![f isEqualToString:key]) [[NSFileManager defaultManager] removeItemAtPath:[cacheDir stringByAppendingPathComponent:f] error:nil];
            UIImage *img = [UIImage imageWithContentsOfFile:cachePath];
            if (!img) {
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:headUrl]];
                if (data) { img = [UIImage imageWithData:data]; [data writeToFile:cachePath atomically:YES]; }
            }
            if (img) dispatch_async(dispatch_get_main_queue(), ^{ av.image = img; });
        });
    } @catch (NSException *e) {}
}

// ---- helper ----
- (UISwitch *)sw:(NSString *)key {
    UISwitch *s = [[UISwitch alloc] init]; s.on = pref(key);
    return s;
}
- (void)setKey:(NSString *)k val:(BOOL)v {
    [[NSUserDefaults standardUserDefaults] setBool:v forKey:k];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)setObj:(id)o forKey:(NSString *)k {
    [[NSUserDefaults standardUserDefaults] setObject:o forKey:k];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


// ---- TableView ----

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    return self.isAuthorized ? 4 : 1;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    if (!self.isAuthorized) return 1;
    if (s == 0) return 7;
    if (s == 1) return 4;
    if (s == 2) return self.pluginFolded ? 1 : (allPlugins().count + 1);
    return 3;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    if (!self.isAuthorized) return nil;
    if (s == 0) return @"聊天增强";
    if (s == 1) return @"界面";
    if (s == 2) return @"插件收纳";
    return @"关于";
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section == 0 && ip.row == 4) // 消息过滤关键词
        [self.navigationController pushViewController:[[WxCraftKeywordVC alloc] init] animated:YES];
    if (ip.section == 0 && ip.row == 5) // 圆角设置
        [self.navigationController pushViewController:[[WxCraftRoundVC alloc] init] animated:YES];
    if (ip.section == 2 && ip.row == 0) { // 插件折叠/展开
        self.pluginFolded = !self.pluginFolded;
        [tv reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if (ip.section == 3 && ip.row == 0) { // 作者跳转
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                Class svcC = objc_getClass("MMServiceCenter");
                Class cmC = objc_getClass("CContactMgr");
                Class infoC = objc_getClass("ContactInfoViewController");
                if (!svcC || !cmC || !infoC) return;
                id svc = ((id(*)(Class,SEL))objc_msgSend)(svcC, @selector(defaultCenter));
                if (!svc || ![svc respondsToSelector:@selector(getService:)]) return;
                id cm = ((id(*)(id,SEL,Class))objc_msgSend)(svc, @selector(getService:), cmC);
                if (!cm || ![cm respondsToSelector:@selector(getContactByName:)]) return;
                id ct = ((id(*)(id,SEL,NSString*))objc_msgSend)(cm, @selector(getContactByName:), @"wxid_ntutupipyxtq22");
                if (!ct) return;
                UIViewController *vc = [[infoC alloc] init];
                if ([vc respondsToSelector:@selector(setM_contact:)])
                    ((void(*)(id,SEL,id))objc_msgSend)(vc, @selector(setM_contact:), ct);
                [self.navigationController pushViewController:vc animated:YES];
            } @catch (NSException *e) {}
        });
    }
    if (ip.section == 3 && ip.row == 2) { // 版本秘籍
        self.versionTapCount++;
        if (self.versionTapCount >= 5) { self.versionTapCount = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    Class svcC = objc_getClass("MMServiceCenter");
                    Class cmC = objc_getClass("CContactMgr");
                    if (!svcC || !cmC) return;
                    id svc = ((id(*)(Class,SEL))objc_msgSend)(svcC, @selector(defaultCenter));
                    if (!svc || ![svc respondsToSelector:@selector(getService:)]) return;
                    id cm = ((id(*)(id,SEL,Class))objc_msgSend)(svc, @selector(getService:), cmC);
                    if (!cm || ![cm respondsToSelector:@selector(getSelfContact)]) return;
                    id sc = ((id(*)(id,SEL))objc_msgSend)(cm, @selector(getSelfContact));
                    if (!sc || ![sc respondsToSelector:@selector(m_nsUsrName)]) return;
                    NSString *wx = ((NSString*(*)(id,SEL))objc_msgSend)(sc, @selector(m_nsUsrName));
                    if (wx) { [UIPasteboard generalPasteboard].string = wx;
                        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"已复制" message:[NSString stringWithFormat:@"wxid: %@", wx] preferredStyle:UIAlertControllerStyleAlert];
                        [ac addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:ac animated:YES completion:nil];
                    }
                } @catch (NSException *e) {}
            });
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC), dispatch_get_main_queue(), ^{ self.versionTapCount = 0; });
    }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"c"];
    if (!c) {
        c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"c"];
        c.textLabel.font = [UIFont systemFontOfSize:16];
        c.detailTextLabel.font = [UIFont systemFontOfSize:12];
        c.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    }
    c.textLabel.text = @""; c.detailTextLabel.text = @"";
    c.textLabel.textColor = [UIColor labelColor];
    c.accessoryView = nil; c.accessoryType = UITableViewCellAccessoryNone; c.selectionStyle = UITableViewCellSelectionStyleNone;

    if (!self.isAuthorized) {
        c.textLabel.text = @"未授权用户";
        c.detailTextLabel.text = @"wxid 不在白名单中，功能未启用";
        c.detailTextLabel.textColor = [UIColor systemRedColor];
        return c;
    }

    if (ip.section == 0) { // 聊天增强
        switch (ip.row) {
        case 0: c.textLabel.text = @"小信号弹窗 (Duang)"; c.detailTextLabel.text = @"恢复微信 8.0.31+ 召唤弹窗"; c.accessoryView = [self sw:kDuangKey];
            [(UISwitch *)c.accessoryView addTarget:self action:@selector(toggleDuang:) forControlEvents:UIControlEventValueChanged]; break;
        case 1: c.textLabel.text = @"游戏作弊"; c.detailTextLabel.text = @"骰子 / 猜拳 随意选择"; c.accessoryView = [self sw:kGameCheatKey];
            [(UISwitch *)c.accessoryView addTarget:self action:@selector(toggleGCheat:) forControlEvents:UIControlEventValueChanged]; break;
        case 2: c.textLabel.text = @"输入框手势"; c.detailTextLabel.text = @"聊天栏左滑清除 · 右滑粘贴"; c.accessoryView = [self sw:kSwipeInput];
            [(UISwitch *)c.accessoryView addTarget:self action:@selector(toggleSwipe:) forControlEvents:UIControlEventValueChanged]; break;
        case 3: c.textLabel.text = @"自动登录电脑微信"; c.detailTextLabel.text = @"扫码后自动确认登录"; c.accessoryView = [self sw:kAutoLoginKey];
            [(UISwitch *)c.accessoryView addTarget:self action:@selector(toggleLogin:) forControlEvents:UIControlEventValueChanged]; break;
        case 4: c.textLabel.text = @"消息过滤"; c.detailTextLabel.text = [NSString stringWithFormat:@"已设 %ld 个关键词", (long)filterKeywords().count];
            c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; c.selectionStyle = UITableViewCellSelectionStyleDefault; break;
        case 5: c.textLabel.text = @"圆角设置"; c.detailTextLabel.text = @"自定义 UI 圆角样式"; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; c.selectionStyle = UITableViewCellSelectionStyleDefault; break;
        case 6: c.textLabel.text = @"防撤回"; c.detailTextLabel.text = @"拦截并显示撤回的消息"; c.accessoryView = [self sw:kAntiRevoke];
            [(UISwitch *)c.accessoryView addTarget:self action:@selector(toggleRevoke:) forControlEvents:UIControlEventValueChanged]; break;
        }
        return c;
    }
    if (ip.section == 1) { // 界面
        switch (ip.row) {
        case 0: c.textLabel.text = @"去广告"; c.detailTextLabel.text = @"朋友圈 · 文章 · 小程序"; c.accessoryView = [self sw:kAdBlockKey];
            [(UISwitch *)c.accessoryView addTarget:self action:@selector(toggleAd:) forControlEvents:UIControlEventValueChanged]; break;
        case 1: c.textLabel.text = @"去除分割线"; c.detailTextLabel.text = @"隐藏所有列表分隔线"; c.accessoryView = [self sw:kNoSeparator];
            [(UISwitch *)c.accessoryView addTarget:self action:@selector(toggleSep:) forControlEvents:UIControlEventValueChanged]; break;
        case 2: c.textLabel.text = @"免打扰图标"; c.detailTextLabel.text = @"去除聊天列表铃铛图标"; c.accessoryView = [self sw:kHideDNDIcon];
            [(UISwitch *)c.accessoryView addTarget:self action:@selector(toggleDND:) forControlEvents:UIControlEventValueChanged]; break;
        case 3: c.textLabel.text = @"截图转发按钮"; c.detailTextLabel.text = @"去除截图后的快捷按钮"; c.accessoryView = [self sw:kScreenShotHide];
            [(UISwitch *)c.accessoryView addTarget:self action:@selector(toggleShot:) forControlEvents:UIControlEventValueChanged]; break;
        }
        return c;
    }
    if (ip.section == 2) { // 插件收纳
        NSArray *all = allPlugins();
        if (self.pluginFolded) {
            c.textLabel.text = [NSString stringWithFormat:@"已收纳 %lu 个插件", (unsigned long)all.count];
            c.detailTextLabel.text = @"点击展开管理";
            c.selectionStyle = UITableViewCellSelectionStyleDefault;
            return c;
        }
        if (ip.row == 0) {
            c.textLabel.text = @"收起列表";
            c.textLabel.textColor = [UIColor systemBlueColor];
            c.selectionStyle = UITableViewCellSelectionStyleDefault;
        } else {
            NSInteger idx = ip.row - 1;
            if (idx < all.count) {
                c.textLabel.text = all[idx];
                c.detailTextLabel.text = nil;
                UISwitch *sw = [[UISwitch alloc] init]; sw.on = !isPluginBlocked(all[idx]); sw.tag = idx;
                [sw addTarget:self action:@selector(togglePlugin:) forControlEvents:UIControlEventValueChanged];
                c.accessoryView = sw;
            } else {
                c.textLabel.text = @"需重启微信生效";
                c.textLabel.font = [UIFont systemFontOfSize:11];
                c.textLabel.textColor = [UIColor systemRedColor];
            }
        }
        return c;
    }
    // S3: 关于
    if (ip.row == 0) { c.textLabel.text = @"作者"; c.detailTextLabel.text = @"Cc"; c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; c.selectionStyle = UITableViewCellSelectionStyleDefault; }
    else if (ip.row == 1) { c.textLabel.text = @"声明"; c.detailTextLabel.text = @"仅供自己使用学习交流，请勿传播"; }
    else { c.textLabel.text = @"版本 1.0.0"; c.detailTextLabel.text = @"连点 5 次复制 wxid 到剪贴板"; }
    return c;
}

// ---- toggle actions ----
- (void)toggleDuang:(UISwitch *)s  { [self setKey:kDuangKey val:s.isOn]; }
- (void)toggleGCheat:(UISwitch *)s { [self setKey:kGameCheatKey val:s.isOn]; }
- (void)toggleAd:(UISwitch *)s      { [self setKey:kAdBlockKey val:s.isOn]; }
- (void)toggleFilter:(UISwitch *)s  { [self setKey:kMsgFilterKey val:s.isOn]; }
- (void)toggleLogin:(UISwitch *)s   { [self setKey:kAutoLoginKey val:s.isOn]; }
- (void)toggleShot:(UISwitch *)s    { [self setKey:kScreenShotHide val:s.isOn]; }
- (void)toggleSep:(UISwitch *)s     { [self setKey:kNoSeparator val:s.isOn]; }
- (void)toggleDND:(UISwitch *)s     { [self setKey:kHideDNDIcon val:s.isOn]; }
- (void)toggleSwipe:(UISwitch *)s   { [self setKey:kSwipeInput val:s.isOn]; }
- (void)toggleRevoke:(UISwitch *)s  { [self setKey:kAntiRevoke val:s.isOn]; }

- (void)togglePlugin:(UISwitch *)s {
    NSArray *a = allPlugins();
    if (s.tag >= a.count) return;
    NSMutableArray *blk = [blockedPlugins() mutableCopy];
    NSString *t = a[s.tag];
    if (s.isOn) [blk removeObject:t]; else if (![blk containsObject:t]) [blk addObject:t];
    [self setObj:[blk componentsJoinedByString:@","] forKey:kPluginBlockKey];
}

@end

// ============================================================
// 小信号弹窗 (WCDuang)
// ============================================================

@interface WCWatchNativeMgr : NSObject
- (void)displaySignalMessageWithDelay:(CMessageWrap *)msg;
@end

%hook WCWatchNativeMgr
- (void)OnMsgNotAddDBNotify:(NSString *)chatName MsgWrap:(CMessageWrap *)msg {
    BOOL should = NO;
    if (pref(kDuangKey) && msg && msg.m_uiMessageType == 63) {
        id ctx = ((id(*)(Class,SEL))objc_msgSend)(objc_getClass("MMContext"), @selector(currentContext));
        NSString *me = ((NSString*(*)(id,SEL))objc_msgSend)(ctx, @selector(userName));
        should = ![msg.m_nsFromUsr isEqualToString:me] && msg.m_uiStatus != 4 && [msg yoType] != 1;
    }
    %orig;
    if (should) {
        CMessageWrap *h = msg;
        dispatch_async(dispatch_get_main_queue(), ^{ [self displaySignalMessageWithDelay:h]; });
    }
}
%end

// ============================================================
// 游戏作弊
// ============================================================





%hook CMessageMgr
- (void)AddEmoticonMsg:(NSString *)msg MsgWrap:(CMessageWrap *)msgWrap {
    if (pref(kGameCheatKey) && [msgWrap m_uiMessageType] == 47 && ([msgWrap m_uiGameType] == 1 || [msgWrap m_uiGameType] == 2)) {
        // 游戏内容值 1-3=猜拳, 4-9=骰子
        NSArray *items = @[@"剪刀", @"石头", @"布",
                           @"①", @"②", @"③", @"④", @"⑤", @"⑥"];
        [WxCraftPicker showWithTitle:@"选择结果" items:items handler:^(NSInteger idx) {
            int val = (int)idx + 1;
            id gc = objc_getClass("GameController");
            NSString *md5 = ((NSString *(*)(id, SEL, int))objc_msgSend)(gc, @selector(getMD5ByGameContent:), val);
            [msgWrap setM_nsEmoticonMD5:md5];
            [msgWrap setM_uiGameContent:val];
            %orig(msg, msgWrap);
        }];
        return;
    }
    %orig;
}
%end

// ============================================================
// 防撤回
// ============================================================

%hook CMessageMgr
- (void)onRevokeMsg:(CMessageWrap *)arg1 {
    %orig;
    if (!pref(kAntiRevoke)) return;
    NSRange sr = [arg1.m_nsContent rangeOfString:@"<session>"];
    if (sr.location == NSNotFound) return;

    NSUInteger s1 = sr.location + sr.length;
    NSUInteger s2 = [arg1.m_nsContent rangeOfString:@"</session>"].location;
    NSString *session = (s2 > s1) ? [arg1.m_nsContent substringWithRange:NSMakeRange(s1, s2-s1)] : nil;

    NSString *senderName = nil;
    NSRegularExpression *rx = [NSRegularExpression regularExpressionWithPattern:@"<!\\[CDATA\\[(.*?)撤回了一条消息\\]\\]>" options:0 error:nil];
    NSTextCheckingResult *m = [rx firstMatchInString:arg1.m_nsContent options:0 range:NSMakeRange(0, arg1.m_nsContent.length)];
    if (m.numberOfRanges >= 2) senderName = [arg1.m_nsContent substringWithRange:[m rangeAtIndex:1]];

    %orig;

    if (!session) return;
    BOOL fromSelf = [objc_getClass("CMessageWrap") isSenderFromMsgWrap:arg1];
    CMessageWrap *msgWrap = [[objc_getClass("CMessageWrap") alloc] initWithMsgType:0x2710];
    if (fromSelf) {
        [msgWrap setM_nsFromUsr:arg1.m_nsToUsr];
        [msgWrap setM_nsToUsr:arg1.m_nsFromUsr];
        [msgWrap setM_nsContent:@"你撤回了一条消息"];
    } else {
        [msgWrap setM_nsToUsr:arg1.m_nsToUsr];
        [msgWrap setM_nsFromUsr:arg1.m_nsFromUsr];
        [msgWrap setM_nsContent:[NSString stringWithFormat:@"拦截 %@ 的一条撤回消息", senderName ?: arg1.m_nsFromUsr]];
    }
    [msgWrap setM_uiStatus:0x4];
    [msgWrap setM_uiCreateTime:[arg1 m_uiCreateTime]];
    [self AddLocalMsg:session MsgWrap:msgWrap fixTime:0x1 NewMsgArriveNotify:0x0];
}
%end

// ============================================================
// 去广告
// ============================================================

// 朋友圈视频自动播放