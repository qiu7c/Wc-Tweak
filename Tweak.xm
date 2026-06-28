// Wc+
// 作者: CC
// 微信增强: 小信号弹窗 + 日月开关 + 游戏作弊 + 插件收纳管理

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <WebKit/WebKit.h>
#import "DayNightSwitch.h"

// ============================================================
// 常量
// ============================================================
static NSString * const kDuangKey       = @"WcPlus_Duang";
static NSString * const kDayNightKey    = @"WcPlus_DayNight";
static NSString * const kGameCheatKey   = @"WcPlus_GameCheat";
static NSString * const kPluginBlockKey = @"WcPlus_PluginBlock";
static NSString * const kPluginAllKey   = @"WcPlus_AllPlugins";
static NSString * const kAdBlockKey    = @"WcPlus_AdBlock";

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

@interface WcPlusPicker : UIView
+ (void)showWithTitle:(NSString *)title items:(NSArray<NSString *> *)items handler:(void (^)(NSInteger idx))handler;
@end

@implementation WcPlusPicker

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
            [btn addTarget:[WcPlusPicker class] action:@selector(handleTap:) forControlEvents:UIControlEventTouchUpInside];
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
    [cancel addTarget:[WcPlusPicker class] action:@selector(handleCancel:) forControlEvents:UIControlEventTouchUpInside];
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

@interface WcPlusSettingsVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISwitch *duangSwitch, *daynightSwitch, *gameCheatSwitch, *adBlockSwitch;
@property (nonatomic) BOOL pluginFolded;
@end

@implementation WcPlusSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Wc+";
    self.view.backgroundColor = [UIColor whiteColor];
    self.pluginFolded = YES;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    [self.view addSubview:self.tableView];

    self.duangSwitch = [[UISwitch alloc] init]; self.duangSwitch.on = pref(kDuangKey);
    [self.duangSwitch addTarget:self action:@selector(toggleDuang:) forControlEvents:UIControlEventValueChanged];
    self.daynightSwitch = [[UISwitch alloc] init]; self.daynightSwitch.on = pref(kDayNightKey);
    [self.daynightSwitch addTarget:self action:@selector(toggleDayNight:) forControlEvents:UIControlEventValueChanged];
    self.gameCheatSwitch = [[UISwitch alloc] init]; self.gameCheatSwitch.on = pref(kGameCheatKey);
    [self.gameCheatSwitch addTarget:self action:@selector(toggleGameCheat:) forControlEvents:UIControlEventValueChanged];
    self.adBlockSwitch = [[UISwitch alloc] init]; self.adBlockSwitch.on = pref(kAdBlockKey);
    [self.adBlockSwitch addTarget:self action:@selector(toggleAdBlock:) forControlEvents:UIControlEventValueChanged];
}

- (void)toggleDuang:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kDuangKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleDayNight:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kDayNightKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleGameCheat:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kGameCheatKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleAdBlock:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kAdBlockKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }

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
    if (s == 0) return 4;
    if (s == 1) return self.pluginFolded ? 1 : (allPlugins().count ? allPlugins().count + 1 : 2);
    return 1;
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
    if (ip.section == 1 && ip.row == 0) {
        self.pluginFolded = !self.pluginFolded;
        [tv reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    // --- 功能 ---
    if (ip.section == 0) {
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
        else { c.textLabel.text = @"去广告"; c.detailTextLabel.text = @"公众号文章 CSS 注入屏蔽"; c.accessoryView = self.adBlockSwitch; }
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
    if (!c) { c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ab"]; c.selectionStyle = UITableViewCellSelectionStyleNone; }
    c.textLabel.text = @"作者"; c.detailTextLabel.text = @"CC"; c.detailTextLabel.textColor = [UIColor blackColor];
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
@interface CMessageWrap (GameExt)
@property (nonatomic, assign) int m_uiGameType;
- (void)setM_nsEmoticonMD5:(NSString *)md5;
- (void)setM_uiGameContent:(int)content;
@end

%hook CMessageMgr
- (void)AddEmoticonMsg:(NSString *)msg MsgWrap:(CMessageWrap *)msgWrap {
    if (pref(kGameCheatKey) && [msgWrap m_uiMessageType] == 47 && ([msgWrap m_uiGameType] == 1 || [msgWrap m_uiGameType] == 2)) {
        // 游戏内容值 1-3=猜拳, 4-9=骰子
        NSArray *items = @[@"剪刀", @"石头", @"布",
                           @"①", @"②", @"③", @"④", @"⑤", @"⑥"];
        [WcPlusPicker showWithTitle:@"选择结果" items:items handler:^(NSInteger idx) {
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
// 去广告: 公众号文章 CSS 注入
// ============================================================

static NSString * const kAdBlockCSS = @":root{--adHide:display:none!important}"
".mpa_ad,.ad_banner,.ad_container,.ad_feedback,#js_ad_area,.rich_media_area_extra,.reward_area,"
"[class*=ad_],[class*=banner],[id*=ad_],[id*=banner],.bottom_ad,.article_ad,.ad_wrap,.ad-box,"
".insert_ad,.ad_iframe,.top_ad,.video_ad,.stream_ad,.ad-card,.ad_footer,.ad_header,.ad_tag,"
".ad-label,.ad-info,.ad-link,.ad_border,.ad_unit,.ad_sponsor,.advertisement,.sponsor_area,"
".mp-article_ad,.recommend_ad,.wx_ad,.wechat_ad,.shop_ad,.promotion_ad,.feed_ad,.adFeed"
"{display:none!important}";

@interface MMWebViewController : UIViewController
@property (nonatomic, strong) WKWebView *m_webView;
- (void)webViewDidFinishLoad:(id)arg1;
@end

%hook MMWebViewController
- (void)webViewDidFinishLoad:(id)arg1 {
    %orig;
    if (!pref(kAdBlockKey)) return;
    WKWebView *wv = [self valueForKey:@"m_webView"];
    if (!wv) wv = [self valueForKey:@"webView"];
    if (!wv) return;
    NSString *js = [NSString stringWithFormat:@"(function(){var s=document.createElement('style');s.textContent='%@';document.head.appendChild(s)})()", kAdBlockCSS];
    [wv evaluateJavaScript:js completionHandler:nil];
}
%end

// ============================================================
// 插件收纳隐藏
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
            @"Wc+", @"1.0.0", @"WcPlusSettingsVC");
    }
}
