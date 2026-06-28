// Wc+
// 作者: CC
// 微信增强: 小信号弹窗 + 日月开关

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "DayNightSwitch.h"

// ============================================================
// 开关 Key
// ============================================================
static NSString * const kDuangKey   = @"WcPlus_Duang";
static NSString * const kDayNightKey = @"WcPlus_DayNight";
static NSString * const kGameCheatKey = @"WcPlus_GameCheat";

static BOOL pref(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

// ============================================================
// 设置页面
// ============================================================

@interface WcPlusSettingsVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISwitch *duangSwitch;
@property (nonatomic, strong) UISwitch *daynightSwitch;
@property (nonatomic, strong) UISwitch *gameCheatSwitch;
@end

@implementation WcPlusSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Wc+";
    self.view.backgroundColor = [UIColor whiteColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    [self.view addSubview:self.tableView];

    self.duangSwitch = [[UISwitch alloc] init];
    self.duangSwitch.on = pref(kDuangKey);
    [self.duangSwitch addTarget:self action:@selector(toggleDuang:) forControlEvents:UIControlEventValueChanged];

    self.daynightSwitch = [[UISwitch alloc] init];
    self.daynightSwitch.on = pref(kDayNightKey);
    [self.daynightSwitch addTarget:self action:@selector(toggleDayNight:) forControlEvents:UIControlEventValueChanged];

    self.gameCheatSwitch = [[UISwitch alloc] init];
    self.gameCheatSwitch.on = pref(kGameCheatKey);
    [self.gameCheatSwitch addTarget:self action:@selector(toggleGameCheat:) forControlEvents:UIControlEventValueChanged];
}

- (void)toggleDuang:(UISwitch *)s  { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kDuangKey];  [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleDayNight:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kDayNightKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }
- (void)toggleGameCheat:(UISwitch *)s { [[NSUserDefaults standardUserDefaults] setBool:s.isOn forKey:kGameCheatKey]; [[NSUserDefaults standardUserDefaults] synchronize]; }

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv { return 2; }
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s { return s == 0 ? 3 : 1; }

- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)s { return 36; }
- (CGFloat)tableView:(UITableView *)tv heightForFooterInSection:(NSInteger)s { return 4; }

- (UIView *)tableView:(UITableView *)tv viewForHeaderInSection:(NSInteger)s {
    UIView *h = [[UIView alloc] init];
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, tv.frame.size.width-32, 20)];
    lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    lbl.textColor = [UIColor grayColor];
    lbl.text = (s == 0) ? @"功能" : @"关于";
    [h addSubview:lbl];
    return h;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section == 0) {
        UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"fn"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"fn"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.font = [UIFont systemFontOfSize:16];
            cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
        if (ip.row == 0) {
            cell.textLabel.text = @"小信号弹窗 (Duang)";
            cell.detailTextLabel.text = @"恢复微信 8.0.31+ 召唤弹窗";
            cell.accessoryView = self.duangSwitch;
        } else if (ip.row == 1) {
            cell.textLabel.text = @"日月开关";
            cell.detailTextLabel.text = @"将 UISwitch 改为日月动画样式";
            cell.accessoryView = self.daynightSwitch;
        } else {
            cell.textLabel.text = @"游戏作弊";
            cell.detailTextLabel.text = @"骰子/猜拳 想几点就几点";
            cell.accessoryView = self.gameCheatSwitch;
        }
        return cell;
    }

    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"ab"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ab"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = @"作者";
    cell.detailTextLabel.text = @"CC";
    cell.detailTextLabel.textColor = [UIColor blackColor];
    return cell;
}

@end

// ============================================================
// 小信号弹窗 Hook (WCDuang)
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
        BOOL fromSelf = [msg.m_nsFromUsr isEqualToString:me];
        BOOL read = (msg.m_uiStatus == 4);
        BOOL replyYo = ([msg yoType] == 1);
        should = !fromSelf && !read && !replyYo;
    }
    %orig;
    if (should) {
        CMessageWrap *h = msg;
        dispatch_async(dispatch_get_main_queue(), ^{ [self displaySignalMessageWithDelay:h]; });
    }
}
%end

// ============================================================
// 日月开关 Hook (DayNightSwitch)
// ============================================================

%hook UISwitch
- (void)didMoveToSuperview {
    %orig;
    if (!pref(kDayNightKey)) return;

    DayNightSwitch *ds = [[DayNightSwitch alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    ds.on = self.on;
    ds.changeAction = ^(BOOL on) {
        self.on = on;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    };
    self.layer.opacity = 0;
    self.layer.shadowOpacity = 0;
    [self addSubview:ds];
}
%end

// ============================================================
// 游戏作弊: 骰子/猜拳可选点数
// ============================================================

@interface CMessageMgr : NSObject
- (void)AddEmoticonMsg:(NSString *)msg MsgWrap:(CMessageWrap *)msgWrap;
@end

@interface GameController : NSObject
+ (NSString *)getMD5ByGameContent:(int)content;
@end

@interface CMessageWrap (GameExt)
@property (nonatomic, assign) int m_uiGameType;
@property (nonatomic, assign) int m_uiGameContent;
@property (nonatomic, copy) NSString *m_nsEmoticonMD5;
- (void)setM_nsEmoticonMD5:(NSString *)md5;
- (void)setM_uiGameContent:(int)content;
@end

%hook CMessageMgr
- (void)AddEmoticonMsg:(NSString *)msg MsgWrap:(CMessageWrap *)msgWrap {
    if (pref(kGameCheatKey) && ([msgWrap m_uiMessageType] == 47 && ([msgWrap m_uiGameType] == 2 || [msgWrap m_uiGameType] == 1))) {
        NSString *title = [msgWrap m_uiGameType] == 1 ? @"请选择" : @"请选择点数";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"游戏作弊"
                                                                       message:title
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        NSArray *items = @[@"剪刀", @"石头", @"布", @"1", @"2", @"3", @"4", @"5", @"6"];
        int start = [msgWrap m_uiGameType] == 1 ? 0 : 3;
        int end   = [msgWrap m_uiGameType] == 1 ? 3 : 9;
        for (int i = start; i < end; i++) {
            UIAlertAction *act = [UIAlertAction actionWithTitle:items[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction *_) {
                [msgWrap setM_nsEmoticonMD5:[objc_getClass("GameController") getMD5ByGameContent:i + 1]];
                [msgWrap setM_uiGameContent:i + 1];
                %orig(msg, msgWrap);
            }];
            [alert addAction:act];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        UIWindow *kw = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                kw = scene.windows.firstObject; break;
            }
        }
        if (!kw) kw = [UIApplication sharedApplication].windows.firstObject;
        [kw.rootViewController presentViewController:alert animated:YES completion:nil];
        return;
    }
    %orig;
}
%end

// ============================================================
// 注册
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
