// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'دراستي';

  @override
  String get continueAction => 'متابعة';

  @override
  String get back => 'رجوع';

  @override
  String get close => 'إغلاق';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get see => 'عرض';

  @override
  String get offlineBanner => 'دون اتصال · تنزيلاتك ما تزال متاحة';

  @override
  String get errorLoad => 'تعذّر التحميل. تحقّق من اتصالك ثم أعد المحاولة.';

  @override
  String get screenRecordingBlocked => 'تسجيل الشاشة غير مسموح';

  @override
  String get screenRecordingBody =>
      'لحماية عمل أساتذتنا، لا يمكن تصوير هذا المحتوى.';

  @override
  String get tagline => 'تعلّم · تدرّب · انجح';

  @override
  String get welcomeTitle => 'مرحبًا بك في دراستي';

  @override
  String get welcomeBody =>
      'من الابتدائية إلى الباكالوريا، تعلّم بإيقاعك وانجح في سنتك.';

  @override
  String get whoAreYou => 'من أنت؟';

  @override
  String get iAmStudent => 'أنا تلميذ';

  @override
  String get iAmStudentSub => 'دروس وتمارين وامتحانات';

  @override
  String get iAmParent => 'أنا وليّ أمر';

  @override
  String get iAmParentSub => 'متابعة تقدّم أبنائي';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get trialLine =>
      'البرنامج الدراسي الموريتاني · دروس وتمارين وامتحانات';

  @override
  String get studentLoginTitle => 'دخول التلميذ';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get pinCode => 'الرمز السري';

  @override
  String get forgotPin => 'نسيت الرمز؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get parentLoginTitle => 'دخول وليّ الأمر';

  @override
  String get whatsappNumber => 'رقم واتساب';

  @override
  String get newDeviceHint => 'هاتف جديد؟ سنرسل لك رمز تحقق عبر واتساب.';

  @override
  String get verifyTitle => 'تحقّق من رقمك';

  @override
  String verifyBody(Object phone) {
    return 'أدخل الرمز المكوّن من 6 أرقام المرسل عبر واتساب إلى $phone.';
  }

  @override
  String resendIn(Object time) {
    return 'إعادة إرسال الرمز بعد $time';
  }

  @override
  String get changeNumber => 'تغيير الرقم';

  @override
  String get verify => 'تحقّق';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String stepOf(Object n, Object total) {
    return 'الخطوة $n من $total';
  }

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get myGrade => 'قسمي';

  @override
  String get noGradesOpen => 'لا يوجد حاليًا أي قسم مفتوح للتسجيل.';

  @override
  String get errGradeClosed =>
      'هذا القسم لم يعد مفتوحًا للتسجيل. اختر قسمًا آخر.';

  @override
  String get aiDisclaimer => 'رفيق ذكاء اصطناعي وقد يخطئ.';

  @override
  String get reportAiAnswer => 'إبلاغ';

  @override
  String get reportAiTitle => 'الإبلاغ عن إجابة رفيق';

  @override
  String get reportAiReasonWrong => 'الإجابة خاطئة';

  @override
  String get reportAiReasonInappropriate => 'محتوى غير لائق أو مسيء';

  @override
  String get reportAiReasonOther => 'مشكلة أخرى';

  @override
  String get reportAiCommentHint => 'اشرح باختصار (اختياري)';

  @override
  String get reportAiSend => 'إرسال البلاغ';

  @override
  String get reportAiThanks => 'شكرًا! سيتحقق فريقنا من هذه الإجابة.';

  @override
  String get reportAiError => 'تعذّر الإرسال. حاول لاحقًا.';

  @override
  String get parentGateTitle => 'اطلب من أحد والديك';

  @override
  String parentGateBody(int a, int b) {
    return 'للمتابعة، يجب على أحد الوالدين الإجابة: كم يساوي $a × $b؟';
  }

  @override
  String get parentGateWrong => 'الإجابة غير صحيحة.';

  @override
  String get parentGateConfirm => 'تأكيد';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get selfSignupFromC2 =>
      'الابتدائي والسنة الأولى إعدادي: يُنشئ أحد الوالدين الحساب من فضائه.';

  @override
  String get chooseRoleTitle => 'من يُنشئ الحساب؟';

  @override
  String get chooseRoleBody => 'اختر ملفك للبدء. يمكنك تغيير كل شيء لاحقًا.';

  @override
  String get roleStudentDesc => 'أتعلّم بدروسي وتماريني، ورفيق إلى جانبي.';

  @override
  String get roleStudentBadge => 'الإعدادية (السنة 2) ← الثانوية';

  @override
  String get roleStudentPoint1 => 'دروس وتمارين البرنامج الموريتاني';

  @override
  String get roleStudentPoint2 => 'رفيق يساعدني خطوة بخطوة في واجباتي';

  @override
  String get roleParentDesc => 'أُنشئ حسابات أبنائي وأتابع تقدّمهم.';

  @override
  String get roleParentBadge => 'الابتدائية ← الثانوية';

  @override
  String get roleParentPoint1 => 'حساب لكل طفل، ابتداءً من الابتدائي';

  @override
  String get roleParentPoint2 => 'ملخّص لتقدّمهم كل أسبوع';

  @override
  String get paymentProof => 'صورة شاشة الدفع';

  @override
  String get addPaymentProof => 'إضافة صورة الشاشة';

  @override
  String get paymentProofHint => 'تأكيد بنكيلي مع المبلغ والتاريخ.';

  @override
  String get paymentProofAdded => 'تمت إضافة الصورة';

  @override
  String get changePaymentProof => 'تغيير';

  @override
  String get errPaymentProofRequired => 'أضف صورة شاشة الدفع.';

  @override
  String get bankilyNumberSoon =>
      'سيظهر رقم بنكيلي هنا قريبًا. في الأثناء، اختر «الدفع يدويًا».';

  @override
  String get lockedNoPlanTitle => 'اختر عرضك';

  @override
  String get lockedNoPlanBody =>
      'حسابك جاهز! اختر عرضًا لفتح كل الدروس والتمارين ورفيق.';

  @override
  String get lockedPendingTitle => 'الدفع قيد التحقق';

  @override
  String get lockedPendingBody =>
      'نتحقق من دفعتك. يُفتح الوصول فور التأكيد — اضغط «تحديث» للتحقق.';

  @override
  String get lockedManualTitle => 'تم تسجيل الطلب';

  @override
  String get lockedManualBody =>
      'سيتواصل معك فريقنا لإتمام الدفع. يُفتح الوصول فور التأكيد.';

  @override
  String get chooseClassTitle => 'في أي قسم تدرس؟';

  @override
  String get chooseClassBody => 'نُعدّ برنامجك حسب قسمك.';

  @override
  String get havePromoCode => 'لديّ رمز ترويجي';

  @override
  String get changeClass => 'تعديل';

  @override
  String get cyclePrimary => 'الابتدائية';

  @override
  String get cycleMiddle => 'الإعدادية';

  @override
  String get cycleHigh => 'الثانوية';

  @override
  String get available => '✓ متاح';

  @override
  String get choosePin => 'اختر رمزًا سريًا';

  @override
  String get acceptTerms => 'أوافق على سياسة الخصوصية';

  @override
  String get getWhatsappCode => 'استلام الرمز عبر واتساب';

  @override
  String get trialTitle => '7 أيام مجانًا';

  @override
  String get trialBody => 'وصول كامل إلى برنامج قسمك، دون دفع.';

  @override
  String get startTrial => 'ابدأ تجربتي';

  @override
  String get claimBody =>
      'أنشأ لك وليّ أمرك حسابًا. أدخل رمز الدعوة الذي أرسله لك.';

  @override
  String hello(Object name) {
    return 'مرحبًا $name';
  }

  @override
  String level(Object n) {
    return 'المستوى $n';
  }

  @override
  String xpToNext(Object xp, Object n) {
    return 'بقيت $xp نقطة للوصول إلى المستوى $n';
  }

  @override
  String get myWeek => 'أسبوعي';

  @override
  String get correctAnswers => 'إجابات صحيحة';

  @override
  String get exercisesDone => 'تمارين منجزة';

  @override
  String get activeDays => 'أيام النشاط';

  @override
  String get studyTime => 'وقت الدراسة';

  @override
  String get mySubjects => 'موادي';

  @override
  String lessonsCount(Object n) {
    return '$n درسًا';
  }

  @override
  String get weeklyExam => 'امتحان الأسبوع';

  @override
  String get prepare => 'استعدّ';

  @override
  String get homeworkHelper => 'رفيق – مساعد الواجبات';

  @override
  String get homeworkHelperSub => 'صوّر تمرينك، وسيرشدك رفيق خطوة بخطوة.';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabSubjects => 'المواد';

  @override
  String get tabExams => 'الامتحانات';

  @override
  String get tabProfile => 'حسابي';

  @override
  String get tabSubscription => 'الاشتراك';

  @override
  String get journeyVideo => 'الفيديو';

  @override
  String get journeyLesson => 'الدرس';

  @override
  String get journeyExercises => 'التمارين';

  @override
  String get statusMastered => 'متقَن';

  @override
  String get statusViewed => 'تمت المشاهدة';

  @override
  String get statusNotStarted => 'لم يبدأ';

  @override
  String download(Object size) {
    return 'تحميل · $size';
  }

  @override
  String get downloadWifiHint =>
      'حمّل الفيديو عبر الواي فاي لمشاهدته دون اتصال وتوفير بياناتك.';

  @override
  String get inThisLesson => 'في هذا الدرس';

  @override
  String get continueToLesson => 'المتابعة إلى الدرس';

  @override
  String get realLife => 'في الحياة اليومية';

  @override
  String get checkUnderstanding => 'تحقّق من فهمك';

  @override
  String get nextConcept => 'المفهوم التالي';

  @override
  String get answerToContinue => 'أجب إجابة صحيحة للمتابعة';

  @override
  String get workedExample => 'مثال محلول';

  @override
  String get commonMistake => 'خطأ شائع';

  @override
  String get revisionSheet => 'بطاقة المراجعة';

  @override
  String get formulas => 'صيغ للحفظ';

  @override
  String get definitions => 'تعاريف';

  @override
  String get keyFacts => 'للمعرفة';

  @override
  String get goToExercises => 'الانتقال إلى التمارين';

  @override
  String questionOf(Object n, Object total) {
    return 'السؤال $n/$total';
  }

  @override
  String get check => 'تحقّق';

  @override
  String get correctFeedback => 'أحسنت، إجابة صحيحة!';

  @override
  String get wrongFeedback => 'ليس تمامًا';

  @override
  String xpGain(Object xp) {
    return '+$xp نقاط';
  }

  @override
  String streakDays(Object n) {
    return '$n أيام متتالية';
  }

  @override
  String get streakBody => 'سلسلتك مستمرة. عُد غدًا للحفاظ عليها.';

  @override
  String get score => 'النتيجة';

  @override
  String get duration => 'المدة';

  @override
  String get xpEarned => 'نقاط مكتسبة';

  @override
  String reviewMistakes(Object n) {
    return 'مراجعة أخطائي ($n)';
  }

  @override
  String get backHome => 'العودة إلى الرئيسية';

  @override
  String get leaveSessionTitle => 'مغادرة الجلسة؟';

  @override
  String get yourAnswer => 'إجابتك';

  @override
  String get aiCorrection => 'تصحيح رفيق';

  @override
  String get almost => 'تقريبًا!';

  @override
  String get correctAnswer => 'الإجابة الصحيحة';

  @override
  String get similarExercise => 'تمرين مشابه';

  @override
  String get watchMethod => 'شاهد الطريقة بالفيديو';

  @override
  String get helperGuideNote => 'دراستي يرشدك دون أن يعطيك الإجابة مباشرة.';

  @override
  String get typeAnswer => 'اكتب إجابتك…';

  @override
  String get exams => 'الامتحانات';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get recentResults => 'نتائج حديثة';

  @override
  String get upcoming => 'قادم';

  @override
  String get startExam => 'ابدأ الامتحان';

  @override
  String get finishExam => 'إنهاء الامتحان';

  @override
  String get previous => 'السابق';

  @override
  String get next => 'التالي';

  @override
  String get byChapter => 'حسب الفصل';

  @override
  String get myDownloads => 'تنزيلاتي';

  @override
  String get wifiOnly => 'التحميل عبر الواي فاي فقط';

  @override
  String get offlineExpired => 'انتهت صلاحية الوصول دون اتصال';

  @override
  String get reconnect => 'إعادة الاتصال';

  @override
  String get noDownloads => 'لا توجد تنزيلات';

  @override
  String get language => 'اللغة';

  @override
  String get parentalControl => 'الرقابة الأبوية';

  @override
  String get faq => 'الأسئلة الشائعة';

  @override
  String get whatsappSupport => 'الدعم عبر واتساب';

  @override
  String get rateApp => 'قيّم التطبيق';

  @override
  String get shareApp => 'شارك دراستي';

  @override
  String get about => 'حول التطبيق';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get deleteAccount => 'حذف حسابي';

  @override
  String get subscriptionActive => 'اشتراك نشط';

  @override
  String get trialEnded => 'انتهت تجربتك';

  @override
  String get trialEndedBody =>
      'اطلب من وليّ أمرك اختيار عرض لمواصلة دروسك وتمارينك.';

  @override
  String get notifyParent => 'أخبر وليّ أمري عبر واتساب';

  @override
  String get alreadyPaid => 'دفعت بالفعل؟ حدّث';

  @override
  String focusUntil(Object time) {
    return 'وضع التركيز حتى $time';
  }

  @override
  String get unlock => 'إلغاء القفل';

  @override
  String get parentCode => 'رمز وليّ الأمر';

  @override
  String get guidedAccessHint =>
      'على الآيفون: فعّل الوصول الموجّه (نقر ثلاثي على الزر الجانبي) للبقاء في دراستي.';

  @override
  String get focusBlockedTitle => 'ليس الآن!';

  @override
  String focusBlockedBody(Object time) {
    return 'وضع التركيز مفعّل حتى $time. يمكنك تسجيل الخروج بعد ذلك، أو باستعمال رمز وليّ أمرك.';
  }

  @override
  String get keepStudying => 'واصل الدراسة';

  @override
  String get parentSpace => 'فضاء وليّ الأمر';

  @override
  String get myChildren => 'أبنائي';

  @override
  String get addChild => 'إضافة ابن';

  @override
  String subscribeFor(Object name) {
    return 'اشترك لـ$name';
  }

  @override
  String get subscribed => 'مشترك';

  @override
  String trialDaysLeft(Object n) {
    return 'تجربة · $n أيام';
  }

  @override
  String get childFirstName => 'اسم الابن';

  @override
  String get createChildAccount => 'إنشاء الحساب';

  @override
  String childReady(Object name) {
    return 'حساب $name جاهز';
  }

  @override
  String get shareWhatsapp => 'المشاركة عبر واتساب';

  @override
  String get copyCredentials => 'نسخ بيانات الدخول';

  @override
  String daysUntilExam(Object n, Object exam) {
    return '$n يومًا قبل $exam';
  }

  @override
  String get examConcours => 'مسابقة دخول السنة الأولى إعدادية';

  @override
  String get examBrevet => 'شهادة ختم الدروس الإعدادية';

  @override
  String get examBac => 'الباكالوريا';

  @override
  String get weeklyInsight => 'تحليل الأسبوع';

  @override
  String get masteryBySubject => 'الإتقان حسب المادة';

  @override
  String get examHistory => 'سجل الامتحانات';

  @override
  String get lessonDetail => 'التفاصيل درسًا بدرس';

  @override
  String get focusMode => 'وضع التركيز';

  @override
  String get enableFocus => 'تفعيل وضع التركيز';

  @override
  String timeWindow(Object n) {
    return 'الفترة $n';
  }

  @override
  String get start => 'البداية';

  @override
  String get end => 'النهاية';

  @override
  String get addWindow => 'إضافة فترة';

  @override
  String get focusLog => 'السجل';

  @override
  String logLeftApp(Object min) {
    return 'غادر التطبيق $min دقيقة';
  }

  @override
  String get logUnlocked => 'أُلغي القفل برمزك';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get planMonthly => 'شهري';

  @override
  String get planQuarterly => 'فصلي';

  @override
  String get planYearly => 'سنوي';

  @override
  String get popular => 'الأكثر طلبًا';

  @override
  String get forWhichChildren => 'لأي من الأبناء؟';

  @override
  String get familyDiscount => 'تخفيض العائلة';

  @override
  String get total => 'المجموع';

  @override
  String priceMru(Object amount) {
    return '$amount أوقية';
  }

  @override
  String get payWithBankily => 'الدفع عبر Bankily';

  @override
  String get choosePaymentMethod => 'اختر وسيلة الدفع';

  @override
  String payWithMethod(Object method) {
    return 'الدفع عبر $method';
  }

  @override
  String paymentMethodTitle(Object method) {
    return 'الدفع عبر $method';
  }

  @override
  String methodNumber(Object method) {
    return 'رقم $method الخاص بدراستي';
  }

  @override
  String methodStep1(Object method) {
    return 'افتح $method وأرسل المبلغ إلى الرقم أعلاه.';
  }

  @override
  String get methodPhone => 'الرقم المستعمل للدفع';

  @override
  String get paymentProofHintGeneric => 'تأكيد الدفع مع المبلغ والتاريخ.';

  @override
  String paymentSentBodyMethod(Object method) {
    return 'نتحقق من دفعكم عبر $method، وسيُفعَّل الوصول فور التأكيد.';
  }

  @override
  String get bankilyTitle => 'الدفع عبر Bankily';

  @override
  String get amountToSend => 'المبلغ المطلوب إرساله';

  @override
  String get merchantNumber => 'رقم بنكيلي الخاص بدراستي';

  @override
  String get bankilyStep1 =>
      'افتح بنكيلي وأرسل المبلغ إلى رقم بنكيلي الخاص بدراستي أعلاه.';

  @override
  String get bankilyStep2 => 'التقط صورة شاشة لتأكيد الدفع.';

  @override
  String get bankilyStep3 => 'أضفها أدناه مع رقمك، ثم أكّد.';

  @override
  String get bankilyPhone => 'رقم Bankily المستعمل';

  @override
  String get transactionCode => 'رمز العملية';

  @override
  String get confirmPayment => 'تأكيد الدفع';

  @override
  String get mySubscriptions => 'اشتراكاتي';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusPending => 'قيد التحقق';

  @override
  String get statusExpired => 'منتهي';

  @override
  String get statusRefused => 'دفع مرفوض';

  @override
  String get renew => 'تجديد';

  @override
  String get history => 'السجل';

  @override
  String get statusDownloaded => 'متاح دون إنترنت';

  @override
  String get downloadNoSize => 'تنزيل';

  @override
  String get downloadFailed => 'فشل التنزيل — تحقق من الاتصال وأعد المحاولة.';

  @override
  String get backspace => 'مسح';

  @override
  String get studentLoginBody => 'استخدم المعرّف الذي أعطاك إياه والداك.';

  @override
  String get parentLoginBody => 'أدخل رقم واتساب ورمزك السري.';

  @override
  String get noAccountYet => 'ليس لديك حساب بعد؟';

  @override
  String get forgotPinStudentTitle => 'نسيت رمزك؟';

  @override
  String get forgotPinStudentBody =>
      'اطلب من والديك: يمكنهما رؤية رمزك السري أو تغييره من فضاء الوالدين.';

  @override
  String get forgotPinParentBody =>
      'تواصل مع دعم واتساب لإعادة تعيين رمزك السري.';

  @override
  String get ok => 'حسنًا';

  @override
  String get wrongStudentCredentials => 'اسم المستخدم أو الرمز السري غير صحيح.';

  @override
  String get wrongParentCredentials => 'الرقم أو الرمز السري غير صحيح.';

  @override
  String pinLocked(Object min) {
    return 'محاولات كثيرة. أعد المحاولة بعد $min دقيقة.';
  }

  @override
  String get askParentForPin => 'نسيت رمزك؟ اسأل والديك';

  @override
  String get registerBody => 'بعض المعلومات لتحضير برنامجك.';

  @override
  String get registerParentBody => 'بعض المعلومات لإنشاء فضاء الوالدين.';

  @override
  String get phoneHintVerify => 'لاستلام رمز التحقق';

  @override
  String get phoneHintOptional => 'اختياري · للتحقق من حسابك ومتابعة تقدمك';

  @override
  String get pinHint => '4 أرقام، سهلة التذكر بالنسبة لك وليس للآخرين.';

  @override
  String get enterPin => 'أدخل رمزك السري';

  @override
  String get validate => 'تأكيد';

  @override
  String get createMyAccount => 'إنشاء حسابي';

  @override
  String get errNameRequired => 'أدخل الاسم الكامل.';

  @override
  String get errUsernameFormat =>
      'من 3 إلى 20 حرفًا أو رقمًا لاتينيًا، بدون مسافات.';

  @override
  String get errPhoneRequired => 'أدخل رقم واتساب.';

  @override
  String get errPinFormat => 'يجب أن يتكون الرمز السري من 4 أرقام.';

  @override
  String get errTermsRequired => 'وافق على سياسة الخصوصية للمتابعة.';

  @override
  String get errAccountExists =>
      'يوجد حساب بهذا الرقم بالفعل — سجّل الدخول بدلاً من ذلك.';

  @override
  String get errUsernameTaken =>
      'اسم المستخدم هذا مُستخدم بالفعل — جرّب اسمًا آخر.';

  @override
  String get errTooSoon => 'انتظر قليلاً قبل طلب رمز جديد.';

  @override
  String get errCodeExpired => 'انتهت صلاحية الرمز — اطلب رمزًا جديدًا.';

  @override
  String get errIncorrectCode => 'رمز غير صحيح.';

  @override
  String get errTooManyAttempts => 'محاولات كثيرة جدًا — اطلب رمزًا جديدًا.';

  @override
  String get errNoPendingCode => 'لا يوجد رمز بانتظار — اطلب رمزًا جديدًا.';

  @override
  String get errGeneric => 'حدث خطأ. تحقق من اتصالك ثم أعد المحاولة.';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get pasteCode => 'لصق الرمز';

  @override
  String get pasteCodeHint => 'اضغط مطولاً للصق الرمز';

  @override
  String get accountCreated => 'تم إنشاء الحساب';

  @override
  String trialTitleDays(Object n) {
    return '$n أيام مجانية';
  }

  @override
  String trialBodyGrade(Object grade) {
    return 'وصول كامل إلى كل برنامج $grade، بدون دفع.';
  }

  @override
  String get trialFeatureLessons => 'كل الدروس والفيديوهات';

  @override
  String get trialFeatureQcm => 'اختبارات وتمارين يصححها رفيق (ذكاء اصطناعي)';

  @override
  String get trialFeatureExams => 'امتحانات أسبوعية';

  @override
  String get trialFeatureHelper => 'مساعدة في الواجبات بالصور مع رفيق';

  @override
  String trialFooterPrice(Object price) {
    return 'بعد ذلك ابتداءً من $price أوقية في الشهر. لا يوجد سحب تلقائي: يختار أحد الوالدين العرض ويدفع عبر بنكيلي.';
  }

  @override
  String get trialFooterNoPrice =>
      'لا يوجد سحب تلقائي: يختار أحد الوالدين العرض ويدفع عبر بنكيلي.';

  @override
  String get accountReadyTitle => 'حسابك جاهز';

  @override
  String accountReadyBody(Object grade) {
    return 'اختر عرضًا للوصول إلى كل برنامج $grade.';
  }

  @override
  String get choosePlan => 'اختيار عرض';

  @override
  String get later => 'لاحقًا';

  @override
  String xpOfTotal(Object xp, Object total) {
    return '$xp / $total XP';
  }

  @override
  String inDays(Object n) {
    return 'بعد $n أيام';
  }

  @override
  String get today => 'اليوم';

  @override
  String get tomorrow => 'غدًا';

  @override
  String get availableNow => 'متاح';

  @override
  String questionsCount(Object n) {
    return '$n أسئلة';
  }

  @override
  String hoursMinutes(Object h, Object m) {
    return '$h س $m د';
  }

  @override
  String minutesShort(Object m) {
    return '$m د';
  }

  @override
  String get noSubjects => 'لا توجد مواد متاحة لصفك حاليًا.';

  @override
  String get noExamThisWeek => 'لا يوجد امتحان هذا الأسبوع';

  @override
  String get noExamThisWeekBody => 'سيظهر الامتحان القادم هنا بمجرد توفره.';

  @override
  String get profileLoadError => 'تعذّر تحميل ملفك الشخصي.';

  @override
  String chaptersCount(Object n) {
    return '$n فصول';
  }

  @override
  String masteredLessonsCount(Object n) {
    return '$n دروس متقنة';
  }

  @override
  String get filterAll => 'الكل';

  @override
  String get filterToReview => 'للمراجعة';

  @override
  String get filterOffline => 'دون إنترنت';

  @override
  String chapterMeta(Object n, Object m) {
    return '$n دروس · $m متقنة';
  }

  @override
  String get comingSoon => 'المحتوى قادم قريبًا';

  @override
  String get comingSoonBody => 'دروس هذه المادة قادمة قريبًا.';

  @override
  String get noLessonsToReview => 'لا شيء للمراجعة حاليًا';

  @override
  String get noLessonsToReviewBody =>
      'ستظهر هنا الدروس التي شاهدتها ولم تتقنها بعد.';

  @override
  String get noOfflineLessons => 'لا توجد دروس دون إنترنت';

  @override
  String get noOfflineLessonsBody => 'نزّل فيديو درس لتجده هنا دون اتصال.';

  @override
  String get subjectLoadError => 'تعذّر تحميل هذه المادة.';

  @override
  String get mySubjectsTitle => 'موادي';

  @override
  String lessonLabel(Object chapter, Object n) {
    return '$chapter · الدرس $n';
  }

  @override
  String conceptOf(Object n, Object total) {
    return 'المفهوم $n من $total';
  }

  @override
  String get correctUnlocked => '✓ صحيح! تم فتح المفهوم التالي.';

  @override
  String get wrongTryAgain => 'ليس تمامًا — أعد قراءة المفهوم وحاول مجددًا.';

  @override
  String get revealedAnswer => 'إليك الإجابة الصحيحة:';

  @override
  String get finishExamplesFirst => 'أنهِ الأمثلة لفتح السؤال.';

  @override
  String get nextExample => 'المثال التالي';

  @override
  String exampleOf(Object n, Object total) {
    return 'المثال $n من $total';
  }

  @override
  String get statement => 'نص التمرين';

  @override
  String get showSolution => 'عرض الحل خطوة بخطوة';

  @override
  String get reviewVideo => 'إعادة مشاهدة الفيديو';

  @override
  String get lessonComingSoon => 'محتوى هذا الدرس قادم قريبًا.';

  @override
  String get lessonNotFound => 'الدرس غير موجود.';

  @override
  String get lessonLoadError => 'تعذّر تحميل هذا الدرس.';

  @override
  String get alreadyReadTitle => 'لقد قرأت هذا الدرس من قبل';

  @override
  String get alreadyReadBody => 'ماذا تريد أن تفعل الآن؟';

  @override
  String get redoLesson => 'مراجعة الدرس';

  @override
  String get redoLessonSub => 'الفيديو والشرح من البداية';

  @override
  String get qcmTitle => 'اختبار متعدد الخيارات';

  @override
  String get qcmSub => 'أسئلة اختيار من متعدد بتصحيح فوري';

  @override
  String get guidedExercises => 'تمارين موجّهة';

  @override
  String get guidedExercisesSub => 'تمارين مفتوحة يصححها رفيق (ذكاء اصطناعي)';

  @override
  String get alreadyDone => 'تم من قبل';

  @override
  String get startQcm => 'ابدأ الاختبار';

  @override
  String get finishLesson => 'إنهاء الدرس';

  @override
  String questionTopic(Object lesson, Object n) {
    return '$lesson · السؤال $n';
  }

  @override
  String get leaveSessionBody => 'لن يتم حفظ إجاباتك في هذا الاختبار.';

  @override
  String get leave => 'خروج';

  @override
  String get stayInSession => 'متابعة الاختبار';

  @override
  String get seeResults => 'عرض نتائجي';

  @override
  String get hint => 'تلميح';

  @override
  String get lessonValidated => 'تم اجتياز الدرس';

  @override
  String notMasteredYet(Object pct) {
    return 'لم تُتقن بعد ($pct %) — أعد الاختبار لتتقدّم.';
  }

  @override
  String get retryQcm => 'إعادة الاختبار';

  @override
  String get noQcmTitle => 'لا يوجد اختبار بعد';

  @override
  String get noQcmBody => 'أسئلة هذا الدرس قادمة قريبًا.';

  @override
  String get backToLesson => 'العودة إلى الدرس';

  @override
  String get qcmLoadError => 'تعذّر تحميل الأسئلة.';

  @override
  String get mistakesTitle => 'أخطاؤك';

  @override
  String yourAnswerWas(Object a) {
    return 'إجابتك: $a';
  }

  @override
  String correctAnswerWas(Object a) {
    return 'الإجابة الصحيحة: $a';
  }

  @override
  String qcmScoreTitle(Object lesson) {
    return '$lesson · اختبار';
  }

  @override
  String openExerciseLabel(Object lesson) {
    return 'تمرين مفتوح · $lesson';
  }

  @override
  String exerciseN(Object n) {
    return 'التمرين $n';
  }

  @override
  String attemptN(Object n) {
    return 'المحاولة $n';
  }

  @override
  String get submitAnswer => 'إرسال إجابتي';

  @override
  String get usefulSymbols => 'رموز مفيدة';

  @override
  String get seeCorrection => 'عرض التصحيح';

  @override
  String get hintBeforeCorrection =>
      'اقرأ التلميح ثم اطلب التصحيح — أو عدّل إجابتك أولاً.';

  @override
  String get correcting => 'جارٍ التصحيح…';

  @override
  String get generatingExercise => 'جارٍ إنشاء تمرين مشابه…';

  @override
  String get verdictCorrect => 'صحيح!';

  @override
  String get verdictReview => 'للمراجعة';

  @override
  String get reviseAnswer => 'تصحيح إجابتي';

  @override
  String get nextExercise => 'التمرين التالي';

  @override
  String get noExercisesTitle => 'لا توجد تمارين بعد';

  @override
  String get noExercisesBody => 'تمارين هذا الدرس قادمة قريبًا.';

  @override
  String get exercisesLoadError => 'تعذّر تحميل التمارين.';

  @override
  String get methodVideos => 'الطريقة بالفيديو';

  @override
  String get photoPrompt => 'صوّر تمرينك';

  @override
  String get photoPromptBody => 'اجعل نص التمرين واضحًا وبإضاءة جيدة.';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get analyze => 'تحليل';

  @override
  String get analyzingPhoto => 'دراستي يقرأ تمرينك…';

  @override
  String detectedSubject(Object subject) {
    return '$subject · تم التعرّف عليه';
  }

  @override
  String get readProblem => 'هذا ما قرأته:';

  @override
  String get letsSolveTogether => 'لنحلّه معًا خطوة بخطوة.';

  @override
  String get nextStep => 'الخطوة التالية';

  @override
  String get showAnswer => 'عرض الإجابة';

  @override
  String get answerLabel => 'الإجابة';

  @override
  String get keyConceptsLabel => 'مفاهيم أساسية';

  @override
  String get newPhoto => 'صورة جديدة';

  @override
  String get retakePhoto => 'إعادة التصوير';

  @override
  String get examsBody => 'امتحان واحد أسبوعيًا لكل مادة أساسية.';

  @override
  String get seeExam => 'عرض الامتحان';

  @override
  String get filterPast => 'السابقة';

  @override
  String get weeklyExamBadge => 'امتحان أسبوعي';

  @override
  String get dueBy => 'آخر أجل';

  @override
  String get questionsLabel => 'أسئلة';

  @override
  String get xpMax => 'أقصى XP';

  @override
  String get beforeStart => 'قبل البدء';

  @override
  String get examRuleTimer => 'يبدأ العدّاد بمجرد الضغط على ابدأ.';

  @override
  String get examRuleSkip => 'يمكنك تخطي سؤال والعودة إليه قبل النهاية.';

  @override
  String get examRuleCalm =>
      'اجلس في مكان هادئ: لا يمكن إيقاف الامتحان مؤقتًا.';

  @override
  String get examRuleSaved => 'تُحفظ كل إجابة بمجرد اختيارها.';

  @override
  String skippedHint(Object n) {
    return 'تم تخطي السؤال $n · يمكنك العودة إليه';
  }

  @override
  String get finishExamTitle => 'إنهاء الامتحان؟';

  @override
  String finishExamUnanswered(Object n) {
    return 'ستُحتسب $n أسئلة بدون إجابة خاطئة.';
  }

  @override
  String get finishExamAll => 'لقد أجبت على جميع الأسئلة.';

  @override
  String get finishNow => 'إنهاء الآن';

  @override
  String get keepGoing => 'متابعة الامتحان';

  @override
  String resultsGreat(Object name) {
    return 'عمل رائع يا $name';
  }

  @override
  String resultsGood(Object name) {
    return 'عمل جيد يا $name';
  }

  @override
  String resultsKeepGoing(Object name) {
    return 'واصل مجهودك يا $name';
  }

  @override
  String get byLesson => 'حسب الدرس';

  @override
  String get yourAnswers => 'إجاباتك';

  @override
  String get done => 'تم';

  @override
  String get missed => 'فائت';

  @override
  String get noExams => 'لا توجد امتحانات حاليًا';

  @override
  String get noExamsBody => 'ستظهر امتحانات الأسبوع هنا.';

  @override
  String get noPastExams => 'لا توجد امتحانات سابقة';

  @override
  String get examsLoadError => 'تعذّر تحميل امتحاناتك.';

  @override
  String get examLoadError => 'تعذّر تحميل هذا الامتحان.';

  @override
  String get submitError => 'فشل الإرسال. تحقق من اتصالك ثم أعد المحاولة.';

  @override
  String get seeResultsExam => 'عرض النتيجة';

  @override
  String storageUsed(Object size) {
    return '$size مستخدمة';
  }

  @override
  String get offlineExpiredBody => 'اتصل بالإنترنت لإعادة تفعيل فيديوهاتك.';

  @override
  String get downloadsFooter =>
      'تبقى الفيديوهات المنزّلة متاحة دون إنترنت حتى نهاية اشتراكك.';

  @override
  String get noDownloadsBody =>
      'افتح درسًا واضغط «تنزيل» على الفيديو لمشاهدته دون اتصال.';

  @override
  String get deleteAll => 'حذف الكل';

  @override
  String get deleteAllDownloadsConfirm => 'حذف كل التنزيلات؟';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get myVideos => 'فيديوهاتي';

  @override
  String videosCountSize(Object n, Object size) {
    return '$n فيديو · $size';
  }

  @override
  String get statusTrial => 'تجربة';

  @override
  String get statusEnded => 'منتهٍ';

  @override
  String accessUntil(Object date) {
    return 'وصول كامل حتى $date.';
  }

  @override
  String trialUntil(Object date) {
    return 'تجربة مجانية حتى $date.';
  }

  @override
  String get pendingBody => 'دفعتك قيد التحقق.';

  @override
  String get noSubscription => 'لا يوجد اشتراك';

  @override
  String get noSubscriptionBody => 'اختر عرضًا للوصول إلى البرنامج كاملاً.';

  @override
  String get protectedByParent => 'محمي برمز الوالدين';

  @override
  String get languageFrench => 'الفرنسية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get subscriptionEndedTitle => 'انتهى اشتراكك';

  @override
  String get nothingLost => 'لم يضع شيء';

  @override
  String nothingLostBody(Object streak, Object xp) {
    return 'سلسلتك من $streak أيام و$xp XP وكل تقدمك محفوظة.';
  }

  @override
  String get subscribeMyself => 'اختيار عرض بنفسي';

  @override
  String get parentWhatsappMessage =>
      'مرحبًا، انتهى وصولي إلى دراستي. هل يمكنك اختيار عرض لأواصل دروسي؟';

  @override
  String get parentCodeBody =>
      'اطلب من وليّ أمرك إدخال رمزه المكوّن من 4 أرقام للخروج من وضع التركيز.';

  @override
  String get enterParentCode => 'إدخال رمز وليّ الأمر';

  @override
  String parentWeekTotal(Object time) {
    return 'هذا الأسبوع، درس أطفالكم $time في المجموع.';
  }

  @override
  String get parentWeekNone =>
      'لا دراسة بعد هذا الأسبوع — ما رأيكم بتشجيع صغير؟';

  @override
  String streakDaysShort(Object n) {
    return '$n يوم';
  }

  @override
  String get noStreak => 'لا سلسلة';

  @override
  String timeThisWeek(Object time) {
    return '· $time هذا الأسبوع';
  }

  @override
  String get noChildrenTitle => 'أضيفوا طفلكم الأول';

  @override
  String get noChildrenBody =>
      'أنشئوا حسابه في دقيقة: سيدخل باسم المستخدم ورمزه السري.';

  @override
  String get childrenLoadError => 'تعذّر تحميل بيانات أطفالكم.';

  @override
  String get activityLast7Days => 'النشاط خلال 7 أيام';

  @override
  String get childClass => 'القسم';

  @override
  String gradeExamNote(Object exam, Object grade) {
    return '$grade تنتهي بامتحان $exam.';
  }

  @override
  String get childPinLabel => 'الرمز السري للطفل';

  @override
  String get childPinHint => 'سيستعمله للدخول من هاتفه.';

  @override
  String get errChildNameRequired => 'أدخلوا اسم الطفل.';

  @override
  String get addChildError => 'تعذّرت إضافة هذا الطفل — حاولوا مجددًا.';

  @override
  String get giveCredentials => 'أعطوه هذه المعلومات ليتمكن من الدخول.';

  @override
  String get backToHome => 'العودة إلى الرئيسية';

  @override
  String get credentialsCopied => 'تم نسخ معلومات الدخول';

  @override
  String credentialsShareMessage(Object pin, Object username) {
    return 'حسابك في دراستي جاهز!\nاسم المستخدم: $username\nالرمز السري: $pin';
  }

  @override
  String get daysUnit => 'يومًا';

  @override
  String beforeExam(Object exam) {
    return 'قبل $exam';
  }

  @override
  String get currentStreak => 'السلسلة الحالية';

  @override
  String daysShortN(Object n) {
    return '$n ي';
  }

  @override
  String get focusOn => 'مفعّل';

  @override
  String get focusOff => 'غير مفعّل';

  @override
  String get loginCredentials => 'معلومات الدخول';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String get setLogin => 'تعيين';

  @override
  String get insightLoading => 'رفيق يُعدّ تحليل الأسبوع…';

  @override
  String get insightUnavailable => 'التحليل غير متاح حاليًا — حاولوا لاحقًا.';

  @override
  String get insightGenerated => 'أعدّه رفيق (ذكاء اصطناعي)';

  @override
  String get childNotFound => 'الطفل غير موجود.';

  @override
  String get noSubjectsForChild => 'لا توجد مواد متاحة لهذا القسم حاليًا.';

  @override
  String get chooseSubject => 'اختر مادة';

  @override
  String get editCredentials => 'تعديل معلومات الدخول';

  @override
  String get newPinOptional => 'رمز سري جديد';

  @override
  String get newPinOptionalHint => 'اتركوه فارغًا للإبقاء على الرمز الحالي.';

  @override
  String get errPinRequiredNewLogin =>
      'اختاروا رمزًا سريًا من 4 أرقام لهذا الحساب.';

  @override
  String credentialsUpdated(Object username) {
    return 'تم تحديث معلومات الدخول: $username';
  }

  @override
  String weekOf(Object date) {
    return 'أسبوع $date';
  }

  @override
  String get noExamsForChild => 'لا توجد اختبارات بعد لهذا الطفل.';

  @override
  String lessonsInSubject(Object n) {
    return '$n درسًا في هذه المادة';
  }

  @override
  String get lessonsCompleted => 'دروس منتهية';

  @override
  String get withExercisesDone => 'مع تمارين منجزة';

  @override
  String chapterTitle(Object n, Object title) {
    return 'الفصل $n · $title';
  }

  @override
  String lessonStatusExercised(Object n, Object pct) {
    return 'تمارين منجزة · $pct% · المحاولات: $n';
  }

  @override
  String get lessonStatusViewed => 'الدرس منتهٍ · بلا تمارين بعد';

  @override
  String get lessonStatusNotStarted => 'لم يبدأ بعد';

  @override
  String get noContentYet => 'لا يوجد محتوى بعد.';

  @override
  String focusIntro(Object name) {
    return 'خلال هذه الفترات، يبقى دراستي مفتوحًا على هاتف $name، ولا يمكن الخروج منه إلا برمزكم.';
  }

  @override
  String get focusStatusOn => 'مفعّل خلال الفترات أدناه';

  @override
  String get parentCodeSub => 'لفتح قفل الهاتف';

  @override
  String get nextDay => '(اليوم التالي)';

  @override
  String get onIphone => 'على الآيفون';

  @override
  String get iphoneGuidedAccessSetup =>
      'لا يسمح الآيفون لتطبيق بقفل نفسه. مرة واحدة على هاتف الطفل: الإعدادات ← تسهيلات الاستخدام ← الوصول الموجّه ← فعّلوه واختاروا رمزًا. خلال الفترات، سيطلب منه دراستي النقر ثلاث مرات على الزر الجانبي.';

  @override
  String get focusSavedParent => 'تم الحفظ — يُطبَّق عند فتح الطفل للتطبيق.';

  @override
  String get focusSavedDevice => 'تم الحفظ — مفعّل على هذا الهاتف.';

  @override
  String get errFocusPinRequired => 'حدّدوا رمز وليّ الأمر قبل التفعيل.';

  @override
  String get errFocusNeedWindow => 'أضيفوا فترة واحدة على الأقل.';

  @override
  String get errFocusWindowInvalid =>
      'يجب أن تحتوي كل فترة على يوم واحد على الأقل وساعتين مختلفتين.';

  @override
  String get errPinMismatch => 'الرمزان غير متطابقين.';

  @override
  String get errParentPinWrong => 'رمز وليّ الأمر غير صحيح.';

  @override
  String get errParentPinLocked => 'محاولات خاطئة كثيرة — حاولوا بعد 15 دقيقة.';

  @override
  String get noFocusEvents => 'لا شيء حتى الآن.';

  @override
  String get logLeftAppShort => 'غادر التطبيق';

  @override
  String get parentsOnly => 'خاص بأولياء الأمور';

  @override
  String get enterParentCodeBody => 'أدخلوا رمز وليّ الأمر المكوّن من 4 أرقام.';

  @override
  String get needsInternetSettings =>
      'يلزم اتصال بالإنترنت لتعديل هذه الإعدادات.';

  @override
  String get newCode => 'رمز جديد';

  @override
  String get confirmCode => 'تأكيد الرمز';

  @override
  String get subscriptionIntro =>
      'كل المواد والفيديوهات والتمارين والامتحانات وفق البرنامج الدراسي.';

  @override
  String get planNoCommitment => 'بدون التزام';

  @override
  String planDaysDiscount(Object days, Object pct) {
    return '$days يومًا · −$pct٪';
  }

  @override
  String planDays(Object days) {
    return '$days يومًا';
  }

  @override
  String childActiveUntil(Object date) {
    return 'مشترك حتى $date';
  }

  @override
  String childTrialDaysLeft(Object n) {
    return 'تجربة، $n أيام متبقية';
  }

  @override
  String get childInReview => 'الدفع قيد التحقق';

  @override
  String get childNoPlan => 'بدون اشتراك';

  @override
  String get seeMySubscriptions => 'عرض اشتراكاتي';

  @override
  String get payByContact => 'الدفع يدويًا';

  @override
  String get selectAtLeastOneChild => 'اختاروا طفلًا واحدًا على الأقل.';

  @override
  String get noPlans => 'لا توجد باقات متاحة حاليًا.';

  @override
  String get contactConfirmTitle => 'الدفع يدويًا';

  @override
  String get contactConfirmBody =>
      'سيتواصل معك فريقنا عبر واتساب لإتمام الدفع معك. تم تسجيل طلبك في الانتظار.';

  @override
  String contactWhatsappMessage(Object amount, Object names, Object plan) {
    return 'مرحبًا، أرغب في الاشتراك في باقة $plan ($amount أوقية) لـ: $names.';
  }

  @override
  String get transactionCodeHint => 'يوجد في رسالة التأكيد من Bankily.';

  @override
  String get bankilyVerifyNote => 'نتحقق من الدفع ثم نفعّل الاشتراك.';

  @override
  String get errPhoneInvalid => 'أدخلوا رقم هاتف صحيحًا.';

  @override
  String get errTransactionCode => 'أدخلوا رمز العملية المستلم من Bankily.';

  @override
  String get copied => 'تم النسخ';

  @override
  String get paymentSentTitle => 'تم إرسال الدفع';

  @override
  String get paymentSentBody =>
      'نتحقق من دفعكم عبر Bankily، وسيُفعَّل الوصول فور التأكيد.';

  @override
  String get contactSentTitle => 'تم تسجيل الطلب';

  @override
  String get contactSentBody =>
      'يُتمّ فريقنا الدفع معكم عبر واتساب ثم يفعّل الاشتراك.';

  @override
  String pendingDetails(Object code, Object date) {
    return 'تم استلام دفع Bankily بتاريخ $date · الرمز $code. التفعيل فور التأكيد.';
  }

  @override
  String get unpaidDetails => 'في انتظار الدفع مع فريقنا.';

  @override
  String get contactSupport => 'التواصل مع الدعم';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get statusUnpaid => 'غير مدفوع';

  @override
  String get statusScheduled => 'مبرمج';

  @override
  String get statusPaused => 'موقوف';

  @override
  String get statusTrialEnded => 'انتهت التجربة';

  @override
  String upcomingPlan(Object end, Object plan, Object start) {
    return 'الباقة القادمة: $plan، من $start إلى $end.';
  }

  @override
  String endedOn(Object date) {
    return 'انتهى في $date.';
  }

  @override
  String get subscribeAction => 'اشتراك';

  @override
  String get noHistory => 'لا توجد اشتراكات سابقة.';

  @override
  String get freeTrial => 'تجربة مجانية';

  @override
  String childrenTimesPlan(int n, Object plan) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n طفلًا',
      few: '$n أطفال',
      two: 'طفلان',
      one: 'طفل واحد',
    );
    return '$_temp0 × $plan';
  }

  @override
  String get deleteFinalTitle => 'هذا الإجراء نهائي';

  @override
  String get deleteLosesIntro => 'بحذف هذا الحساب، ستفقدون نهائيًا:';

  @override
  String get deleteLossProgress => 'التقدم في جميع الدروس';

  @override
  String get deleteLossXp => 'نقاط الخبرة والمستوى والسلسلة';

  @override
  String get deleteLossHistory => 'سجل التمارين';

  @override
  String get deleteCannotUndo => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String deleteTypeToConfirm(Object word) {
    return 'للتأكيد، اكتبوا $word في الأسفل:';
  }

  @override
  String get deleteForever => 'حذف نهائي';

  @override
  String get deleteFailed => 'فشل الحذف. حاولوا مجددًا أو تواصلوا مع الدعم.';

  @override
  String get deleteDownloadTitle => 'حذف التنزيل؟';

  @override
  String get deleteDownloadBody => 'سيبقى الفيديو متاحًا عبر الإنترنت.';

  @override
  String get videoLabel => 'فيديو';

  @override
  String get offlineShort => 'دون إنترنت';

  @override
  String get nowPlaying => 'قيد التشغيل';

  @override
  String get previousVideo => 'السابق';

  @override
  String get nextVideo => 'التالي';

  @override
  String get signInWho => 'لديك حساب؟ سجّل دخولك';

  @override
  String videoOfMeta(Object min, Object n, Object total) {
    return 'الفيديو $n من $total · $min د';
  }

  @override
  String videoMinutes(Object min) {
    return '$min د';
  }

  @override
  String familyDiscountLine(Object pct) {
    return 'تخفيض العائلة (−$pct٪ ابتداءً من الطفل الثاني)';
  }

  @override
  String familyOfferBanner(Object p2, Object p3) {
    return 'عرض العائلة: −$p2٪ على الطفل الثاني، −$p3٪ على كل طفل بعد الأول ابتداءً من 3 أطفال — يُطبَّق تلقائيًا.';
  }

  @override
  String addChildForDiscount(Object amount, Object name) {
    return 'أضيفوا $name: وفّروا $amount أوقية';
  }

  @override
  String get addAction => 'إضافة';

  @override
  String minusPriceMru(Object amount) {
    return '−$amount أوقية';
  }

  @override
  String weekProgress(Object done, Object total) {
    return '$done من $total امتحانات منجزة';
  }

  @override
  String availableOn(Object day) {
    return 'ابتداءً من $day';
  }

  @override
  String get examToDo => 'للإنجاز';

  @override
  String get weekExamsDone => 'أحسنت، أنجزت كل امتحانات الأسبوع!';

  @override
  String get noExamsThisWeek => 'لا توجد امتحانات بعد هذا الأسبوع.';

  @override
  String get examsOfTheWeek => 'امتحانات الأسبوع';

  @override
  String get photoUnreadableTitle => 'لا أستطيع قراءة صورتك جيدًا';

  @override
  String get photoUnreadableBody =>
      'أعد التقاطها بإضاءة جيدة، والورقة مسطّحة وكاملة داخل الإطار، وبخط واضح.';

  @override
  String get issueBlurry => 'ضبابية';

  @override
  String get issueDark => 'مظلمة';

  @override
  String get issueRotated => 'مائلة';

  @override
  String get issueCropped => 'مقصوصة';

  @override
  String get issueMissingParts => 'ناقصة';

  @override
  String get issueIllegible => 'خط غير مقروء';

  @override
  String get issueNotExercise => 'ليست التمرين';

  @override
  String get askDirassty => 'مساعدة دراستي';

  @override
  String get tutorTitle => 'رفيق يساعدك';

  @override
  String get tutorIntroExercise =>
      'لن أعطيك الجواب مباشرة: سنصل إليه معًا. اختر مساعدة أو اكتب أين توقفت.';

  @override
  String get tutorIntroLesson => 'اسألني عن الدرس، أو اختر مساعدة أدناه.';

  @override
  String get tutorHint => '💡 تلميح';

  @override
  String get tutorGuide => 'أرشدني';

  @override
  String get tutorCheckStep => 'تحقّق من خطوتي';

  @override
  String get tutorExplainStep => 'اشرح هذه الخطوة';

  @override
  String get tutorSolution => 'الحل الكامل';

  @override
  String get tutorExplain => 'اشرح ببساطة';

  @override
  String get tutorStepByStep => 'خطوة بخطوة';

  @override
  String get tutorExample => 'مثال';

  @override
  String get tutorAnotherExample => 'مثال آخر';

  @override
  String get tutorSummary => 'ملخّص';

  @override
  String get tutorInputHintExercise => 'اكتب خطوتك أو سؤالك…';

  @override
  String get tutorInputHintLesson => 'اطرح سؤالك عن الدرس…';

  @override
  String get tutorNeedsText =>
      'اكتب أولًا خطوتك (أو الجزء المراد شرحه) في الخانة.';

  @override
  String get tutorThinking => 'دراستي يفكّر…';

  @override
  String get tutorFinalAnswer => 'الجواب النهائي';

  @override
  String get tutorWhy => 'لماذا:';

  @override
  String get tutorFormulas => 'للتذكّر';

  @override
  String get tutorStepCorrect => 'خطوة صحيحة ✓';

  @override
  String get tutorStepPartial => 'تقريبًا';

  @override
  String get tutorStepIncorrect => 'تحتاج مراجعة';

  @override
  String aiBudgetLeft(Object pct) {
    return 'مساعدة رفيق المتبقية اليوم: $pct٪';
  }

  @override
  String get checkWithPhoto => '📷 تحقّق من ورقتي';

  @override
  String get checkPhotoBody => 'حُلّ على الورقة، ثم صوّر ورقتك (حتى 3 صفحات).';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get checkingCopy => 'دراستي يقرأ ورقتك…';

  @override
  String get resultReasoning => 'الاستدلال';

  @override
  String get resultCalculation => 'الحسابات';

  @override
  String get resultFinalAnswer => 'الجواب النهائي';

  @override
  String get alternativeMethod => 'طريقة أخرى صحيحة أيضًا 👍';

  @override
  String get whatIRead => 'ما قرأته في ورقتك';

  @override
  String get verdictUndetermined => 'يجب التحقّق';

  @override
  String get writeAnswerInstead => 'كتابة جوابي بدل ذلك';

  @override
  String get correctionWellDone => 'ما أحسنت فيه';

  @override
  String get correctionToFix => 'ما يجب تصحيحه';

  @override
  String get correctionSeeSolution => 'عرض الحل الكامل';

  @override
  String get correctionHideSolution => 'إخفاء الحل';

  @override
  String get noActiveSubscriptionTitle => 'لا يوجد اشتراك فعّال';

  @override
  String get subscriptionCheckFailedTitle => 'تعذّر التحقق من اشتراكك';

  @override
  String get subscriptionCheckFailedBody =>
      'تحقق من اتصالك بالإنترنت، ثم اضغط على الزر للتحديث.';

  @override
  String get updateRequiredTitle => 'التحديث ضروري';

  @override
  String get updateRequiredBody =>
      'نسخة جديدة من دراستي متوفرة. ثبّتها لمواصلة استخدام التطبيق — تقدّمك محفوظ.';

  @override
  String get updateAvailableTitle => 'نسخة جديدة متوفرة';

  @override
  String get updateAvailableBody => 'حدّث دراستي للاستفادة من آخر التحسينات.';

  @override
  String get updateNow => 'تحديث الآن';

  @override
  String get updateLater => 'لاحقًا';

  @override
  String get updateWhatsNew => 'الجديد';

  @override
  String get updateNoLink => 'تواصل مع الدعم';

  @override
  String updateVersionLabel(String version) {
    return 'النسخة $version';
  }

  @override
  String get fullAnswerLabel => 'الإجابة الكاملة';

  @override
  String get figureLabel => 'الشكل';

  @override
  String get promoHaveCode => 'لديّ رمز ترويجي';

  @override
  String get promoCodeOptional => 'الرمز الترويجي (اختياري)';

  @override
  String get promoApply => 'تأكيد';

  @override
  String promoApplied(String name) {
    return 'تم تسجيل رمز $name ✓';
  }

  @override
  String get promoUnknown => 'رمز غير معروف — تحقّق من كتابته.';
}
