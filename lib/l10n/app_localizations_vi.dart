// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get buddhistSun => 'Giờ Mặt Trời Dành Cho Đạo Phật';

  @override
  String get noon => 'Trưa';

  @override
  String get dawn => 'Bình Minh';

  @override
  String get timer => 'Bộ hẹn giờ';

  @override
  String get gps => 'GPS';

  @override
  String get settings => 'Cài đặt';

  @override
  String get help => 'Trợ giúp';

  @override
  String get about => 'Giới thiệu';

  @override
  String get licenses => 'Giấy phép';

  @override
  String get not_set => 'Chưa cài đặt';

  @override
  String get solar_noon => 'Đứng bóng';

  @override
  String get gmt_offset => 'Độ lệch so với GMT';

  @override
  String get hours => 'giờ';

  @override
  String get astronomical_twilight => 'Hoàng hôn thiên văn';

  @override
  String get nautical_twilight => 'Hoàng hôn hàng hải';

  @override
  String get civil_twilight => 'Hoàng hôn dân sự';

  @override
  String get sunrise => 'Bình minh';

  @override
  String get date => 'Ngày';

  @override
  String get current_time => 'Giờ hiện tại';

  @override
  String get late => 'Trễ';

  @override
  String get time_left => 'Thời gian còn lại';

  @override
  String get speech_notify => 'Thông báo bằng lời';

  @override
  String get screen_always_on => 'Luôn bật màn hình';

  @override
  String get speech_in_background => 'Âm thanh chạy dưới nền';

  @override
  String get volume => 'Âm lượng';

  @override
  String get press_wait => 'Bấm và chờ GPS mới.';

  @override
  String get get_gps => 'Lấy GPS';

  @override
  String get save_gps => 'Lưu GPS';

  @override
  String get set_gps_city => 'Cài GPS tên Thành Phố bằng Internet';

  @override
  String get previous_gps_is => 'GPS trước là';

  @override
  String get decimal_number => 'Số thập phân';

  @override
  String get current_offset_is => 'Độ lệch so với GMT hiện tại';

  @override
  String get safety => 'Mức an toàn';

  @override
  String get none => 'không';

  @override
  String get minute1 => '1 phút';

  @override
  String get minutes2 => '2 phút';

  @override
  String get minutes3 => '3 phút';

  @override
  String get minutes4 => '4 phút';

  @override
  String get minutes5 => '5 phút';

  @override
  String get minutes10 => '10 phút';

  @override
  String get pa_auk => 'Pa-Auk';

  @override
  String get na_uyana => 'Na-Uyana';

  @override
  String get search_for_city => 'Tìm T.Phố';

  @override
  String get gps_permission => 'Quyền GPS';

  @override
  String get background_permission => 'Quyền chạy nền';

  @override
  String get error => 'Lỗi';

  @override
  String get notification => 'Thông báo';

  @override
  String get running_in_background => 'Buddhist Sun đang chạy nền';

  @override
  String get background_initialized => 'Khởi tạo dưới nền';

  @override
  String get background_enabled => 'Nền đã được bật';

  @override
  String get background_not_set => 'Chưa bật nền';

  @override
  String get background_init_error => 'Khởi tạo nền bị lỗi';

  @override
  String get background_disabled => 'Nền đã tắt';

  @override
  String get ok => 'Đồng ý';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get cancel => 'Hủy';

  @override
  String get gps_not_available => 'GPS không có sẵn';

  @override
  String get gps_recommend =>
      'Khuyến cáo nên dùng GPS để cho kết quả tốt nhất. Bạn có muốn bật GPS hay không?';

  @override
  String get gps_internet_message =>
      'Nếu Internet được bật, tên Thành Phố có thể được tham khảo bằng GPS';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get theme => 'Chủ đề';

  @override
  String get help_content =>
      'Cách tính:\n Việc tính toán được dựa trên các phương trình từ các Thuật toán Thiên văn, bởi tác giả Jean Meeus. Kết quả mặt trời mọc và lặn chính xác theo lý thuyết trong phạm vi một phút cho những nơi nằm giữa +/-72° vĩ tuyến. Xin xem xét dừng trước thời gian được nêu. \n\nTRƯA:\nMàn hình buổi TRƯA hiển thị Mặt Trời Đứng Bóng cho ngày hiện tại như được chọn bởi GPS hoặc Thành Phố theo cách dễ nhìn. Tất cả thời gian theo mức an toàn từ phần cài đặt. (xem bên dưới)\n\nBÌNH MINH:\n Màn hình Bình Minh hiển thị công thức Bình minh đã được chọn từ phần cài đặt và cũng từ các tính toán mặt trời khác. Tất cả thời gian phản ánh theo mức an toàn từ phần cài đặt. \nPa-Auk = (Mặt trời mọc - 40 phút).  \nNa-uyana = ( Mặt trời mọc - 30 phút)  (xem bên dưới) \n\nGPS:\nGPS sẽ tự động thiết lập thành phố nếu Internet được bật và hộp đánh dấu được bật. Xin khuyến cáo sử dụng cài đặt GPS để xác định vị trí của bạn vì Mặt Trời Đứng Bóng sẽ chính xác nhất theo cách này. Điều này chưa được kiểm tra theo vị trí \"Tiết kiệm Ánh sáng Ban ngày\".\n\n Cài đặt:\nĐộ lệch:\n Được thiết lập tự động khi dùng GPS. Nếu bạn dùng Tìm kiếm Thành phố trong cài đặt, bạn phải chọn một độ lệch (GMT +- giờ địa phương của bạn). \nMức an toàn:\n Điều này sẽ trừ số phút từ thời gian Giữa Trưa để cho sớm hơn và cộng số phút vào giờ Bình minh để làm cho trễ hơn.  Vì công thức chính xác trong vòng một phút nên mặc định mức an toàn là một phút.  \n Bình minh:\nChọn bình minh ưa thích của bạn. Na-Uyana dùng Mặt trời mọc-30 minutes, và Pa-Auk dùng Mặt trời mọc - 40 phút. Mức an toàn sẽ cộng x-phút vào thời gian này. \n Bộ báo giờ:\nMàn hình báo giờ cho phép thông báo bằng âm thanh để rảnh tay.  Lời nói có nghĩa là \"Văn bản thành Lời nói\". Âm lượng được kiểm soát bằng thanh trượt. Dưới điều kiện bình thường thông báo bằng lời nói chỉ hoạt động khi màn hình sáng. Để sửa đổi điều này, bạn có thể làm màn hình luôn sáng với nút chuyển \"Màn hình luôn bật\", hoặc bạn bật chức năng \"TTS với màn hình tắt\".  Điều này sẽ bật hoạt động \"nền\" trong khi màn hình tắt và ngăn thiết bị đi vào chế độ ngủ. Bạn nên kiểm tra chức năng nền vài lần trước khi tín nhiệm nó. Một vài điện thoại có thể không cho phép điều này. Chúng tôi sẽ không chịu bất cứ trách nhiệm nào. Khi bạn đóng ứng dụng, có một lệnh được gọi để dừng các công việc dưới nền.  Bạn sẽ biết ứng dụng đang chạy dưới nền bởi biểu tượng mặt trời được hiển thị trên đầu khu vực thông báo của điện thoại (chỗ thanh thời gian và tín hiệu).  Nếu Buddhist Sun không ở trong \"chế độ nền\", bạn sẽ không thấy biểu tượng mặt trời. Chức năng này không có sẵn đối với người dùng iOS.\n Thông báo bằng lời nói thì ở trong các khoảng lặp theo số phút sau: 50,40,30,20,15,10,8,6,5,4,3,2,1,0 \n\nRiêng tư:\n Thông tin đầy đủ về sự riêng tư được đặt ở:\n https://americanmonk.org/privacy-policy-for-buddhist-sun-app/\n\n Chúng tôi không thu thập thông tin.';

  @override
  String get about_content =>
      'Buddhist Sun là một ứng dụng nhỏ chuyên hiển thị giờ mặt trời đứng bóng dành cho các vị sư và tu nữ Phật giáo theo các nhu cầu Giới Luật Phật giáo. Bởi vì tôi thường ăn bốc bằng tay, tôi cần có một cách \"rảnh tay\" để biết khi nào sắp tới giờ mặt trời đứng bóng. Bộ báo giờ với thông báo bằng lời nói được bật sẽ giúp tôi biết thời gian còn lại để ăn. Tôi ưa thích sử dụng ứng dụng này và tôi hy vọng các bạn cũng thế. \n\nTại sao điều này lại quan trọng? \nNhững ai tuân thủ Giới Luật thì không được phép ăn sau giữa trưa. Quy tắc này dựa vào mặt trời lúc đứng bóng hơn là đồng hồ. Họ không có đồng hồ vào thời đức Phật. Những ai tuân theo 8 hay 10 giới cũng có thể thấy sự hữu dụng của ứng dụng này. \n\nTôi xin giới thiệu trang https://TimeandDate.com để kiểm tra sự chính xác của ứng dụng này. Ứng dụng này có ý nghĩa dùng cho \"khoảnh khắc/vị trí hiện tại\".  \n\n Cầu mong điều này trợ giúp các bạn chứng ngộ Nibbāna một cách nhanh chóng và an toàn!';

  @override
  String get gps_permission_content =>
      'GPS yêu cầu được dùng quyền này. Quyền này giúp Buddhist Sun biết dữ liệu vị trí GPS để tính vị trí mặt trời. GPS chỉ thu thập 1 lần mỗi khi nút GPS được bấm. Dữ liệu không được gởi ra ngoài app.';

  @override
  String get background_permission_content =>
      'Việc chạy nền yêu cầu được dùng quyền này. Thông báo bằng lời cần quyền này để chạy mở màn hình. Buddhist Sun sẽ tắt tiến trình nền này khi tắt nút chuyển này hoặc khi đóng app này. Nếu được chấp nhận, quyền này chỉ yêu cầu 1 lần.';

  @override
  String get dstSavingsNotice =>
      'Cảnh báo, ứng dụng này không tính cho Giờ tiết kiệm ánh sáng ban ngày (DST). Hãy lưu ý những thay đổi. Khi DST xảy ra, bạn cần đặt lại GPS hoặc độ lệch được tìm thấy trong Tab Cài đặt.';

  @override
  String get dstNoticeTitle => 'Thông báo giờ mùa hè (DST)';

  @override
  String get verify => 'Kiểm tra lại giờ Trưa';

  @override
  String get rateThisApp => 'Đánh giá cho ứng dụng';

  @override
  String get prev => 'Trước';

  @override
  String get next => 'Sau';

  @override
  String get moonPhase => 'Tuần trăng:';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get selectedDate => 'Ngày đã chọn:';

  @override
  String get moon => 'trưa';

  @override
  String get darkMode => 'Chế độ tối';

  @override
  String get color => 'Màu';

  @override
  String get material3 => 'Material 3';

  @override
  String get uposathaCountry => 'Quốc gia Uposatha';

  @override
  String get autoUpdateGps => 'Tự động cập nhật GPS';

  @override
  String get refreshingGps => 'Đang làm mới GPS';

  @override
  String get command => 'flutter gen-l10n';
}
