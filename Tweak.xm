// ForeignAppEnhancer
// 作者: CC
// 功能: 重新启用小信号弹窗 + 更多增强

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ============================================================
// 开关 Key（与 WCPluginsMgr 注册的 key 一致）
// ============================================================
static NSString * const kDuangSwitchKey = @"WCDuang_Switch";

// 读取开关状态
static BOOL isDuangEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDuangSwitchKey];
}

// ============================================================
// 设置页面
// ============================================================

@interface ForeignSettingsVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation ForeignSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ForeignAppEnhancer";
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 2;
    if (section == 1) return 1;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"作者";
    if (section == 1) return @"功能";
    return @"关于";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cid = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cid];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"作者";
            cell.detailTextLabel.text = @"CC";
        } else {
            cell.textLabel.text = @"联系方式";
            cell.detailTextLabel.text = @"js8887@126.com";
        }
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"小信号弹窗 (Duang)";
        cell.detailTextLabel.text = isDuangEnabled() ? @"已开启" : @"已关闭";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        cell.textLabel.text = @"版本";
        cell.detailTextLabel.text = @"1.0.0";
    }

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
// 注册到 WCPluginsMgr
// ============================================================

%ctor {
    Class mgr = NSClassFromString(@"WCPluginsMgr");
    if (mgr) {
        id instance = ((id (*)(id, SEL))objc_msgSend)(mgr, @selector(sharedInstance));

        // 注册设置页面
        ((void (*)(id, SEL, NSString *, NSString *, NSString *))objc_msgSend)(
            instance,
            @selector(registerControllerWithTitle:version:controller:),
            @"ForeignAppEnhancer",
            @"1.0.0",
            @"ForeignSettingsVC"
        );

        // 注册小信号开关
        ((void (*)(id, SEL, NSString *, NSString *))objc_msgSend)(
            instance,
            @selector(registerSwitchWithTitle:key:),
            @"小信号弹窗 (Duang)",
            kDuangSwitchKey
        );
    }
}
