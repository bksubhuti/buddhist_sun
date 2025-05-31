// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get buddhistSun => '佛日';

  @override
  String get noon => '正午';

  @override
  String get dawn => '明相';

  @override
  String get timer => '计时器';

  @override
  String get gps => 'GPS';

  @override
  String get settings => '设置';

  @override
  String get help => '帮助';

  @override
  String get about => '关于';

  @override
  String get licenses => '许可';

  @override
  String get not_set => '未设置';

  @override
  String get solar_noon => '日中时分';

  @override
  String get gmt_offset => 'GMT 偏移';

  @override
  String get hours => '小时';

  @override
  String get astronomical_twilight => '天文曙光';

  @override
  String get nautical_twilight => '航海曙光';

  @override
  String get civil_twilight => '民用曙光';

  @override
  String get sunrise => '日出';

  @override
  String get date => '日期';

  @override
  String get current_time => '现在时间';

  @override
  String get late => '已过';

  @override
  String get time_left => '剩余时间';

  @override
  String get speech_notify => '语音提示';

  @override
  String get screen_always_on => '屏幕常亮';

  @override
  String get speech_in_background => '后台语音';

  @override
  String get volume => '音量';

  @override
  String get press_wait => '按下等待新的 GPS.';

  @override
  String get get_gps => '获取GPS';

  @override
  String get save_gps => '保存GPS';

  @override
  String get set_gps_city => '网络设置GPS城市名称';

  @override
  String get previous_gps_is => '以前的GPS是';

  @override
  String get decimal_number => '填入数字';

  @override
  String get current_offset_is => '当前标准时差是';

  @override
  String get safety => '安全时差';

  @override
  String get none => '无';

  @override
  String get minute1 => '1分钟';

  @override
  String get minutes2 => '2分钟';

  @override
  String get minutes3 => '3分钟';

  @override
  String get minutes4 => '4分钟';

  @override
  String get minutes5 => '5分钟';

  @override
  String get minutes10 => '10分钟';

  @override
  String get pa_auk => '帕奥';

  @override
  String get na_uyana => '龙树林';

  @override
  String get search_for_city => '城市搜索';

  @override
  String get gps_permission => 'GPS启用';

  @override
  String get background_permission => '后台运行';

  @override
  String get error => '错误';

  @override
  String get notification => '提示';

  @override
  String get running_in_background => '后台运行中';

  @override
  String get background_initialized => '后台运行启动';

  @override
  String get background_enabled => '后台运行开通';

  @override
  String get background_not_set => '后台未设定';

  @override
  String get background_init_error => '后台启动错误';

  @override
  String get background_disabled => '后台取消';

  @override
  String get ok => 'OK';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get cancel => '取消';

  @override
  String get gps_not_available => 'GPS无信号';

  @override
  String get gps_recommend => '推荐使用GPS以获取最佳结果。您要启用GPS吗?';

  @override
  String get gps_internet_message => '互联网开通时，城市名称可以被GPS检寻定位。';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get help_content =>
      '算法:\n 计算依照让-米尔斯的天文算法公式进行。在南北纬72°间日出和日落的算值精度理论上偏差小于1分钟。请依预设时间恰当止息。 \n\n正午:\n正午屏面以简便方式显示GPS地址或所在城市的当日太阳日中时间。所有时间值参考了设定的安全时差。（见下）\n\n明相:\n明相屏面显示根据设定和相关太阳算法而产生的明相时间。 所有时间值计入设定的安全时差。 \n帕奥 = (日出时间-40分钟)。 \n龙树林 = (日出时间-30分钟)。 (见下) \n\nGPS:\n有网络且选择框打勾时，GPS会自动设定所在城市。 推荐使用GPS进行位置设定，这是计算正午时刻精度最佳的方式。此测试不包括 \"夏令时\" 区。\n\n设定:\n偏移:\n 此功能在 GPS状态下自动设置。 如果你选择在设定时使用城市搜索，你需要输入标准时差值 (GMT +- 本地时间). \n安全时差:\n 正午时间减去此值令其略早，明相时间加上此值令其略晚。 本算法中精度差小于1分钟，所以缺省安全时差设定为1分钟。\n明相:\n可选择适合您的明相时间。  龙树林以日出前30分钟为明相时分，而帕奥则以日出前40分钟为明相。安全时差会加在您选择的明相设定时间。 \n计时器:\n计时器屏面提供免操作语音提示。语音表示 \"文本转语音\"。 音量可以滑动调节。 通常情况下，屏面显示状态下语音提示可用。 若需, 您可以选择 \"屏幕常亮\" 以避免关屏或启动 \"关屏时使用TTS\" 功能。关屏时进入 \"后台\"运行，防止设备进入睡眠模式。 在确保其效果前，建议您多测试后台功能几次。有些手机可能不允许这类操作。我们不作任何保证。 关闭本应用，需要操作以停止后台运行任务。若你在手机顶部信息提示区（时间和信号等）看到本应用的太阳图标，则表示该应用正在后台运行中。否则，您将不会在此处见到该图标。该功能苹果系统用户尚未提供。\n 语音播报间隔为: 50,40,30,20,15,10,8,6,5,4,3,2,1,0 \n\n隐私:\n详细的隐私声明请见:\n https://americanmonk.org/privacy-policy-for-buddhist-sun-app/\n\n 我们不搜集任何信息，我们也不建立网络连接。在关闭状态下，本应用不在后台运行。GPS功能只有在您按下GPS按钮才因此而有唯一的一次启用。虽然本应用基于来自pub.dev网站的其它程序包，但我可以肯定，您在使用时是安全的。上述程序包在本应用\"许可\"页面，以及GitHub程序库中，有详细列明。';

  @override
  String get about_content =>
      ' BuddhistSun（佛日）是一款面向佛教比丘、比丘尼的小应用，显示日中、明相等，满足日常修行生活需要。因为我本人常以手进食，我需要一种\"免于动手\"的方式知道何时日中临近。开通语音提醒功能的计时器可以方便地让我了解还剩下多少用斋的时间。我很开心手头有这款小应用，希望您也会喜欢上它。\n\n有那么重要吗？你也许会问。\n是的，确实重要。遵从佛制僧规的人都知道过午不可再食。中午时刻是根据太阳在天空中的最高点而不是闹钟来确定的，再说，佛世时也没有闹钟。其他持守八戒或者十戒的修行人也将会发现这款小应用的价值。\n\n我推荐使用 https://TimeandDate.com 来验证本应用的精确度。本应用致力于满足您\"此时/处\" 的实际需求。 \n\n谨愿此应用助您早日安稳无差达至涅槃！';

  @override
  String get gps_permission_content =>
      '请允准使用GPS，以便本应用获得GPS地址数据来计算太阳位置。按下GPS钮，仅执行一次数据采集。所采集数据仅在本APP范围内使用。';

  @override
  String get background_permission_content =>
      '请允准后台启用，以确保屏面显示期间语音提示功能可以正常使用。当您关闭启用或关闭本APP时，后台运程将随之终止。同意启用后，则本请求不再发出。';

  @override
  String get dstSavingsNotice =>
      'Warning, this app does not calculate for Daylight Savings Time (DST).  Please be aware of the changes.  When DST happens you need to reset the GPS or the offset found in the Settings Tab.';

  @override
  String get dstNoticeTitle => '夏令时通知';

  @override
  String get verify => '确认';

  @override
  String get rateThisApp => '请评价';

  @override
  String get prev => '后退';

  @override
  String get next => '前进';

  @override
  String get moonPhase => '月相';

  @override
  String get selectDate => '选择日期';

  @override
  String get selectedDate => '已选择日期';

  @override
  String get moon => '月';

  @override
  String get darkMode => '护眼模式';

  @override
  String get color => '颜色';

  @override
  String get material3 => '材料3';

  @override
  String get uposathaCountry => '布萨国家';

  @override
  String get autoUpdateGps => '自动更新 GPS';

  @override
  String get refreshingGps => '正在刷新 GPS';

  @override
  String get command => 'flutter gen-l10n';
}
