// WxCraft
// 作者: CC
// 微信增强: 小信号弹窗 + 游戏作弊 + 插件收纳管理

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

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

static NSArray<NSString *> *filterKeywords(void);
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
    self.title = @"过滤关键词";
    self.view.backgroundColor = [UIColor whiteColor];
    self.keywords = [filterKeywords() mutableCopy];

    self.tv = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tv.delegate = self; self.tv.dataSource = self;
    self.tv.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.tv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tv];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addKeyword)];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return self.keywords.count + 1; }

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
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

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.row != self.keywords.count) return;
    [self addKeyword];
}

- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip {
    return ip.row < self.keywords.count;
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
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISwitch *duangSwitch, *gameCheatSwitch, *adBlockSwitch, *msgFilterSwitch, *autoLoginSwitch, *screenshotSwitch, *noSepSwitch, *hideDNDSwitch, *swipeInputSwitch;
@property (nonatomic) BOOL pluginFolded;
@property (nonatomic) NSInteger versionTapCount;
@end

@implementation WxCraftSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"WxCraft";
    self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    self.pluginFolded = YES;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];

    self.duangSwitch    = [self makeSwitch:kDuangKey];
    self.gameCheatSwitch = [self makeSwitch:kGameCheatKey];
    self.adBlockSwitch   = [self makeSwitch:kAdBlockKey];
    self.msgFilterSwitch  = [self makeSwitch:kMsgFilterKey];
    self.autoLoginSwitch  = [self makeSwitch:kAutoLoginKey];
    self.screenshotSwitch = [self makeSwitch:kScreenShotHide];
    self.noSepSwitch      = [self makeSwitch:kNoSeparator];
    self.hideDNDSwitch    = [self makeSwitch:kHideDNDIcon];
    self.swipeInputSwitch  = [self makeSwitch:kSwipeInput];
}

- (UISwitch *)makeSwitch:(NSString *)key {
    UISwitch *s = [[UISwitch alloc] init];
    s.on = pref(key);
    return s;
}

- (void)saveBool:(BOOL)v forKey:(NSString *)k {
    [[NSUserDefaults standardUserDefaults] setBool:v forKey:k];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 3; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    if (s == 0) return 4;  // 聊天增强
    if (s == 1) return 5;  // 界面
    if (s == 2) return 1;  // 其他 (折叠)
    return 0;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)s {
    if (s == 0) return @"聊天增强";
    if (s == 1) return @"界面";
    if (s == 2) return @"其他";
    return nil;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section == 0 && ip.row == 3) { // 圆角
        [self.navigationController pushViewController:[[WxCraftRoundVC alloc] init] animated:YES];
    }
    if (ip.section == 2 && ip.row == 0) { // 插件收纳折叠
        self.pluginFolded = !self.pluginFolded;
        [tv reloadData];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"c"];
    if (!c) {
        c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"c"];
        c.textLabel.font = [UIFont systemFontOfSize:15];
        c.detailTextLabel.font = [UIFont systemFontOfSize:12];
        c.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    }
    c.textLabel.text = @"";
    c.detailTextLabel.text = @"";
    c.accessoryView = nil;
    c.accessoryType = UITableViewCellAccessoryNone;
    c.selectionStyle = UITableViewCellSelectionStyleNone;

    // ==== 聊天增强 ====
    if (ip.section == 0) {
        if (ip.row == 0) {
            c.textLabel.text = @"小信号弹窗 (Duang)"; c.detailTextLabel.text = @"恢复召唤弹窗"; c.accessoryView = self.duangSwitch;
            [self.duangSwitch addTarget:self action:@selector(toggleDuang:) forControlEvents:UIControlEventValueChanged];
        } else if (ip.row == 1) {
            c.textLabel.text = @"游戏作弊"; c.detailTextLabel.text = @"骰子/猜拳自由选择"; c.accessoryView = self.gameCheatSwitch;
            [self.gameCheatSwitch addTarget:self action:@selector(toggleGameCheat:) forControlEvents:UIControlEventValueChanged];
        } else if (ip.row == 2) {
            c.textLabel.text = @"输入框手势"; c.detailTextLabel.text = @"左滑清除 · 右滑粘贴"; c.accessoryView = self.swipeInputSwitch;
            [self.swipeInputSwitch addTarget:self action:@selector(toggleSwipeInput:) forControlEvents:UIControlEventValueChanged];
        } else {
            c.textLabel.text = @"圆角设置"; c.detailTextLabel.text = @"定制 UI 圆角";
            c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; c.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        return c;
    }
    // ==== 界面 ====
    if (ip.section == 1) {
        if (ip.row == 0) {
            c.textLabel.text = @"去广告"; c.detailTextLabel.text = @"朋友圈/文章/小程序"; c.accessoryView = self.adBlockSwitch;
            [self.adBlockSwitch addTarget:self action:@selector(toggleAdBlock:) forControlEvents:UIControlEventValueChanged];
        } else if (ip.row == 1) {
            c.textLabel.text = @"去除分割线"; c.detailTextLabel.text = @"全局隐藏列表分割线"; c.accessoryView = self.noSepSwitch;
            [self.noSepSwitch addTarget:self action:@selector(toggleNoSep:) forControlEvents:UIControlEventValueChanged];
        } else if (ip.row == 2) {
            c.textLabel.text = @"免打扰图标"; c.detailTextLabel.text = @"隐藏聊天列表铃铛"; c.accessoryView = self.hideDNDSwitch;
            [self.hideDNDSwitch addTarget:self action:@selector(toggleHideDND:) forControlEvents:UIControlEventValueChanged];
        } else if (ip.row == 3) {
            c.textLabel.text = @"截图转发按钮"; c.detailTextLabel.text = @"去除截图后的小按钮"; c.accessoryView = self.screenshotSwitch;
            [self.screenshotSwitch addTarget:self action:@selector(toggleScreenShot:) forControlEvents:UIControlEventValueChanged];
        } else {
            c.textLabel.text = @"消息过滤";
            NSInteger cnt = filterKeywords().count;
            c.detailTextLabel.text = cnt ? [NSString stringWithFormat:@"%ld 个关键词", (long)cnt] : @"未设置";
            c.accessoryView = self.msgFilterSwitch;
            c.accessoryType = UITableViewCellAccessoryDisclosureIndicator; c.selectionStyle = UITableViewCellSelectionStyleDefault;
            [self.msgFilterSwitch addTarget:self action:@selector(toggleMsgFilter:) forControlEvents:UIControlEventValueChanged];
        }
        return c;
    }

    // ==== 其他 ====
    NSArray *all = allPlugins();
    c.textLabel.text = self.pluginFolded ? [NSString stringWithFormat:@"插件收纳隐藏 (%lu 个)", (unsigned long)all.count] : @"插件收纳隐藏";
    c.detailTextLabel.text = self.pluginFolded ? @"点击展开" : @"点击收起";
    c.selectionStyle = UITableViewCellSelectionStyleDefault;
    return c;
}

- (void)toggleDuang:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kDuangKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleGameCheat:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kGameCheatKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleAdBlock:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kAdBlockKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleMsgFilter:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kMsgFilterKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleAutoLogin:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kAutoLoginKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleScreenShot:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kScreenShotHide]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleNoSep:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kNoSeparator]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleHideDND:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kHideDNDIcon]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleSwipeInput:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kSwipeInput]; [[NSUserDefaults standardUserDefaults] synchronize]; }

- (void)togglePlugin:(UISwitch *)s {
    NSArray *all = allPlugins();
    NSInteger idx = s.tag;
    if (idx >= all.count) return;
    NSMutableArray *blk = [blockedPlugins() mutableCopy];
    NSString *title = all[idx];
    if (s.isOn) [blk removeObject:title];
    else if (![blk containsObject:title]) [blk addObject:title];
    [[NSUserDefaults standardUserDefaults] setObject:[blk componentsJoinedByString:@","] forKey:kPluginBlockKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

// ============================================================
// 小信号弹窗 (WCDuang)
// ============================================================

@interface MMContext : NSObject
+ (instancetype)currentContext;
- (NSString *)userName;
@end
@interface CMessageWrap : NSObject
@property (nonatomic, assign) int m_uiMessageType;
@property (nonatomic, copy) NSString *m_nsFromUsr;
@property (nonatomic, assign) unsigned int m_uiStatus;
- (int)yoType;
@end
@interface WCWatchNativeMgr : NSObject
- (void)displaySignalMessageWithDelay:(CMessageWrap *)msg;
@end

%hook WCWatchNativeMgr
- (void)OnMsgNotAddDBNotify:(NSString *)chatName MsgWrap:(CMessageWrap *)msg {
    BOOL should = NO;
    if (pref(kDuangKey) && msg && msg.m_uiMessageType == 63) {
        MMContext *ctx = [%c(MMContext) currentContext];
        NSString *me = [ctx userName];
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

@interface CMessageMgr : NSObject
- (void)AddEmoticonMsg:(NSString *)msg MsgWrap:(CMessageWrap *)msgWrap;
@end

@interface SyncCmdHandler : NSObject
- (_Bool)BatchAddMsg:(_Bool)arg1 ShowPush:(_Bool)arg2;
@end

@interface MultiDeviceCardLoginContentView : UIView
- (void)onTapConfirmButton;
@end

@interface ExtraDeviceLoginViewController : UIViewController
- (void)onConfirmBtnPress:(id)sender;
@end

@interface MMServiceCenter : NSObject
+ (id)defaultCenter;
- (id)getService:(Class)cls;
@end
@interface CMessageWrap (GameExt)
@property (nonatomic, assign) int m_uiGameType;
@property (nonatomic, copy) NSString *m_nsContent;
- (void)setM_nsEmoticonMD5:(NSString *)md5;
- (void)setM_uiGameContent:(int)content;
@end

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
// 去广告
// ============================================================

// 朋友圈视频自动播放
%hook WCFacade
- (bool)isTimelineVideoSightAutoPlayEnable {
    if (pref(kAdBlockKey)) return NO;
    return %orig;
}
%end

// 视频号 / 朋友圈 / 文章广告
@interface WCDataItem : NSObject
- (bool)isVideoAd;
- (bool)isAd;
@end

%hook WCDataItem
- (bool)isVideoAd { if (pref(kAdBlockKey)) return NO; return %orig; }
- (bool)isAd { if (pref(kAdBlockKey)) return NO; return %orig; }
%end

@interface WKCompositingView : UIView
@end

// 公众号文章底部大图广告 (原生层 hook WKCompositingView)
%hook WKCompositingView
- (void)didMoveToSuperview {
    %orig;
    if (!pref(kAdBlockKey)) return;
    // WKCompositingView 的 layerID 包含 CSS class 名，匹配广告关键词
    NSString *desc = self.layer.description;
    if (!desc) return;
    NSArray *adKeywords = @[@"wx_bottom_modal", @"bottom_modal", @"ad_", @"banner", @"sponsor", @"advertisement"];
    for (NSString *kw in adKeywords) {
        if ([desc rangeOfString:kw].location != NSNotFound) {
            self.hidden = YES;
            self.layer.opacity = 0;
            return;
        }
    }
}
%end

// ============================================================
// 消息过滤: 按关键词屏蔽群消息
// ============================================================

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

%hook SyncCmdHandler
- (_Bool)BatchAddMsg:(_Bool)arg1 ShowPush:(_Bool)arg2 {
    NSMutableArray *msgList = [self valueForKey:@"m_arrMsgList"];
    NSMutableArray *filtered = [msgList mutableCopy];
    for (id msg in msgList) {
        if (shouldFilterMsg(msg)) [filtered removeObject:msg];
    }
    [self setValue:filtered forKey:@"m_arrMsgList"];
    return %orig;
}
%end

// ============================================================
// 自动登录: 电脑确认自动点击
// ============================================================

%hook MultiDeviceCardLoginContentView
- (void)layoutSubviews {
    %orig;
    if (pref(kAutoLoginKey)) [self onTapConfirmButton];
}
%end

%hook ExtraDeviceLoginViewController
- (void)viewDidLoad {
    %orig;
    if (pref(kAutoLoginKey)) {
        double delay = ((double)arc4random() / 0x100000000) * 1.2;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self onConfirmBtnPress:[self valueForKey:@"confirmBtn"]];
        });
    }
}
%end

// 小程序开屏广告
@interface WAAppTaskSplashADConfig : NSObject
- (bool)canShowSplashADWindow;
- (bool)launchShow;
@end

%hook WAAppTaskSplashADConfig
- (bool)canShowSplashADWindow { if (pref(kAdBlockKey)) return NO; return %orig; }
- (bool)launchShow { if (pref(kAdBlockKey)) return NO; return %orig; }
%end

// ============================================================
// 截图转发按钮去除
// ============================================================

@interface MMScreenShotForwardButton : UIButton
@end

%hook MMScreenShotForwardButton
- (void)didMoveToSuperview {
    if (pref(kScreenShotHide)) {
        self.hidden = YES;
        if (self.superview) self.superview.hidden = YES;
        return;
    }
    %orig;
}
%end

// ============================================================
// 输入框增强 (MMTextView = 真正的输入框)
// ============================================================

@interface MMTextView : UITextView
@property (nonatomic, copy) NSString *text;
- (void)wxc_clearText;
- (void)wxc_pasteText;
@end

%hook MMTextView
- (void)didMoveToSuperview {
    %orig;
    // 圆角
    if ([roundEnabledClasses() containsObject:NSStringFromClass(self.class)]) {
        self.layer.cornerRadius = roundRadius(NSStringFromClass(self.class));
        self.clipsToBounds = YES;
    }
    // 手势
    if (!pref(kSwipeInput)) return;
    for (UIGestureRecognizer *g in self.gestureRecognizers) {
        if ([g isKindOfClass:[UISwipeGestureRecognizer class]]) return;
    }
    UISwipeGestureRecognizer *l = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(wxc_clearText)];
    l.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:l];
    UISwipeGestureRecognizer *r = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(wxc_pasteText)];
    r.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:r];
}

%new
- (void)wxc_clearText { self.text = @""; }

%new
- (void)wxc_pasteText {
    NSString *paste = [UIPasteboard generalPasteboard].string;
    if (paste.length) self.text = paste;
}
%end

// ============================================================
// 万能圆角
// ============================================================

// 已启用的圆角类名集合
static NSSet<NSString *> *roundEnabledClasses(void) {
    NSString *raw = [[NSUserDefaults standardUserDefaults] stringForKey:kRoundCorners];
    if (!raw.length) return [NSSet set];
    return [NSSet setWithArray:[raw componentsSeparatedByString:@","]];
}

static CGFloat roundRadius(NSString *cls) {
    CGFloat v = [[NSUserDefaults standardUserDefaults] floatForKey:[kRoundRadiusPrefix stringByAppendingString:cls]];
    return v > 0 ? v : 20;
}

// 支持的元素（类名 → 中文名）
static NSDictionary<NSString *, NSString *> *roundElements(void) {
    return @{
        @"MMTextView":              @"聊天输入框",
        @"InputToolContainerView":  @"输入工具容器",
    };
}

// UIView hook removed — modifying corners during didMoveToSuperview caused infinite layout recursion

// 圆角管理页
@implementation WxCraftRoundVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"圆角设置";
    self.view.backgroundColor = [UIColor whiteColor];
    self.enabled = [roundEnabledClasses() mutableCopy];

    self.tv = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tv.delegate = self; self.tv.dataSource = self;
    self.tv.backgroundColor = [UIColor whiteColor];
    self.tv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tv];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 1; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return roundElements().count;
}

- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)s { return 8; }

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSArray *keys = roundElements().allKeys;
    NSString *cls = keys[ip.row];
    NSString *name = roundElements()[cls];
    BOOL on = [self.enabled containsObject:cls];
    CGFloat r = roundRadius(cls);

    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"rr"];
    if (!c) {
        c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"rr"];
    }
    c.textLabel.text = name;
    c.textLabel.font = [UIFont systemFontOfSize:15];
    c.detailTextLabel.text = on ? [NSString stringWithFormat:@"%.0fpt · 已启用", r] : @"已关闭";
    c.detailTextLabel.font = [UIFont systemFontOfSize:12];
    c.selectionStyle = on ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    c.accessoryType = on ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    c.accessoryView = nil;

    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = on;
    sw.tag = ip.row;
    [sw addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
    c.accessoryView = sw;

    return c;
}

- (void)toggle:(UISwitch *)sw {
    NSArray *keys = roundElements().allKeys;
    NSString *cls = keys[sw.tag];
    if (sw.on) [self.enabled addObject:cls]; else [self.enabled removeObject:cls];
    [self save];
    [self.tv reloadData];
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    NSArray *keys = roundElements().allKeys;
    NSString *cls = keys[ip.row];
    if (![self.enabled containsObject:cls]) return;

    NSArray *opts = @[@"4pt", @"6pt", @"8pt", @"10pt", @"12pt", @"14pt", @"16pt", @"18pt", @"20pt", @"24pt", @"28pt", @"32pt"];
    [WxCraftPicker showWithTitle:roundElements()[cls] items:opts handler:^(NSInteger idx) {
        CGFloat vals[] = {4,6,8,10,12,14,16,18,20,24,28,32};
        NSString *key = [kRoundRadiusPrefix stringByAppendingString:cls];
        [[NSUserDefaults standardUserDefaults] setFloat:vals[idx] forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [tv reloadData];
    }];
}

- (void)save {
    [[NSUserDefaults standardUserDefaults] setObject:[self.enabled.allObjects componentsJoinedByString:@","] forKey:kRoundCorners];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end

// ============================================================
// 隐藏免打扰图标
// ============================================================

@interface UIImageView (WxCraftDND)
- (void)wxc_checkDND;
@end

%hook UIImageView
- (void)didMoveToSuperview {
    %orig;
    [self wxc_checkDND];
}

- (void)layoutSubviews {
    %orig;
    [self wxc_checkDND];
}

%new
- (void)wxc_checkDND {
    if (!pref(kHideDNDIcon) || !self.superview) return;
    // 只隐藏铃铛图标（免打扰），不误伤红点徽章
    if (self.frame.size.width < 10 || self.frame.size.height > 14) return;
    // 铃铛在聊天列表 cell 中的固定位置 x≈44
    if (self.frame.origin.x < 42 || self.frame.origin.x > 48) return;
    // 额外检查：铃铛图标通常有特定大小
    if (self.frame.size.width > 14.5 || self.frame.size.height > 14.5) return;
    self.hidden = YES; self.alpha = 0;
}
%end

// ============================================================
// 全局去除分割线
// ============================================================

@interface _UITableViewCellSeparatorView : UIView
@end


%hook _UITableViewCellSeparatorView
- (void)didMoveToSuperview {
    %orig;
    if (pref(kNoSeparator)) self.hidden = YES;
}
%end

// ============================================================
// 插件收纳隐藏 (UI 层过滤已注册的)
// ============================================================

@interface MMTableViewCell : UITableViewCell
@end

%hook MMTableViewCell
- (void)didMoveToSuperview {
    %orig;
    // 只在插件列表页生效
    UIResponder *r = self.superview;
    while (r && ![r isKindOfClass:NSClassFromString(@"WCPluginsViewController")]) r = r.nextResponder;
    if (!r) return;
    for (UIView *sub in self.contentView.subviews) {
        if ([sub isKindOfClass:[UILabel class]]) {
            NSString *t = [(UILabel *)sub text];
            if (t.length && isPluginBlocked(t)) { self.hidden = YES; return; }
        }
    }
}
%end

// ============================================================
// 插件收纳隐藏 (注册层拦截新注册的)
// ============================================================
// ============================================================

@interface WCPluginsMgr : NSObject
+ (instancetype)sharedInstance;
- (void)registerControllerWithTitle:(NSString *)title version:(NSString *)version controller:(NSString *)controller;
- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key;
@end

%hook WCPluginsMgr
- (void)registerControllerWithTitle:(NSString *)title version:(NSString *)version controller:(NSString *)controller {
    addToAllPlugins(title);
    if (!isPluginBlocked(title)) %orig;
}
- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key {
    addToAllPlugins(title);
    if (!isPluginBlocked(title)) %orig;
}
%end

// ============================================================
// 注册自身
// ============================================================

%ctor {
    // 每次启动清空已发现插件缓存，让列表只显示当前注入的插件
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPluginAllKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    Class mgr = NSClassFromString(@"WCPluginsMgr");
    if (mgr) {
        id inst = ((id (*)(id, SEL))objc_msgSend)(mgr, @selector(sharedInstance));
        ((void (*)(id, SEL, NSString *, NSString *, NSString *))objc_msgSend)(
            inst, @selector(registerControllerWithTitle:version:controller:),
            @"WxCraft", @"1.0.0", @"WxCraftSettingsVC");
    }
}
