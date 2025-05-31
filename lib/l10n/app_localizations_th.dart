// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get buddhistSun => 'Buddhist Sun';

  @override
  String get noon => 'เที่ยงวัน';

  @override
  String get dawn => 'อรุณ';

  @override
  String get timer => 'ตัวจับเวลา';

  @override
  String get gps => 'GPS';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get help => 'ช่วยเหลือ';

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get licenses => 'ใบอนุญาต';

  @override
  String get not_set => 'ไม่ได้ตั้งค่า';

  @override
  String get solar_noon => 'เที่ยงวัน';

  @override
  String get gmt_offset => 'ต่างจาก GMT';

  @override
  String get hours => 'ชั่วโมง';

  @override
  String get astronomical_twilight => 'สนธยาดาราศาสตร์';

  @override
  String get nautical_twilight => 'สนธยาทะเล';

  @override
  String get civil_twilight => 'สนธยาพลเรือน';

  @override
  String get sunrise => 'พระอาทิตย์ขึ้น';

  @override
  String get date => 'วันที่';

  @override
  String get current_time => 'เวลาปัจจุบัน';

  @override
  String get late => 'เลยเที่ยง';

  @override
  String get time_left => 'เหลือเวลา';

  @override
  String get speech_notify => 'แจ้งด้วยคำพูด';

  @override
  String get screen_always_on => 'หน้าจอเปิดตลอดเวลา';

  @override
  String get speech_in_background => 'คำพูดในพื้นหลัง';

  @override
  String get volume => 'ระดับเสียง';

  @override
  String get press_wait => 'กด_รอ';

  @override
  String get get_gps => 'รับ GPS';

  @override
  String get save_gps => 'บันทึก GPS';

  @override
  String get set_gps_city => 'ตั้งค่า GPS ตามตัวเมือง ';

  @override
  String get previous_gps_is => 'GPS ก่อนหน้าคือ';

  @override
  String get decimal_number => 'เลขทศนิยม';

  @override
  String get current_offset_is => 'ความต่างจาก GMT ที่ใช้อยู่';

  @override
  String get safety => 'การตั้งเวลาเผื่อ';

  @override
  String get none => 'ไม่มี';

  @override
  String get minute1 => '1 นาที';

  @override
  String get minutes2 => '2 นาที';

  @override
  String get minutes3 => '3 นาที';

  @override
  String get minutes4 => '4 นาที';

  @override
  String get minutes5 => '5 นาที';

  @override
  String get minutes10 => '10 นาที';

  @override
  String get pa_auk => 'พะอ๊อก';

  @override
  String get na_uyana => 'นะ อุยะนะ';

  @override
  String get search_for_city => 'ค้นหาเมือง';

  @override
  String get gps_permission => 'การอนุญาต GPS';

  @override
  String get background_permission => 'การอนุญาตพื้นหลัง';

  @override
  String get error => 'ข้อผิดพลาด';

  @override
  String get notification => 'การแจ้งเตือน';

  @override
  String get running_in_background => 'เเสดงในพื้นหลัง';

  @override
  String get background_initialized => 'เริ่มต้นพื้นหลังแล้ว';

  @override
  String get background_enabled => 'เปิดใช้งานพื้นหลังแล้ว';

  @override
  String get background_not_set => 'ไม่ได้ตั้งค่าพื้นหลัง';

  @override
  String get background_init_error => 'ข้อผิดพลาดในการเริ่มต้นพื้นหลัง';

  @override
  String get background_disabled => 'พื้นหลังไม่ทำงาน';

  @override
  String get ok => 'ตกลง';

  @override
  String get yes => 'ใช่';

  @override
  String get no => 'ไม่';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get gps_not_available => 'GPS ไม่พร้อมใช้งาน';

  @override
  String get gps_recommend =>
      'แนะนำให้ใช้ GPS เพื่อผลลัพธ์ที่ดีที่สุด คุณต้องการตั้งค่า GPS หรือไม่?';

  @override
  String get gps_internet_message =>
      'หากอินเทอร์เน็ตเปิดอยู่ ชื่อเมืองสามารถอ้างอิงได้โดย GPS';

  @override
  String get language => 'ภาษา';

  @override
  String get theme => 'ธีม';

  @override
  String get help_content =>
      'การคำนวณ:\n การคำนวณอิงตามสมการจากอัลกอริทึมทางดาราศาสตร์ที่ถูกคิดค้นโดย Jean Meeus โดยเวลาพระอาทิตย์ขึ้นเเละเวลาพระอาทิตย์ตกดินในพื้นที่ที่ตั้งอยู่ในระหว่างละติจูด +/- 72° นั้นมีความคลาดเคลื่อนไม่เกิน 1 นาที โปรดพิจาราณาหยุดฉันก่อนเวลาดังกล่าว \n\nเที่ยงวัน:\n จอแสดงเที่ยงวันจะเเสดงตามเเบบสุริยคติของวันนั้นๆ ตามที่ถูกกำหนดโดย GPS หรือเมือง ทั้งนี้เพื่อให้ท่านดูเวลาได้อย่างสะดวก ทุกเวลาที่แสดงในแอปนี้ขึ้นอยู่กับค่าที่ตั้งไว้ในโหมดการตั้งเวลาเผื่อในการตั้งค่า (ดูตามด้านล่าง) \n\nDAWN:\n จอเเสดงอรุณจะเเสดงในรูปเเบบอรุณที่เลือกไว้จากการตั้งค่าเเละจากการคำนวณทางสุริยคติ ทุกเวลาที่แสดงในแอปนี้ขึ้นอยู่กับค่าที่ตั้งไว้ในโหมดการตั้งเวลาเผื่อในการตั้งค่า \nพะอ๊อก = (ก่อนพระอาทิตย์ขึ้น 40 นาที) \nนา อุยานะ = (ก่อนพระอาทิตย์ขึ้น 30 นาที) (see below ดูตามด้านล่าง)\n\nGPS:\n GPS จะตั้งค่าเมืองโดยอัตโนมัติหากอินเทอร์เน็ตเปิดใช้งานอยู่และทำเครื่องหมายในช่อง ขอแนะนำให้คุณใช้การตั้งค่า GPS ระบุตำแหน่งของคุณ เนื่องจากเวลาเที่ยงเเบบสุริยคติจะแสดงผลแม่นยำที่สุดด้วยวิธีนี้ โหมดนี้ไม่ได้ถูกทดสอบด้วยตำแหน่งที่ตั้งที่เป็น \"เวลาออมแสง\" \n\nการตั้งค่า: \nOffset:\n โหมดนี้จะถูกตั้งค่าโดยอัตโนมัติเมื่อใช้ GPS หากคุณใช้การค้นหาเมืองในการตั้งค่า (GMT +- your local time) คุณต้องเลือกความต่างจาก GMT (GMT +- เวลาท้องถิ่นของคุณ) \nความปลอดภัย:\n วิธีนี้จะลบนาทีจากเวลาเที่ยงเพื่อให้เร็วขึ้น และบวกเวลาอรุณขึ้นเพื่อเผื่อเวลาในภายหลัง เนื่องด้วยสูตรมีความแม่นยำภายใน 1 นาที ดังนั้นการตั้งเวลาเผื่อเริ่มต้นคือ 1 นาที \nอรุณ:\n เลือกเวลาการขึ้นของอรุณ ที่ต้องการ นา อุยานะใช้เวลาพระอาทิตย์ขึ้น -30 นาที และพะอ๊อกใช้เวลาพระอาทิตย์ขึ้น -40 นาที ความปลอดภัยจะเพิ่ม x-นาที ในเวลานี้ \nTimer ตัวจับเวลา:\nหน้าจอตัวจับเวลาช่วยในการแจ้งเตือนด้วยเสียงแบบไม่ต้องใช้มือควบคุม คำพูด หมายถึง \"เปลี่ยนจากข้อความเป็นคำพูด\" ระดับเสียงถูกควบคุมโดยแถบเลื่อน และในสภาวะปกติ การแจ้งเตือนด้วยเสียงจะทำงานเฉพาะในขณะที่หน้าจอเปิดอยู่เท่านั้น เพื่อแก้ไขปัญหานี้ คุณสามารถตั้งค่าให้หน้าจอให้เปิดอยู่เสมอโดยเลือกสวิตช์ \"หน้าจอเปิดตลอดเวลา\" หรือคุณสามารถเปิดใช้งานโหมด \"TTS พร้อมปิดหน้าจอ\" ก็ได้ ซึ่งการตั้งค่าแบบนี้จะเปิดใช้งานการทำงาน \"พื้นหลัง\" ในขณะที่หน้าจอของท่านปิดอยู่ และป้องกันไม่ให้อุปกรณ์เข้าสู่โหมดสลีป (พักเครื่อง) ท่านควรทดสอบโหมดพื้นหลังนี้สองถึงสามครั้งก่อนที่จะใช้งานจริง โทรศัพท์บางรุ่นอาจไม่รองรับเเอปนี้ ซึ่งเราจะไม่รับผิดชอบต่อกรณีใดๆ ทั้งสิ้น เมื่อท่านปิดแอปพลิเคชัน งานที่ทำอยู่เบื้องหลังจะหยุดทำงาน ท่านจะรู้ว่าแอปกำลังทำงานในเบื้องหลังโดยสังเกตจากไอคอนรูปดวงอาทิตย์ที่แสดงที่ด้านบนของพื้นที่แจ้งเตือนในโทรศัพท์ของท่าน (ซึ่งอยู่ใกล้กับเวลาและแถบสัญญาณ) หากแอป Buddhist Sun ไม่อยู่ใน \"โหมดพื้นหลัง\" ท่านจะไม่เห็นไอคอนรูปพระอาทิตย์ อย่างไรก็ตามฟีเจอร์นี้ไม่พร้อมใช้งานสำหรับผู้ใช้ iOS\nการประกาศคำพูดอยู่ในช่วงนาทีต่อไปนี้: 50,40,30,20,15,10,8,6,5,4,3,2,1,0 \n\nPrivacy ความเป็นส่วนตัว:\nA full privacy statement is located at อ่านคำชี้แจงสิทธิส่วนบุคคลฉบับเต็มได้ที่:\n https://americanmonk.org/privacy-policy-for-buddhist-sun-app/ \n\n We do not collect information เราไม่เก็บข้อมูลส่วนตัวของผู้ใช้แอปนี้ในทุกกรณี';

  @override
  String get about_content =>
      'Buddhist Sun is a small app for Buddhist monks and nuns to display the Solar Noon time specific to Buddhist monastic needs. Because I usually eat with my hands, I needed to have a \"hands free\" way to know when the Noon was approaching. The timer with voice notifications turned on helps me know the time left for eating.  I enjoy using the app, and I hope that you do too.\n\nWhy is this important?\nThose who follow Buddhist monastic rules are not allowed to eat after Noon.  The rule is according to the sun at its zenith in the sky rather than a clock. They did not have clocks in the Buddha\'s time.  Others who follow 8 or 10 precepts may find this app useful too.\n\nI recommend https://TimeandDate.com to verify this app\'s accuracy.This application is meant for \"present moment/location\" use.  \n\nMay this help you to reach Nibbāna quickly and safely!';

  @override
  String get gps_permission_content =>
      'จะมีการขออนุญาตสำหรับการใช้ GPS ซึ่งช่วยให้ Buddhist Sun ทราบข้อมูลตำแหน่ง GPS เพื่อคำนวณตำแหน่งของดวงอาทิตย์ ซึ่ง GPS จะถูกรวบรวมเพียงครั้งเดียวในแต่ละครั้งที่มีการกดปุ่ม GPS  Data is not sent outside this app ข้อมูลจะไม่ถูกส่งออกไปนอกแอปนี้';

  @override
  String get background_permission_content =>
      'จะมีการขออนุญาตเพื่อใช้ในพื้นหลัง การอนุญาตนี้จำเป็นต่อการเปิดใช้งานการแจ้งเตือนด้วยเสียงเพื่อให้แอปทำงานบนหน้าจอได้อย่างถูกต้อง Buddhist Sun จะปิดโหมดพื้นหลังนี้เมื่อปิดสวิตช์หรือปิดแอป Permission will be requested only one time if accepted แอปจะขออนุญาตเพียงครั้งเดียวหากได้รับการยอมรับ';

  @override
  String get dstSavingsNotice =>
      'คำเตือน แอปนี้ไม่ได้คำนวณเวลาออมแสง (DST) โปรดทราบถึงการเปลี่ยนแปลงที่เกิดขึ้น คุณจะต้องรีเซ็ต GPS หรือออฟเซ็ตที่พบในแท็บการตั้งค่า';

  @override
  String get dstNoticeTitle => 'ประกาศเรื่องการปรับเวลาตามฤดูกาล';

  @override
  String get verify => 'ยืนยันเที่ยง';

  @override
  String get rateThisApp => 'ให้คะแนนแอปนี้';

  @override
  String get prev => 'ก่อนหน้า';

  @override
  String get next => 'ต่อไป';

  @override
  String get moonPhase => 'ข้างขึ้นข้างแรม:';

  @override
  String get selectDate => 'เลือกวันที่';

  @override
  String get selectedDate => 'วันที่เลือก:';

  @override
  String get moon => 'พระจันทร์';

  @override
  String get darkMode => 'โหมดมืด';

  @override
  String get color => 'สี';

  @override
  String get material3 => 'วัสดุ 3';

  @override
  String get uposathaCountry => 'ประเทศอุโปสถะ';

  @override
  String get autoUpdateGps => 'อัปเดต GPS อัตโนมัติ';

  @override
  String get refreshingGps => 'กำลังรีเฟรช GPS';

  @override
  String get command => 'flutter gen-l10n';
}
