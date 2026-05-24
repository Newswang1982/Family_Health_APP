// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '家庭健康';

  @override
  String get navHome => '首页';

  @override
  String get navRecords => '记录';

  @override
  String get navCharts => '图表';

  @override
  String get navDevices => '设备';

  @override
  String get navSettings => '设置';

  @override
  String get loginTitle => '家庭健康';

  @override
  String get loginSubtitle => '登录以管理您的家庭健康';

  @override
  String get loginPhoneHint => '手机号 / 邮箱';

  @override
  String get loginPasswordHint => '密码';

  @override
  String get loginButton => '登录';

  @override
  String get loginNoAccount => '还没有账号？立即注册';

  @override
  String get loginWeChat => '微信';

  @override
  String get loginQQ => 'QQ';

  @override
  String get loginEmail => '邮箱';

  @override
  String get loginOtherWays => '其他登录方式';

  @override
  String get registerTitle => '注册';

  @override
  String get registerNickname => '昵称';

  @override
  String get registerPhone => '手机号';

  @override
  String get registerEmail => '邮箱';

  @override
  String get registerPassword => '密码';

  @override
  String get registerConfirmPwd => '确认密码';

  @override
  String get registerButton => '注册';

  @override
  String get registerHaveAccount => '已有账号？立即登录';

  @override
  String homeGreeting(Object timeOfDay) {
    return '$timeOfDay';
  }

  @override
  String get homeHeartRate => '心率';

  @override
  String get homeSteps => '步数';

  @override
  String get homeSleep => '睡眠';

  @override
  String get homeQuickRecord => '快速记录';

  @override
  String get homeSmartDevice => '智能设备';

  @override
  String get homeNotConnected => '未连接';

  @override
  String get homeConnect => '连接';

  @override
  String get homeRecentRecords => '最近记录';

  @override
  String get recordSleep => '睡眠';

  @override
  String get recordSmoking => '吸烟';

  @override
  String get recordDrinking => '饮酒';

  @override
  String get recordWorkPosture => '工作姿态';

  @override
  String get recordDiet => '饮食';

  @override
  String get recordSugar => '糖分';

  @override
  String get recordFoodDetail => '精细饮食';

  @override
  String get recordEnvironment => '环境危害';

  @override
  String get recordVitals => '体征';

  @override
  String get recordNoData => '暂无数据';

  @override
  String get recordToday => '今天';

  @override
  String get recordSave => '保存';

  @override
  String get recordCancel => '取消';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsFamily => '家庭管理';

  @override
  String get settingsFamilyMembers => '家庭成员';

  @override
  String get settingsReferenceRanges => '健康参考值';

  @override
  String get settingsNotifications => '通知设置';

  @override
  String get settingsDataMgmt => '数据管理';

  @override
  String get settingsServer => '服务器设置';

  @override
  String get settingsAccountLink => '账号关联';

  @override
  String get settingsWeChat => '微信';

  @override
  String get settingsQQ => 'QQ';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsLogoutConfirm => '确定要退出登录吗？';

  @override
  String get deviceScan => '扫描新设备';

  @override
  String get deviceNoDevice => '未找到设备';

  @override
  String get deviceScanning => '扫描中...';

  @override
  String get deviceBound => '已绑定';

  @override
  String get deviceUnbind => '解绑';

  @override
  String get chartKLine => 'K线图';

  @override
  String get chartStatistics => '统计';

  @override
  String get chartMean => '均值';

  @override
  String get chartMedian => '中位数';

  @override
  String get chartReport => '健康报告';

  @override
  String get chartGenerate => '生成健康报告';

  @override
  String get chartShare => '分享';

  @override
  String get serverLocal => '本地';

  @override
  String get serverCloud => '云端';

  @override
  String get serverSwitch => '切换';

  @override
  String get serverCancel => '取消';

  @override
  String get timeMorning => '早上好';

  @override
  String get timeAfternoon => '下午好';

  @override
  String get timeEvening => '晚上好';

  @override
  String get timeNight => '夜深了';

  @override
  String get errorNetwork => '无法连接到服务器';

  @override
  String get errorTimeout => '连接超时';

  @override
  String get errorGeneric => '发生错误';

  @override
  String get errorPhoneRegistered => '手机号已注册';

  @override
  String get errorEmailRegistered => '邮箱已注册';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get add => '添加';

  @override
  String get create => '创建';

  @override
  String get bind => '绑定';

  @override
  String get unbind => '解绑';

  @override
  String get backup => '备份';

  @override
  String get restore => '恢复';

  @override
  String get comingSoon => '即将上线';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw(): super('zh_TW');

  @override
  String get appTitle => '家庭健康';

  @override
  String get navHome => '首頁';

  @override
  String get navRecords => '記錄';

  @override
  String get navCharts => '圖表';

  @override
  String get navDevices => '設備';

  @override
  String get navSettings => '設置';

  @override
  String get loginTitle => '家庭健康';

  @override
  String get loginSubtitle => '登錄以管理您的家庭健康';

  @override
  String get loginPhoneHint => '手機號 / 郵箱';

  @override
  String get loginPasswordHint => '密碼';

  @override
  String get loginButton => '登錄';

  @override
  String get loginNoAccount => '還沒有賬號？立即註冊';

  @override
  String get loginWeChat => '微信';

  @override
  String get loginQQ => 'QQ';

  @override
  String get loginEmail => '郵箱';

  @override
  String get loginOtherWays => '其他登錄方式';

  @override
  String get registerTitle => '註冊';

  @override
  String get registerNickname => '暱稱';

  @override
  String get registerPhone => '手機號';

  @override
  String get registerEmail => '郵箱';

  @override
  String get registerPassword => '密碼';

  @override
  String get registerConfirmPwd => '確認密碼';

  @override
  String get registerButton => '註冊';

  @override
  String get registerHaveAccount => '已有賬號？立即登錄';

  @override
  String homeGreeting(Object timeOfDay) {
    return '$timeOfDay';
  }

  @override
  String get homeHeartRate => '心率';

  @override
  String get homeSteps => '步數';

  @override
  String get homeSleep => '睡眠';

  @override
  String get homeQuickRecord => '快速記錄';

  @override
  String get homeSmartDevice => '智能設備';

  @override
  String get homeNotConnected => '未連接';

  @override
  String get homeConnect => '連接';

  @override
  String get homeRecentRecords => '最近記錄';

  @override
  String get recordSleep => '睡眠';

  @override
  String get recordSmoking => '吸煙';

  @override
  String get recordDrinking => '飲酒';

  @override
  String get recordWorkPosture => '工作姿態';

  @override
  String get recordDiet => '飲食';

  @override
  String get recordSugar => '糖分';

  @override
  String get recordFoodDetail => '精細飲食';

  @override
  String get recordEnvironment => '環境危害';

  @override
  String get recordVitals => '體徵';

  @override
  String get recordNoData => '暫無數據';

  @override
  String get recordToday => '今天';

  @override
  String get recordSave => '保存';

  @override
  String get recordCancel => '取消';

  @override
  String get settingsTitle => '設置';

  @override
  String get settingsFamily => '家庭管理';

  @override
  String get settingsFamilyMembers => '家庭成員';

  @override
  String get settingsReferenceRanges => '健康參考值';

  @override
  String get settingsNotifications => '通知設置';

  @override
  String get settingsDataMgmt => '數據管理';

  @override
  String get settingsServer => '服務器設置';

  @override
  String get settingsAccountLink => '賬號關聯';

  @override
  String get settingsWeChat => '微信';

  @override
  String get settingsQQ => 'QQ';

  @override
  String get settingsLogout => '退出登錄';

  @override
  String get settingsLogoutConfirm => '確定要退出登錄嗎？';

  @override
  String get deviceScan => '掃描新設備';

  @override
  String get deviceNoDevice => '未找到設備';

  @override
  String get deviceScanning => '掃描中...';

  @override
  String get deviceBound => '已綁定';

  @override
  String get deviceUnbind => '解綁';

  @override
  String get chartKLine => 'K線圖';

  @override
  String get chartStatistics => '統計';

  @override
  String get chartMean => '均值';

  @override
  String get chartMedian => '中位數';

  @override
  String get chartReport => '健康報告';

  @override
  String get chartGenerate => '生成健康報告';

  @override
  String get chartShare => '分享';

  @override
  String get serverLocal => '本地';

  @override
  String get serverCloud => '雲端';

  @override
  String get serverSwitch => '切換';

  @override
  String get serverCancel => '取消';

  @override
  String get timeMorning => '早上好';

  @override
  String get timeAfternoon => '下午好';

  @override
  String get timeEvening => '晚上好';

  @override
  String get timeNight => '夜深了';

  @override
  String get errorNetwork => '無法連接到服務器';

  @override
  String get errorTimeout => '連接超時';

  @override
  String get errorGeneric => '發生錯誤';

  @override
  String get errorPhoneRegistered => '手機號已註冊';

  @override
  String get errorEmailRegistered => '郵箱已註冊';

  @override
  String get confirm => '確認';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '刪除';

  @override
  String get edit => '編輯';

  @override
  String get add => '添加';

  @override
  String get create => '創建';

  @override
  String get bind => '綁定';

  @override
  String get unbind => '解綁';

  @override
  String get backup => '備份';

  @override
  String get restore => '恢復';

  @override
  String get comingSoon => '即將上線';
}
