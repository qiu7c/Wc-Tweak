// WxCraft
// 作者: CC
// 微信增强: 小信号弹窗 + 日月开关 + 游戏作弊 + 插件收纳管理

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "DayNightSwitch.h"

// ============================================================
// 常量
// ============================================================
static NSString * const kDuangKey       = @"WxCraft_Duang";
static NSString * const kDayNightKey    = @"WxCraft_DayNight";
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
static BOOL isSeparatorView(UIView *v);

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
@property (nonatomic, strong) UISwitch *duangSwitch, *daynightSwitch, *gameCheatSwitch, *adBlockSwitch, *msgFilterSwitch, *autoLoginSwitch, *screenshotSwitch, *noSepSwitch;
@property (nonatomic) BOOL pluginFolded;
@property (nonatomic) NSInteger versionTapCount;
@end

@implementation WxCraftSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"WxCraft";
    self.view.backgroundColor = [UIColor whiteColor];
    self.pluginFolded = YES;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];

    self.duangSwitch = [[UISwitch alloc] init]; self.duangSwitch.on = pref(kDuangKey);
    [self.duangSwitch addTarget:self action:@selector(toggleDuang:) forControlEvents:UIControlEventValueChanged];
    self.daynightSwitch = [[UISwitch alloc] init]; self.daynightSwitch.on = pref(kDayNightKey);
    [self.daynightSwitch addTarget:self action:@selector(toggleDayNight:) forControlEvents:UIControlEventValueChanged];
    self.gameCheatSwitch = [[UISwitch alloc] init]; self.gameCheatSwitch.on = pref(kGameCheatKey);
    [self.gameCheatSwitch addTarget:self action:@selector(toggleGameCheat:) forControlEvents:UIControlEventValueChanged];
    self.adBlockSwitch = [[UISwitch alloc] init]; self.adBlockSwitch.on = pref(kAdBlockKey);
    [self.adBlockSwitch addTarget:self action:@selector(toggleAdBlock:) forControlEvents:UIControlEventValueChanged];
    self.msgFilterSwitch = [[UISwitch alloc] init]; self.msgFilterSwitch.on = pref(kMsgFilterKey);
    [self.msgFilterSwitch addTarget:self action:@selector(toggleMsgFilter:) forControlEvents:UIControlEventValueChanged];
    self.autoLoginSwitch = [[UISwitch alloc] init]; self.autoLoginSwitch.on = pref(kAutoLoginKey);
    [self.autoLoginSwitch addTarget:self action:@selector(toggleAutoLogin:) forControlEvents:UIControlEventValueChanged];
    self.screenshotSwitch = [[UISwitch alloc] init]; self.screenshotSwitch.on = pref(kScreenShotHide);
    [self.screenshotSwitch addTarget:self action:@selector(toggleScreenShot:) forControlEvents:UIControlEventValueChanged];
    self.noSepSwitch = [[UISwitch alloc] init]; self.noSepSwitch.on = pref(kNoSeparator);
    [self.noSepSwitch addTarget:self action:@selector(toggleNoSep:) forControlEvents:UIControlEventValueChanged];
}

- (void)toggleDuang:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kDuangKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleDayNight:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kDayNightKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleGameCheat:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kGameCheatKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleAdBlock:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kAdBlockKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleMsgFilter:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kMsgFilterKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleAutoLogin:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kAutoLoginKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleScreenShot:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kScreenShotHide]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleNoSep:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kNoSeparator]; [[NSUserDefaults standardUserDefaults] synchronize]; }

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 3; }

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    if (s == 0) return 9;
    if (s == 1) return self.pluginFolded ? 1 : (allPlugins().count ? allPlugins().count + 1 : 2);
    return 3;
}

- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)s { return 40; }
- (CGFloat)tableView:(UITableView *)tv heightForFooterInSection:(NSInteger)s { return (s == 1 && !self.pluginFolded) ? 28 : 4; }

- (UIView *)tableView:(UITableView *)tv viewForHeaderInSection:(NSInteger)s {
    UIView *h = [[UIView alloc] init];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, tv.frame.size.width - 32, 18)];
    l.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    l.textColor = [UIColor grayColor];
    if (s == 0) l.text = @"功能";
    else if (s == 1) l.text = @"插件收纳隐藏";
    else l.text = @"关于";
    [h addSubview:l];
    return h;
}

- (UIView *)tableView:(UITableView *)tv viewForFooterInSection:(NSInteger)s {
    if (s != 1 || self.pluginFolded) return nil;
    UIView *f = [[UIView alloc] init];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(16, 4, tv.frame.size.width - 32, 20)];
    l.font = [UIFont systemFontOfSize:11];
    l.textColor = [UIColor systemRedColor];
    l.text = @"⚠️ 需重启微信生效";
    [f addSubview:l];
    return f;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    if (ip.section == 0 && ip.row == 7) {
        [self.navigationController pushViewController:[[WxCraftRoundVC alloc] init] animated:YES];
    }
    if (ip.section == 0 && ip.row == 4) {
        [self.navigationController pushViewController:[[WxCraftKeywordVC alloc] init] animated:YES];
    }
    if (ip.section == 1 && ip.row == 0) {
        self.pluginFolded = !self.pluginFolded;
        [tv reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
    if (ip.section == 2 && ip.row == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            Class MMServiceCenter = objc_getClass("MMServiceCenter");
            Class CContactMgr = objc_getClass("CContactMgr");
            Class ContactInfoViewController = objc_getClass("ContactInfoViewController");
            if (MMServiceCenter && CContactMgr && ContactInfoViewController) {
                id service = [MMServiceCenter defaultCenter];
                id contactMgr = ((id (*)(id, SEL, Class))objc_msgSend)(service, @selector(getService:), CContactMgr);
                id contact = ((id (*)(id, SEL, NSString *))objc_msgSend)(contactMgr, @selector(getContactByName:), @"wxid_ntutupipyxtq22");
                if (contact) {
                    UIViewController *infoVC = [[ContactInfoViewController alloc] init];
                    ((void (*)(id, SEL, id))objc_msgSend)(infoVC, @selector(setM_contact:), contact);
                    [self.navigationController pushViewController:infoVC animated:YES];
                }
            }
        });
    }
    if (ip.section == 2 && ip.row == 2) {
        self.versionTapCount++;
        if (self.versionTapCount >= 5) {
            self.versionTapCount = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                id service = [objc_getClass("MMServiceCenter") defaultCenter];
                id contactMgr = ((id (*)(id, SEL, Class))objc_msgSend)(service, @selector(getService:), objc_getClass("CContactMgr"));
                id selfContact = ((id (*)(id, SEL))objc_msgSend)(contactMgr, @selector(getSelfContact));
                NSString *wxid = ((NSString *(*)(id, SEL))objc_msgSend)(selfContact, @selector(m_nsUsrName));
                if (wxid) {
                    [[UIPasteboard generalPasteboard] setString:wxid];
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"已复制" message:[NSString stringWithFormat:@"wxid: %@\n已复制到剪贴板", wxid] preferredStyle:UIAlertControllerStyleAlert];
                    [ac addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:ac animated:YES completion:nil];
                }
            });
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.versionTapCount = 0;
        });
    }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    // --- 功能 ---
    if (ip.section == 0) {
        if (ip.row == 4) {
            // 消息过滤: 开关 + 关键词入口
            UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"filter"];
            if (!c) {
                c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"filter"];
                c.textLabel.font = [UIFont systemFontOfSize:16];
                c.detailTextLabel.font = [UIFont systemFontOfSize:11];
            }
            c.textLabel.text = @"消息过滤";
            NSInteger cnt = filterKeywords().count;
            c.detailTextLabel.text = cnt ? [NSString stringWithFormat:@"%ld 个关键词 >", (long)cnt] : @"未设置关键词 >";
            c.detailTextLabel.textColor = [UIColor grayColor];
            c.accessoryView = self.msgFilterSwitch;
            c.selectionStyle = UITableViewCellSelectionStyleDefault;
            return c;
        }
        UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"fn"];
        if (!c) {
            c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"fn"];
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            c.textLabel.font = [UIFont systemFontOfSize:16];
            c.detailTextLabel.font = [UIFont systemFontOfSize:12];
            c.detailTextLabel.textColor = [UIColor grayColor];
        }
        if (ip.row == 0) { c.textLabel.text = @"小信号弹窗 (Duang)"; c.detailTextLabel.text = @"恢复微信 8.0.31+ 召唤弹窗"; c.accessoryView = self.duangSwitch; }
        else if (ip.row == 1) { c.textLabel.text = @"日月开关"; c.detailTextLabel.text = @"UISwitch 日月动画样式"; c.accessoryView = self.daynightSwitch; }
        else if (ip.row == 2) { c.textLabel.text = @"游戏作弊"; c.detailTextLabel.text = @"骰子/猜拳可选点数"; c.accessoryView = self.gameCheatSwitch; }
        else if (ip.row == 3) { c.textLabel.text = @"去广告"; c.detailTextLabel.text = @"朋友圈 / 文章 / 小程序"; c.accessoryView = self.adBlockSwitch; }
        else if (ip.row == 5) { c.textLabel.text = @"自动登录"; c.detailTextLabel.text = @"电脑登录自动确认"; c.accessoryView = self.autoLoginSwitch; }
        else if (ip.row == 6) { c.textLabel.text = @"截图转发按钮"; c.detailTextLabel.text = @"去除截图后的小按钮"; c.accessoryView = self.screenshotSwitch; }
        else if (ip.row == 7) {
            c.textLabel.text = @"圆角设置";
            c.detailTextLabel.text = @"自定义 UI 圆角 >";
            c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            c.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else { c.textLabel.text = @"去除分割线"; c.detailTextLabel.text = @"全局隐藏列表分割线"; c.accessoryView = self.noSepSwitch; }
        return c;
    }
    // --- 插件收纳 ---
    if (ip.section == 1) {
        if (ip.row == 0) {
            UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"fold"];
            if (!c) {
                c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"fold"];
                c.selectionStyle = UITableViewCellSelectionStyleNone;
                c.textLabel.font = [UIFont systemFontOfSize:14];
                c.detailTextLabel.font = [UIFont systemFontOfSize:12];
            }
            NSArray *all = allPlugins();
            c.textLabel.text = self.pluginFolded ? [NSString stringWithFormat:@"▶ 已收纳 %lu 个插件", (unsigned long)all.count] : @"▼ 展开列表";
            c.detailTextLabel.text = @"";
            c.accessoryView = nil;
            c.accessoryType = UITableViewCellAccessoryNone;
            c.selectionStyle = UITableViewCellSelectionStyleDefault;
            return c;
        }
        NSArray *all = allPlugins();
        if (all.count == 0) {
            UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"noplug"];
            if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"noplug"]; c.selectionStyle = UITableViewCellSelectionStyleNone; }
            c.textLabel.text = @"暂未发现其他插件"; c.textLabel.font = [UIFont systemFontOfSize:13]; c.textLabel.textColor = [UIColor grayColor];
            return c;
        }
        if (ip.row == all.count + 1) {
            UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"hint"];
            if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"hint"]; c.selectionStyle = UITableViewCellSelectionStyleNone; }
            c.textLabel.text = @"⚠️ 需重启微信生效"; c.textLabel.font = [UIFont systemFontOfSize:11]; c.textLabel.textColor = [UIColor systemRedColor];
            return c;
        }
        NSString *title = all[ip.row - 1];
        UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"blk"];
        if (!c) {
            c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"blk"];
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            c.textLabel.font = [UIFont systemFontOfSize:13];
        }
        c.textLabel.text = title;
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = !isPluginBlocked(title);
        sw.tag = ip.row - 1;
        [sw addTarget:self action:@selector(togglePlugin:) forControlEvents:UIControlEventValueChanged];
        c.accessoryView = sw;
        return c;
    }
    // --- 关于 ---
    UITableViewCell *c = [tv dequeueReusableCellWithIdentifier:@"ab"];
    if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ab"]; }
    c.textLabel.textColor = [UIColor blackColor];
    c.detailTextLabel.textColor = [UIColor blackColor];
    c.accessoryView = nil;
    if (ip.row == 0) {
        c.textLabel.text = @"作者";
        c.detailTextLabel.text = @"Cc";
        c.selectionStyle = UITableViewCellSelectionStyleDefault;
        c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (ip.row == 1) {
        c.textLabel.text = @"声明";
        c.detailTextLabel.text = @"仅供自己使用学习交流";
        c.selectionStyle = UITableViewCellSelectionStyleNone;
        c.accessoryType = UITableViewCellAccessoryNone;
    } else {
        c.textLabel.text = @"版本";
        c.detailTextLabel.text = @"1.0.0";
        c.selectionStyle = UITableViewCellSelectionStyleNone;
        c.accessoryType = UITableViewCellAccessoryNone;
    }
    return c;
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
// 日月开关 (DayNightSwitch)
// ============================================================

%hook UISwitch
- (void)didMoveToSuperview {
    %orig;
    if (!pref(kDayNightKey)) return;
    DayNightSwitch *ds = [[DayNightSwitch alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    ds.on = self.on;
    ds.changeAction = ^(BOOL on) { self.on = on; [self sendActionsForControlEvents:UIControlEventValueChanged]; };
    self.layer.opacity = 0;
    self.layer.shadowOpacity = 0;
    [self addSubview:ds];
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
        @"MMGrowTextView":          @"聊天输入框",
        @"InputToolContainerView":  @"输入工具容器",
    };
}

%hook UIView
- (void)didMoveToSuperview {
    %orig;
    if (!self.superview) return;

    // 全局分割线隐藏
    if (pref(kNoSeparator) && ![self isKindOfClass:[UITableViewCell class]] && isSeparatorView(self)) {
        self.hidden = YES;
        return;
    }

    // 自定义圆角
    NSString *cls = NSStringFromClass(self.class);
    if ([roundEnabledClasses() containsObject:cls]) {
        CGFloat r = roundRadius(cls);
        self.layer.cornerRadius = r;
        self.clipsToBounds = YES;
        if ([cls isEqualToString:@"InputToolContainerView"]) {
            self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        }
    }
}
%end

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
// 全局去除分割线
// ============================================================

@interface _UITableViewCellSeparatorView : UIView
@end

static BOOL isSeparatorView(UIView *v) {
    CGFloat h = v.frame.size.height;
    CGFloat pw = v.superview.frame.size.width;
    if (h > 0 && h <= 1.5 && v.frame.size.width >= pw - 10) return YES;
    // UIVisualEffectView 型分割线
    if ([NSStringFromClass(v.class) containsString:@"Separator"]) return YES;
    return NO;
}

%hook _UITableViewCellSeparatorView
- (void)didMoveToSuperview {
    if (pref(kNoSeparator)) { self.hidden = YES; return; }
    %orig;
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
    Class mgr = NSClassFromString(@"WCPluginsMgr");
    if (mgr) {
        id inst = ((id (*)(id, SEL))objc_msgSend)(mgr, @selector(sharedInstance));
        ((void (*)(id, SEL, NSString *, NSString *, NSString *))objc_msgSend)(
            inst, @selector(registerControllerWithTitle:version:controller:),
            @"WxCraft", @"1.0.0", @"WxCraftSettingsVC");
    }
}
