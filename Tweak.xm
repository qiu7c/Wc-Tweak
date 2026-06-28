// ForeignAppEnhancer
// 作者: CC
// 增强国外 App

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 2 : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"作者" : @"关于";
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
    } else {
        cell.textLabel.text = @"版本";
        cell.detailTextLabel.text = @"1.0.0";
    }

    return cell;
}

@end

// ============================================================
// 注册到 WCPluginsMgr
// ============================================================

%ctor {
    if (NSClassFromString(@"WCPluginsMgr")) {
        [[objc_getClass("WCPluginsMgr") sharedInstance]
            registerControllerWithTitle:@"ForeignAppEnhancer"
            version:@"1.0.0"
            controller:@"ForeignSettingsVC"];
    }
}

// ============================================================
// Hook 增强逻辑（在下面写你要 Hook 的内容）
// ============================================================

// %hook SomeViewController
// - (void)viewDidLoad { %orig; }
// %end
