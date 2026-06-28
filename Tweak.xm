// Wc+
// 作者: CC
// 微信增强插件

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString * const kDuangSwitchKey = @"WcPlus_Duang_Switch";

static BOOL isDuangEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDuangSwitchKey];
}

// ============================================================
// 设置页面（开关内置）
// ============================================================

@interface WcPlusSettingsVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISwitch *duangSwitch;
@end

@implementation WcPlusSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Wc+";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];

    self.duangSwitch = [[UISwitch alloc] init];
    self.duangSwitch.on = isDuangEnabled();
    [self.duangSwitch addTarget:self action:@selector(duangToggled:) forControlEvents:UIControlEventValueChanged];
}

- (void)duangToggled:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:kDuangSwitchKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 2 : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"功能" : @"关于";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"duang"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"duang"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = @"小信号弹窗 (Duang)";
                cell.accessoryView = self.duangSwitch;
            }
            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"info"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"info"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            cell.textLabel.text = @"说明";
            cell.detailTextLabel.text = @"恢复微信 8.0.31+ 小信号弹窗";
            return cell;
        }
    }

    // 关于
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"about"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"about"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = @"作者";
    cell.detailTextLabel.text = @"CC";
    return cell;
}

@end

// ============================================================
// WCDuang: 小信号弹窗 Hook
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
    BOOL shouldDisplay = NO;

    if (isDuangEnabled() && msg && msg.m_uiMessageType == 63) {
        MMContext *context = [%c(MMContext) currentContext];
        NSString *me = [context userName];
        BOOL fromSelf = [msg.m_nsFromUsr isEqualToString:me];
        BOOL alreadyRead = (msg.m_uiStatus == 4);
        BOOL isReplyYo = ([msg yoType] == 1);
        shouldDisplay = !fromSelf && !alreadyRead && !isReplyYo;
    }

    %orig;

    if (shouldDisplay) {
        CMessageWrap *hold = msg;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self displaySignalMessageWithDelay:hold];
        });
    }
}

%end

// ============================================================
// 注册
// ============================================================

%ctor {
    Class mgr = NSClassFromString(@"WCPluginsMgr");
    if (mgr) {
        id instance = ((id (*)(id, SEL))objc_msgSend)(mgr, @selector(sharedInstance));
        ((void (*)(id, SEL, NSString *, NSString *, NSString *))objc_msgSend)(
            instance,
            @selector(registerControllerWithTitle:version:controller:),
            @"Wc+",
            @"1.0.0",
            @"WcPlusSettingsVC"
        );
    }
}
