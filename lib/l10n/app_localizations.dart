import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Dirassty'**
  String get appName;

  /// No description provided for @continueAction.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueAction;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get seeAll;

  /// No description provided for @see.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get see;

  /// No description provided for @offlineBanner.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne · tes téléchargements restent disponibles'**
  String get offlineBanner;

  /// No description provided for @errorLoad.
  ///
  /// In fr, this message translates to:
  /// **'Chargement impossible. Vérifie ta connexion puis réessaie.'**
  String get errorLoad;

  /// No description provided for @screenRecordingBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement d\'écran non autorisé'**
  String get screenRecordingBlocked;

  /// No description provided for @screenRecordingBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour protéger le travail de nos professeurs, ce contenu ne peut pas être filmé.'**
  String get screenRecordingBody;

  /// No description provided for @tagline.
  ///
  /// In fr, this message translates to:
  /// **'Apprendre · Pratiquer · Réussir'**
  String get tagline;

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Dirassty'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In fr, this message translates to:
  /// **'Du Primaire au Bac, apprends à ton rythme et réussis ton année.'**
  String get welcomeBody;

  /// No description provided for @whoAreYou.
  ///
  /// In fr, this message translates to:
  /// **'Qui es-tu ?'**
  String get whoAreYou;

  /// No description provided for @iAmStudent.
  ///
  /// In fr, this message translates to:
  /// **'Je suis élève'**
  String get iAmStudent;

  /// No description provided for @iAmStudentSub.
  ///
  /// In fr, this message translates to:
  /// **'Leçons, exercices et examens'**
  String get iAmStudentSub;

  /// No description provided for @iAmParent.
  ///
  /// In fr, this message translates to:
  /// **'Je suis parent'**
  String get iAmParent;

  /// No description provided for @iAmParentSub.
  ///
  /// In fr, this message translates to:
  /// **'Suivre les progrès de mes enfants'**
  String get iAmParentSub;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @trialLine.
  ///
  /// In fr, this message translates to:
  /// **'Programme scolaire mauritanien · Leçons, exercices et examens'**
  String get trialLine;

  /// No description provided for @studentLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion élève'**
  String get studentLoginTitle;

  /// No description provided for @username.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get username;

  /// No description provided for @pinCode.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get pinCode;

  /// No description provided for @forgotPin.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ?'**
  String get forgotPin;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @parentLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion parent'**
  String get parentLoginTitle;

  /// No description provided for @whatsappNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro WhatsApp'**
  String get whatsappNumber;

  /// No description provided for @newDeviceHint.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau téléphone ? Nous vous enverrons un code de vérification par WhatsApp.'**
  String get newDeviceHint;

  /// No description provided for @verifyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre numéro'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code à 6 chiffres envoyé par WhatsApp au {phone}.'**
  String verifyBody(Object phone);

  /// No description provided for @resendIn.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans {time}'**
  String resendIn(Object time);

  /// No description provided for @changeNumber.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le numéro'**
  String get changeNumber;

  /// No description provided for @verify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get verify;

  /// No description provided for @registerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get registerTitle;

  /// No description provided for @stepOf.
  ///
  /// In fr, this message translates to:
  /// **'Étape {n} sur {total}'**
  String stepOf(Object n, Object total);

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom et nom'**
  String get fullName;

  /// No description provided for @myGrade.
  ///
  /// In fr, this message translates to:
  /// **'Ma classe'**
  String get myGrade;

  /// No description provided for @noGradesOpen.
  ///
  /// In fr, this message translates to:
  /// **'Aucune classe n\'est ouverte aux inscriptions pour le moment.'**
  String get noGradesOpen;

  /// No description provided for @errGradeClosed.
  ///
  /// In fr, this message translates to:
  /// **'Cette classe n\'est plus ouverte aux inscriptions. Choisis-en une autre.'**
  String get errGradeClosed;

  /// No description provided for @aiDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Rafiq est une intelligence artificielle : il peut se tromper.'**
  String get aiDisclaimer;

  /// No description provided for @reportAiAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get reportAiAnswer;

  /// No description provided for @reportAiTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler une réponse de Rafiq'**
  String get reportAiTitle;

  /// No description provided for @reportAiReasonWrong.
  ///
  /// In fr, this message translates to:
  /// **'La réponse est fausse'**
  String get reportAiReasonWrong;

  /// No description provided for @reportAiReasonInappropriate.
  ///
  /// In fr, this message translates to:
  /// **'Contenu inapproprié ou choquant'**
  String get reportAiReasonInappropriate;

  /// No description provided for @reportAiReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre problème'**
  String get reportAiReasonOther;

  /// No description provided for @reportAiCommentHint.
  ///
  /// In fr, this message translates to:
  /// **'Explique en quelques mots (facultatif)'**
  String get reportAiCommentHint;

  /// No description provided for @reportAiSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le signalement'**
  String get reportAiSend;

  /// No description provided for @reportAiThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci ! Notre équipe va vérifier cette réponse.'**
  String get reportAiThanks;

  /// No description provided for @reportAiError.
  ///
  /// In fr, this message translates to:
  /// **'Envoi impossible. Réessaie plus tard.'**
  String get reportAiError;

  /// No description provided for @parentGateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande à un parent'**
  String get parentGateTitle;

  /// No description provided for @parentGateBody.
  ///
  /// In fr, this message translates to:
  /// **'Pour continuer, un parent doit répondre : combien font {a} × {b} ?'**
  String parentGateBody(int a, int b);

  /// No description provided for @parentGateWrong.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas la bonne réponse.'**
  String get parentGateWrong;

  /// No description provided for @parentGateConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get parentGateConfirm;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @selfSignupFromC2.
  ///
  /// In fr, this message translates to:
  /// **'Primaire et 1re année de collège : c\'est un parent qui crée le compte depuis son espace.'**
  String get selfSignupFromC2;

  /// No description provided for @chooseRoleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qui crée le compte ?'**
  String get chooseRoleTitle;

  /// No description provided for @chooseRoleBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton profil pour commencer. Tu pourras tout changer plus tard.'**
  String get chooseRoleBody;

  /// No description provided for @roleStudentDesc.
  ///
  /// In fr, this message translates to:
  /// **'J\'apprends avec mes leçons, mes exercices et Rafiq à mes côtés.'**
  String get roleStudentDesc;

  /// No description provided for @roleStudentBadge.
  ///
  /// In fr, this message translates to:
  /// **'Collège C2 → Lycée'**
  String get roleStudentBadge;

  /// No description provided for @roleStudentPoint1.
  ///
  /// In fr, this message translates to:
  /// **'Cours et exercices du programme mauritanien'**
  String get roleStudentPoint1;

  /// No description provided for @roleStudentPoint2.
  ///
  /// In fr, this message translates to:
  /// **'Rafiq m\'aide pas à pas sur mes devoirs'**
  String get roleStudentPoint2;

  /// No description provided for @roleParentDesc.
  ///
  /// In fr, this message translates to:
  /// **'Je crée les comptes de mes enfants et je suis leurs progrès.'**
  String get roleParentDesc;

  /// No description provided for @roleParentBadge.
  ///
  /// In fr, this message translates to:
  /// **'Primaire → Lycée'**
  String get roleParentBadge;

  /// No description provided for @roleParentPoint1.
  ///
  /// In fr, this message translates to:
  /// **'Un compte pour chaque enfant, dès le primaire'**
  String get roleParentPoint1;

  /// No description provided for @roleParentPoint2.
  ///
  /// In fr, this message translates to:
  /// **'Un résumé de leurs progrès chaque semaine'**
  String get roleParentPoint2;

  /// No description provided for @paymentProof.
  ///
  /// In fr, this message translates to:
  /// **'Capture d\'écran du paiement'**
  String get paymentProof;

  /// No description provided for @addPaymentProof.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la capture d\'écran'**
  String get addPaymentProof;

  /// No description provided for @paymentProofHint.
  ///
  /// In fr, this message translates to:
  /// **'La confirmation Bankily avec le montant et la date.'**
  String get paymentProofHint;

  /// No description provided for @paymentProofAdded.
  ///
  /// In fr, this message translates to:
  /// **'Capture ajoutée'**
  String get paymentProofAdded;

  /// No description provided for @changePaymentProof.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get changePaymentProof;

  /// No description provided for @errPaymentProofRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez la capture d\'écran du paiement.'**
  String get errPaymentProofRequired;

  /// No description provided for @bankilyNumberSoon.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro Bankily sera bientôt affiché ici. En attendant, choisissez « Payer manuellement ».'**
  String get bankilyNumberSoon;

  /// No description provided for @lockedNoPlanTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton offre'**
  String get lockedNoPlanTitle;

  /// No description provided for @lockedNoPlanBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton compte est prêt ! Choisis une offre pour débloquer toutes les leçons, les exercices et Rafiq.'**
  String get lockedNoPlanBody;

  /// No description provided for @lockedPendingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en vérification'**
  String get lockedPendingTitle;

  /// No description provided for @lockedPendingBody.
  ///
  /// In fr, this message translates to:
  /// **'Nous vérifions ton paiement. L\'accès s\'ouvre dès qu\'il est validé — touche « Actualiser » pour vérifier.'**
  String get lockedPendingBody;

  /// No description provided for @lockedManualTitle.
  ///
  /// In fr, this message translates to:
  /// **'Demande enregistrée'**
  String get lockedManualTitle;

  /// No description provided for @lockedManualBody.
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe te contacte pour finaliser le paiement. L\'accès s\'ouvre dès qu\'il est validé.'**
  String get lockedManualBody;

  /// No description provided for @chooseClassTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu es en quelle classe ?'**
  String get chooseClassTitle;

  /// No description provided for @chooseClassBody.
  ///
  /// In fr, this message translates to:
  /// **'On prépare ton programme selon ta classe.'**
  String get chooseClassBody;

  /// No description provided for @havePromoCode.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai un code promo'**
  String get havePromoCode;

  /// No description provided for @changeClass.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get changeClass;

  /// No description provided for @cyclePrimary.
  ///
  /// In fr, this message translates to:
  /// **'Primaire'**
  String get cyclePrimary;

  /// No description provided for @cycleMiddle.
  ///
  /// In fr, this message translates to:
  /// **'Collège'**
  String get cycleMiddle;

  /// No description provided for @cycleHigh.
  ///
  /// In fr, this message translates to:
  /// **'Lycée'**
  String get cycleHigh;

  /// No description provided for @available.
  ///
  /// In fr, this message translates to:
  /// **'✓ Disponible'**
  String get available;

  /// No description provided for @choosePin.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un code PIN'**
  String get choosePin;

  /// No description provided for @acceptTerms.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte la politique de confidentialité'**
  String get acceptTerms;

  /// No description provided for @getWhatsappCode.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir le code WhatsApp'**
  String get getWhatsappCode;

  /// No description provided for @trialTitle.
  ///
  /// In fr, this message translates to:
  /// **'7 jours offerts'**
  String get trialTitle;

  /// No description provided for @trialBody.
  ///
  /// In fr, this message translates to:
  /// **'Accès complet à tout le programme de ta classe, sans paiement.'**
  String get trialBody;

  /// No description provided for @startTrial.
  ///
  /// In fr, this message translates to:
  /// **'Commencer mon essai'**
  String get startTrial;

  /// No description provided for @claimBody.
  ///
  /// In fr, this message translates to:
  /// **'Ton parent t\'a créé un compte. Saisis le code d\'invitation qu\'il t\'a envoyé.'**
  String get claimBody;

  /// No description provided for @hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}'**
  String hello(Object name);

  /// No description provided for @level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {n}'**
  String level(Object n);

  /// No description provided for @xpToNext.
  ///
  /// In fr, this message translates to:
  /// **'Encore {xp} XP pour atteindre le niveau {n}'**
  String xpToNext(Object xp, Object n);

  /// No description provided for @myWeek.
  ///
  /// In fr, this message translates to:
  /// **'Ma semaine'**
  String get myWeek;

  /// No description provided for @correctAnswers.
  ///
  /// In fr, this message translates to:
  /// **'Bonnes réponses'**
  String get correctAnswers;

  /// No description provided for @exercisesDone.
  ///
  /// In fr, this message translates to:
  /// **'Exercices faits'**
  String get exercisesDone;

  /// No description provided for @activeDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours actifs'**
  String get activeDays;

  /// No description provided for @studyTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps d\'étude'**
  String get studyTime;

  /// No description provided for @mySubjects.
  ///
  /// In fr, this message translates to:
  /// **'Mes matières'**
  String get mySubjects;

  /// No description provided for @lessonsCount.
  ///
  /// In fr, this message translates to:
  /// **'{n} leçons'**
  String lessonsCount(Object n);

  /// No description provided for @weeklyExam.
  ///
  /// In fr, this message translates to:
  /// **'Examen de la semaine'**
  String get weeklyExam;

  /// No description provided for @prepare.
  ///
  /// In fr, this message translates to:
  /// **'Me préparer'**
  String get prepare;

  /// No description provided for @homeworkHelper.
  ///
  /// In fr, this message translates to:
  /// **'Rafiq – Aide aux devoirs'**
  String get homeworkHelper;

  /// No description provided for @homeworkHelperSub.
  ///
  /// In fr, this message translates to:
  /// **'Prends ton exercice en photo, Rafiq te guide étape par étape.'**
  String get homeworkHelperSub;

  /// No description provided for @tabHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabHome;

  /// No description provided for @tabSubjects.
  ///
  /// In fr, this message translates to:
  /// **'Matières'**
  String get tabSubjects;

  /// No description provided for @tabExams.
  ///
  /// In fr, this message translates to:
  /// **'Examens'**
  String get tabExams;

  /// No description provided for @tabProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @tabSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get tabSubscription;

  /// No description provided for @journeyVideo.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get journeyVideo;

  /// No description provided for @journeyLesson.
  ///
  /// In fr, this message translates to:
  /// **'Leçon'**
  String get journeyLesson;

  /// No description provided for @journeyExercises.
  ///
  /// In fr, this message translates to:
  /// **'Exercices'**
  String get journeyExercises;

  /// No description provided for @statusMastered.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrisée'**
  String get statusMastered;

  /// No description provided for @statusViewed.
  ///
  /// In fr, this message translates to:
  /// **'Vue'**
  String get statusViewed;

  /// No description provided for @statusNotStarted.
  ///
  /// In fr, this message translates to:
  /// **'Non commencée'**
  String get statusNotStarted;

  /// No description provided for @download.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger · {size}'**
  String download(Object size);

  /// No description provided for @downloadWifiHint.
  ///
  /// In fr, this message translates to:
  /// **'Télécharge en Wi-Fi pour regarder sans connexion et économiser tes données.'**
  String get downloadWifiHint;

  /// No description provided for @inThisLesson.
  ///
  /// In fr, this message translates to:
  /// **'Dans cette leçon'**
  String get inThisLesson;

  /// No description provided for @continueToLesson.
  ///
  /// In fr, this message translates to:
  /// **'Continuer vers la leçon'**
  String get continueToLesson;

  /// No description provided for @realLife.
  ///
  /// In fr, this message translates to:
  /// **'Dans la vraie vie'**
  String get realLife;

  /// No description provided for @checkUnderstanding.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta compréhension'**
  String get checkUnderstanding;

  /// No description provided for @nextConcept.
  ///
  /// In fr, this message translates to:
  /// **'Notion suivante'**
  String get nextConcept;

  /// No description provided for @answerToContinue.
  ///
  /// In fr, this message translates to:
  /// **'Réponds juste pour continuer'**
  String get answerToContinue;

  /// No description provided for @workedExample.
  ///
  /// In fr, this message translates to:
  /// **'Exemple résolu'**
  String get workedExample;

  /// No description provided for @commonMistake.
  ///
  /// In fr, this message translates to:
  /// **'Erreur fréquente'**
  String get commonMistake;

  /// No description provided for @revisionSheet.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de révision'**
  String get revisionSheet;

  /// No description provided for @formulas.
  ///
  /// In fr, this message translates to:
  /// **'Formules à retenir'**
  String get formulas;

  /// No description provided for @definitions.
  ///
  /// In fr, this message translates to:
  /// **'Définitions'**
  String get definitions;

  /// No description provided for @keyFacts.
  ///
  /// In fr, this message translates to:
  /// **'À savoir'**
  String get keyFacts;

  /// No description provided for @goToExercises.
  ///
  /// In fr, this message translates to:
  /// **'Passer aux exercices'**
  String get goToExercises;

  /// No description provided for @questionOf.
  ///
  /// In fr, this message translates to:
  /// **'Question {n}/{total}'**
  String questionOf(Object n, Object total);

  /// No description provided for @check.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get check;

  /// No description provided for @correctFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Bravo, c\'est juste !'**
  String get correctFeedback;

  /// No description provided for @wrongFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait'**
  String get wrongFeedback;

  /// No description provided for @xpGain.
  ///
  /// In fr, this message translates to:
  /// **'+{xp} XP'**
  String xpGain(Object xp);

  /// No description provided for @streakDays.
  ///
  /// In fr, this message translates to:
  /// **'{n} jours de suite'**
  String streakDays(Object n);

  /// No description provided for @streakBody.
  ///
  /// In fr, this message translates to:
  /// **'Ta série continue. Reviens demain pour la garder.'**
  String get streakBody;

  /// No description provided for @score.
  ///
  /// In fr, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @duration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get duration;

  /// No description provided for @xpEarned.
  ///
  /// In fr, this message translates to:
  /// **'XP gagnés'**
  String get xpEarned;

  /// No description provided for @reviewMistakes.
  ///
  /// In fr, this message translates to:
  /// **'Revoir mes {n} erreurs'**
  String reviewMistakes(Object n);

  /// No description provided for @backHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backHome;

  /// No description provided for @leaveSessionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quitter la session ?'**
  String get leaveSessionTitle;

  /// No description provided for @yourAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse'**
  String get yourAnswer;

  /// No description provided for @aiCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Correction de Rafiq'**
  String get aiCorrection;

  /// No description provided for @almost.
  ///
  /// In fr, this message translates to:
  /// **'Presque !'**
  String get almost;

  /// No description provided for @correctAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse'**
  String get correctAnswer;

  /// No description provided for @similarExercise.
  ///
  /// In fr, this message translates to:
  /// **'Exercice similaire'**
  String get similarExercise;

  /// No description provided for @watchMethod.
  ///
  /// In fr, this message translates to:
  /// **'Voir la méthode en vidéo'**
  String get watchMethod;

  /// No description provided for @helperGuideNote.
  ///
  /// In fr, this message translates to:
  /// **'Dirassty te guide sans donner la réponse directement.'**
  String get helperGuideNote;

  /// No description provided for @typeAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Écris ta réponse…'**
  String get typeAnswer;

  /// No description provided for @exams.
  ///
  /// In fr, this message translates to:
  /// **'Examens'**
  String get exams;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get thisWeek;

  /// No description provided for @recentResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats récents'**
  String get recentResults;

  /// No description provided for @upcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get upcoming;

  /// No description provided for @startExam.
  ///
  /// In fr, this message translates to:
  /// **'Commencer l\'examen'**
  String get startExam;

  /// No description provided for @finishExam.
  ///
  /// In fr, this message translates to:
  /// **'Terminer l\'examen'**
  String get finishExam;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Précédente'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivante'**
  String get next;

  /// No description provided for @byChapter.
  ///
  /// In fr, this message translates to:
  /// **'Par chapitre'**
  String get byChapter;

  /// No description provided for @myDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Mes téléchargements'**
  String get myDownloads;

  /// No description provided for @wifiOnly.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger uniquement en Wi-Fi'**
  String get wifiOnly;

  /// No description provided for @offlineExpired.
  ///
  /// In fr, this message translates to:
  /// **'Accès hors ligne expiré'**
  String get offlineExpired;

  /// No description provided for @reconnect.
  ///
  /// In fr, this message translates to:
  /// **'Se reconnecter'**
  String get reconnect;

  /// No description provided for @noDownloads.
  ///
  /// In fr, this message translates to:
  /// **'Aucun téléchargement'**
  String get noDownloads;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @parentalControl.
  ///
  /// In fr, this message translates to:
  /// **'Contrôle parental'**
  String get parentalControl;

  /// No description provided for @faq.
  ///
  /// In fr, this message translates to:
  /// **'Questions fréquentes'**
  String get faq;

  /// No description provided for @whatsappSupport.
  ///
  /// In fr, this message translates to:
  /// **'Support WhatsApp'**
  String get whatsappSupport;

  /// No description provided for @rateApp.
  ///
  /// In fr, this message translates to:
  /// **'Noter l\'application'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In fr, this message translates to:
  /// **'Partager Dirassty'**
  String get shareApp;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteAccount;

  /// No description provided for @subscriptionActive.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement actif'**
  String get subscriptionActive;

  /// No description provided for @trialEnded.
  ///
  /// In fr, this message translates to:
  /// **'Ton essai est terminé'**
  String get trialEnded;

  /// No description provided for @trialEndedBody.
  ///
  /// In fr, this message translates to:
  /// **'Demande à ton parent de choisir une offre pour continuer tes leçons et tes exercices.'**
  String get trialEndedBody;

  /// No description provided for @notifyParent.
  ///
  /// In fr, this message translates to:
  /// **'Prévenir mon parent sur WhatsApp'**
  String get notifyParent;

  /// No description provided for @alreadyPaid.
  ///
  /// In fr, this message translates to:
  /// **'Déjà payé ? Actualiser'**
  String get alreadyPaid;

  /// No description provided for @focusUntil.
  ///
  /// In fr, this message translates to:
  /// **'Mode concentration jusqu\'à {time}'**
  String focusUntil(Object time);

  /// No description provided for @unlock.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller'**
  String get unlock;

  /// No description provided for @parentCode.
  ///
  /// In fr, this message translates to:
  /// **'Code parent'**
  String get parentCode;

  /// No description provided for @guidedAccessHint.
  ///
  /// In fr, this message translates to:
  /// **'Sur iPhone : active l\'Accès guidé (triple clic sur le bouton latéral) pour rester dans Dirassty.'**
  String get guidedAccessHint;

  /// No description provided for @focusBlockedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pas tout de suite !'**
  String get focusBlockedTitle;

  /// No description provided for @focusBlockedBody.
  ///
  /// In fr, this message translates to:
  /// **'Le mode concentration est actif jusqu\'à {time}. Tu pourras te déconnecter après, ou avec le code de ton parent.'**
  String focusBlockedBody(Object time);

  /// No description provided for @keepStudying.
  ///
  /// In fr, this message translates to:
  /// **'Continuer à étudier'**
  String get keepStudying;

  /// No description provided for @parentSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace parent'**
  String get parentSpace;

  /// No description provided for @myChildren.
  ///
  /// In fr, this message translates to:
  /// **'Mes enfants'**
  String get myChildren;

  /// No description provided for @addChild.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un enfant'**
  String get addChild;

  /// No description provided for @subscribeFor.
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner pour {name}'**
  String subscribeFor(Object name);

  /// No description provided for @subscribed.
  ///
  /// In fr, this message translates to:
  /// **'Abonnée'**
  String get subscribed;

  /// No description provided for @trialDaysLeft.
  ///
  /// In fr, this message translates to:
  /// **'Essai · {n} j'**
  String trialDaysLeft(Object n);

  /// No description provided for @childFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom de l\'enfant'**
  String get childFirstName;

  /// No description provided for @createChildAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get createChildAccount;

  /// No description provided for @childReady.
  ///
  /// In fr, this message translates to:
  /// **'Le compte de {name} est prêt'**
  String childReady(Object name);

  /// No description provided for @shareWhatsapp.
  ///
  /// In fr, this message translates to:
  /// **'Partager par WhatsApp'**
  String get shareWhatsapp;

  /// No description provided for @copyCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Copier les identifiants'**
  String get copyCredentials;

  /// No description provided for @daysUntilExam.
  ///
  /// In fr, this message translates to:
  /// **'{n} jours avant le {exam}'**
  String daysUntilExam(Object n, Object exam);

  /// No description provided for @examConcours.
  ///
  /// In fr, this message translates to:
  /// **'Concours'**
  String get examConcours;

  /// No description provided for @examBrevet.
  ///
  /// In fr, this message translates to:
  /// **'Brevet'**
  String get examBrevet;

  /// No description provided for @examBac.
  ///
  /// In fr, this message translates to:
  /// **'Bac'**
  String get examBac;

  /// No description provided for @weeklyInsight.
  ///
  /// In fr, this message translates to:
  /// **'Analyse de la semaine'**
  String get weeklyInsight;

  /// No description provided for @masteryBySubject.
  ///
  /// In fr, this message translates to:
  /// **'Maîtrise par matière'**
  String get masteryBySubject;

  /// No description provided for @examHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des examens'**
  String get examHistory;

  /// No description provided for @lessonDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail leçon par leçon'**
  String get lessonDetail;

  /// No description provided for @focusMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode concentration'**
  String get focusMode;

  /// No description provided for @enableFocus.
  ///
  /// In fr, this message translates to:
  /// **'Activer le mode concentration'**
  String get enableFocus;

  /// No description provided for @timeWindow.
  ///
  /// In fr, this message translates to:
  /// **'Créneau {n}'**
  String timeWindow(Object n);

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get start;

  /// No description provided for @end.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get end;

  /// No description provided for @addWindow.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un créneau'**
  String get addWindow;

  /// No description provided for @focusLog.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get focusLog;

  /// No description provided for @logLeftApp.
  ///
  /// In fr, this message translates to:
  /// **'A quitté l\'application {min} min'**
  String logLeftApp(Object min);

  /// No description provided for @logUnlocked.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouillé avec votre code'**
  String get logUnlocked;

  /// No description provided for @subscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get subscription;

  /// No description provided for @planMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get planMonthly;

  /// No description provided for @planQuarterly.
  ///
  /// In fr, this message translates to:
  /// **'Trimestriel'**
  String get planQuarterly;

  /// No description provided for @planYearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get planYearly;

  /// No description provided for @popular.
  ///
  /// In fr, this message translates to:
  /// **'Populaire'**
  String get popular;

  /// No description provided for @forWhichChildren.
  ///
  /// In fr, this message translates to:
  /// **'Pour quels enfants ?'**
  String get forWhichChildren;

  /// No description provided for @familyDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Réduction famille'**
  String get familyDiscount;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @priceMru.
  ///
  /// In fr, this message translates to:
  /// **'{amount} MRU'**
  String priceMru(Object amount);

  /// No description provided for @payWithBankily.
  ///
  /// In fr, this message translates to:
  /// **'Payer avec Bankily'**
  String get payWithBankily;

  /// No description provided for @bankilyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement Bankily'**
  String get bankilyTitle;

  /// No description provided for @amountToSend.
  ///
  /// In fr, this message translates to:
  /// **'Montant à envoyer'**
  String get amountToSend;

  /// No description provided for @merchantNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro Bankily Dirassty'**
  String get merchantNumber;

  /// No description provided for @bankilyStep1.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrez Bankily et envoyez le montant au numéro Bankily Dirassty ci-dessus.'**
  String get bankilyStep1;

  /// No description provided for @bankilyStep2.
  ///
  /// In fr, this message translates to:
  /// **'Faites une capture d\'écran de la confirmation du paiement.'**
  String get bankilyStep2;

  /// No description provided for @bankilyStep3.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez-la ci-dessous avec votre numéro, puis confirmez.'**
  String get bankilyStep3;

  /// No description provided for @bankilyPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro Bankily utilisé'**
  String get bankilyPhone;

  /// No description provided for @transactionCode.
  ///
  /// In fr, this message translates to:
  /// **'Code de transaction'**
  String get transactionCode;

  /// No description provided for @confirmPayment.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le paiement'**
  String get confirmPayment;

  /// No description provided for @mySubscriptions.
  ///
  /// In fr, this message translates to:
  /// **'Mes abonnements'**
  String get mySubscriptions;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get statusActive;

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En vérification'**
  String get statusPending;

  /// No description provided for @statusExpired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get statusExpired;

  /// No description provided for @statusRefused.
  ///
  /// In fr, this message translates to:
  /// **'Paiement refusé'**
  String get statusRefused;

  /// No description provided for @renew.
  ///
  /// In fr, this message translates to:
  /// **'Renouveler'**
  String get renew;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Disponible hors ligne'**
  String get statusDownloaded;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get downloadNoSize;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Échec du téléchargement — vérifie ta connexion et réessaie.'**
  String get downloadFailed;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get backspace;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Utilise l\'identifiant donné par ton parent.'**
  String get studentLoginBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre numéro WhatsApp et votre code PIN.'**
  String get parentLoginBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccountYet;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ?'**
  String get forgotPinStudentTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Demande à ton parent : il peut voir ou changer ton code PIN depuis son espace parent.'**
  String get forgotPinStudentBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Contactez notre support WhatsApp pour réinitialiser votre code PIN.'**
  String get forgotPinParentBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'D\'accord'**
  String get ok;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur ou code PIN incorrect.'**
  String get wrongStudentCredentials;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Numéro ou code PIN incorrect.'**
  String get wrongParentCredentials;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Réessaie dans {min} min.'**
  String pinLocked(Object min);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ? Demande à ton parent'**
  String get askParentForPin;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Quelques informations pour préparer ton programme.'**
  String get registerBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Quelques informations pour créer votre espace parent.'**
  String get registerParentBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pour recevoir ton code de vérification'**
  String get phoneHintVerify;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Facultatif · pour vérifier ton compte et suivre tes progrès'**
  String get phoneHintOptional;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'4 chiffres, faciles à retenir pour toi mais pas pour les autres.'**
  String get pinHint;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton code PIN'**
  String get enterPin;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get createMyAccount;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton prénom et ton nom.'**
  String get errNameRequired;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'3 à 20 lettres ou chiffres latins, sans espace.'**
  String get errUsernameFormat;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Saisis ton numéro WhatsApp.'**
  String get errPhoneRequired;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Le code PIN doit contenir 4 chiffres.'**
  String get errPinFormat;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Accepte la politique de confidentialité pour continuer.'**
  String get errTermsRequired;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec ce numéro — connecte-toi plutôt.'**
  String get errAccountExists;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ce nom d\'utilisateur est déjà pris — essaie-en un autre.'**
  String get errUsernameTaken;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Attends un instant avant de redemander un code.'**
  String get errTooSoon;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Code expiré — redemande un nouveau code.'**
  String get errCodeExpired;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect.'**
  String get errIncorrectCode;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives — redemande un nouveau code.'**
  String get errTooManyAttempts;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucun code en attente — redemande un nouveau code.'**
  String get errNoPendingCode;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Vérifie ta connexion puis réessaie.'**
  String get errGeneric;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resendCode;

  /// Button on the WhatsApp-code screen: pastes the code copied from the WhatsApp message.
  ///
  /// In fr, this message translates to:
  /// **'Coller le code'**
  String get pasteCode;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Appui long pour coller le code'**
  String get pasteCodeHint;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Compte créé'**
  String get accountCreated;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} jours offerts'**
  String trialTitleDays(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Accès complet à tout le programme de {grade}, sans paiement.'**
  String trialBodyGrade(Object grade);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Toutes les leçons et vidéos'**
  String get trialFeatureLessons;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'QCM et exercices corrigés par Rafiq (IA)'**
  String get trialFeatureQcm;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Examens hebdomadaires'**
  String get trialFeatureExams;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aide aux devoirs par photo avec Rafiq'**
  String get trialFeatureHelper;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ensuite à partir de {price} MRU par mois. Aucun prélèvement automatique : un parent choisit l\'offre et paie via Bankily.'**
  String trialFooterPrice(Object price);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucun prélèvement automatique : un parent choisit l\'offre et paie via Bankily.'**
  String get trialFooterNoPrice;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ton compte est prêt'**
  String get accountReadyTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Choisis une offre pour accéder à tout le programme de {grade}.'**
  String accountReadyBody(Object grade);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Choisir une offre'**
  String get choosePlan;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{xp} / {total} XP'**
  String xpOfTotal(Object xp, Object total);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Dans {n} jours'**
  String inDays(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get tomorrow;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get availableNow;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} questions'**
  String questionsCount(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{h} h {m}'**
  String hoursMinutes(Object h, Object m);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{m} min'**
  String minutesShort(Object m);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucune matière disponible pour ta classe pour le moment.'**
  String get noSubjects;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'examen cette semaine'**
  String get noExamThisWeek;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Le prochain examen apparaîtra ici dès qu\'il sera disponible.'**
  String get noExamThisWeekBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ton profil.'**
  String get profileLoadError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} chapitres'**
  String chaptersCount(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} leçons maîtrisées'**
  String masteredLessonsCount(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get filterAll;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'À revoir'**
  String get filterToReview;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get filterOffline;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} leçons · {m} maîtrisées'**
  String chapterMeta(Object n, Object m);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Contenu à venir'**
  String get comingSoon;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Les leçons de cette matière arrivent bientôt.'**
  String get comingSoonBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Rien à revoir pour l\'instant'**
  String get noLessonsToReview;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Les leçons vues mais pas encore maîtrisées apparaîtront ici.'**
  String get noLessonsToReviewBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucune leçon hors ligne'**
  String get noOfflineLessons;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Télécharge la vidéo d\'une leçon pour la retrouver ici sans connexion.'**
  String get noOfflineLessonsBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger cette matière.'**
  String get subjectLoadError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Mes matières'**
  String get mySubjectsTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{chapter} · Leçon {n}'**
  String lessonLabel(Object chapter, Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Notion {n} sur {total}'**
  String conceptOf(Object n, Object total);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'✓ Juste ! La notion suivante est débloquée.'**
  String get correctUnlocked;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas tout à fait — relis la notion et réessaie.'**
  String get wrongTryAgain;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Voici la bonne réponse :'**
  String get revealedAnswer;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Termine les exemples pour débloquer la question.'**
  String get finishExamplesFirst;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Exemple suivant'**
  String get nextExample;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Exemple {n} sur {total}'**
  String exampleOf(Object n, Object total);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Énoncé'**
  String get statement;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Afficher la solution étape par étape'**
  String get showSolution;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Revoir la vidéo'**
  String get reviewVideo;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Le contenu de cette leçon arrive bientôt.'**
  String get lessonComingSoon;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Leçon introuvable.'**
  String get lessonNotFound;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger cette leçon.'**
  String get lessonLoadError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà lu cette leçon'**
  String get alreadyReadTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Que veux-tu faire maintenant ?'**
  String get alreadyReadBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Revoir le cours'**
  String get redoLesson;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'La vidéo et l\'explication depuis le début'**
  String get redoLessonSub;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'QCM'**
  String get qcmTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Questions à choix multiples, correction immédiate'**
  String get qcmSub;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Exercices guidés'**
  String get guidedExercises;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Exercices ouverts corrigés par Rafiq (IA)'**
  String get guidedExercisesSub;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Déjà fait'**
  String get alreadyDone;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Commencer le QCM'**
  String get startQcm;

  /// Last lesson step when the lesson has no QCM or exercises: marks it read and goes back.
  ///
  /// In fr, this message translates to:
  /// **'Terminer la leçon'**
  String get finishLesson;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{lesson} · Question {n}'**
  String questionTopic(Object lesson, Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Tes réponses de ce QCM ne seront pas enregistrées.'**
  String get leaveSessionBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get leave;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Continuer le QCM'**
  String get stayInSession;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Voir mes résultats'**
  String get seeResults;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Indice'**
  String get hint;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Leçon validée'**
  String get lessonValidated;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas encore maîtrisée ({pct} %) — refais le QCM pour progresser.'**
  String notMasteredYet(Object pct);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Recommencer le QCM'**
  String get retryQcm;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de QCM'**
  String get noQcmTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Les questions de cette leçon arrivent bientôt.'**
  String get noQcmBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Retour à la leçon'**
  String get backToLesson;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les questions.'**
  String get qcmLoadError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Tes erreurs'**
  String get mistakesTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ta réponse : {a}'**
  String yourAnswerWas(Object a);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse : {a}'**
  String correctAnswerWas(Object a);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{lesson} · QCM'**
  String qcmScoreTitle(Object lesson);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Exercice ouvert · {lesson}'**
  String openExerciseLabel(Object lesson);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Exercice {n}'**
  String exerciseN(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Essai {n}'**
  String attemptN(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Soumettre ma réponse'**
  String get submitAnswer;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Symboles utiles'**
  String get usefulSymbols;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Voir la correction'**
  String get seeCorrection;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Relis l\'indice, puis demande la correction — ou corrige d\'abord ta réponse.'**
  String get hintBeforeCorrection;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Correction en cours…'**
  String get correcting;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Création d\'un exercice similaire…'**
  String get generatingExercise;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Juste !'**
  String get verdictCorrect;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'À revoir'**
  String get verdictReview;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Corriger ma réponse'**
  String get reviseAnswer;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Exercice suivant'**
  String get nextExercise;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'exercices'**
  String get noExercisesTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Les exercices de cette leçon arrivent bientôt.'**
  String get noExercisesBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les exercices.'**
  String get exercisesLoadError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'La méthode en vidéo'**
  String get methodVideos;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Prends ton exercice en photo'**
  String get photoPrompt;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Cadre bien l\'énoncé, avec une bonne lumière.'**
  String get photoPromptBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Caméra'**
  String get camera;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Analyser'**
  String get analyze;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Dirassty lit ton exercice…'**
  String get analyzingPhoto;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{subject} · détecté'**
  String detectedSubject(Object subject);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Voici ce que j\'ai lu :'**
  String get readProblem;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'On le résout ensemble, étape par étape.'**
  String get letsSolveTogether;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Étape suivante'**
  String get nextStep;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Voir la réponse'**
  String get showAnswer;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Réponse'**
  String get answerLabel;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Notions clés'**
  String get keyConceptsLabel;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle photo'**
  String get newPhoto;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Reprendre la photo'**
  String get retakePhoto;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Un examen par semaine et par matière principale.'**
  String get examsBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'examen'**
  String get seeExam;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Passés'**
  String get filterPast;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Examen hebdomadaire'**
  String get weeklyExamBadge;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'À rendre'**
  String get dueBy;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Questions'**
  String get questionsLabel;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'XP max'**
  String get xpMax;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Avant de commencer'**
  String get beforeStart;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Le chronomètre démarre dès que tu appuies sur Commencer.'**
  String get examRuleTimer;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Tu peux passer une question et y revenir avant la fin.'**
  String get examRuleSkip;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Installe-toi au calme : l\'examen ne peut pas être mis en pause.'**
  String get examRuleCalm;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Chaque réponse est enregistrée dès que tu la choisis.'**
  String get examRuleSaved;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Question {n} passée · tu pourras y revenir'**
  String skippedHint(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Terminer l\'examen ?'**
  String get finishExamTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} questions sans réponse compteront comme fausses.'**
  String finishExamUnanswered(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Tu as répondu à toutes les questions.'**
  String get finishExamAll;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Terminer maintenant'**
  String get finishNow;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Continuer l\'examen'**
  String get keepGoing;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Très bon travail, {name}'**
  String resultsGreat(Object name);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Bon travail, {name}'**
  String resultsGood(Object name);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Continue tes efforts, {name}'**
  String resultsKeepGoing(Object name);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Par leçon'**
  String get byLesson;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Tes réponses'**
  String get yourAnswers;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Manqué'**
  String get missed;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucun examen pour le moment'**
  String get noExams;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Tes examens de la semaine apparaîtront ici.'**
  String get noExamsBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucun examen passé'**
  String get noPastExams;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger tes examens.'**
  String get examsLoadError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger cet examen.'**
  String get examLoadError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'L\'envoi a échoué. Vérifie ta connexion puis réessaie.'**
  String get submitError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Voir le résultat'**
  String get seeResultsExam;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{size} utilisés'**
  String storageUsed(Object size);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Connecte-toi à Internet pour réactiver tes vidéos.'**
  String get offlineExpiredBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Les vidéos téléchargées restent disponibles hors ligne jusqu\'à la fin de ton abonnement.'**
  String get downloadsFooter;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ouvre une leçon et touche « Télécharger » sur la vidéo pour la regarder sans connexion.'**
  String get noDownloadsBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Tout supprimer'**
  String get deleteAll;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer tous les téléchargements ?'**
  String get deleteAllDownloadsConfirm;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Mes vidéos'**
  String get myVideos;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} vidéos · {size}'**
  String videosCountSize(Object n, Object size);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Essai'**
  String get statusTrial;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get statusEnded;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Accès complet jusqu\'au {date}.'**
  String accessUntil(Object date);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit jusqu\'au {date}.'**
  String trialUntil(Object date);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ton paiement est en cours de vérification.'**
  String get pendingBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement'**
  String get noSubscription;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Choisis une offre pour accéder à tout le programme.'**
  String get noSubscriptionBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Protégé par le code parent'**
  String get protectedByParent;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ton abonnement est terminé'**
  String get subscriptionEndedTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Rien n\'est perdu'**
  String get nothingLost;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ta série de {streak} jours, tes {xp} XP et tous tes progrès sont sauvegardés.'**
  String nothingLostBody(Object streak, Object xp);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Choisir une offre moi-même'**
  String get subscribeMyself;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, mon accès à Dirassty est terminé. Peux-tu choisir une offre pour que je continue mes leçons ?'**
  String get parentWhatsappMessage;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Demande à ton parent de saisir son code à 4 chiffres pour quitter le mode concentration.'**
  String get parentCodeBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code parent'**
  String get enterParentCode;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine, vos enfants ont étudié {time} au total.'**
  String parentWeekTotal(Object time);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'étude cette semaine — un petit encouragement ?'**
  String get parentWeekNone;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} jours'**
  String streakDaysShort(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas de série'**
  String get noStreak;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'· {time} cette semaine'**
  String timeThisWeek(Object time);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre premier enfant'**
  String get noChildrenTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Créez son compte en une minute : il se connectera avec son nom d\'utilisateur et son code PIN.'**
  String get noChildrenBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos enfants.'**
  String get childrenLoadError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Activité sur 7 jours'**
  String get activityLast7Days;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Classe'**
  String get childClass;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{grade} se termine par le {exam}.'**
  String gradeExamNote(Object exam, Object grade);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Code PIN de l\'enfant'**
  String get childPinLabel;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Il l\'utilisera pour se connecter sur son téléphone.'**
  String get childPinHint;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le prénom de l\'enfant.'**
  String get errChildNameRequired;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ajouter cet enfant — réessayez.'**
  String get addChildError;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Donnez-lui ces identifiants pour qu\'il se connecte.'**
  String get giveCredentials;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Identifiants copiés'**
  String get credentialsCopied;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ton compte Dirassty est prêt !\nNom d\'utilisateur : {username}\nCode PIN : {pin}'**
  String credentialsShareMessage(Object pin, Object username);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get daysUnit;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'avant le {exam}'**
  String beforeExam(Object exam);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Série en cours'**
  String get currentStreak;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} j'**
  String daysShortN(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Activé'**
  String get focusOn;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get focusOff;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Identifiants de connexion'**
  String get loginCredentials;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Définir'**
  String get setLogin;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Rafiq prépare l\'analyse de la semaine…'**
  String get insightLoading;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Analyse indisponible pour l\'instant — réessayez plus tard.'**
  String get insightUnavailable;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Généré par Rafiq (IA)'**
  String get insightGenerated;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Enfant introuvable.'**
  String get childNotFound;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucune matière disponible pour cette classe pour le moment.'**
  String get noSubjectsForChild;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Choisir une matière'**
  String get chooseSubject;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Modifier les identifiants'**
  String get editCredentials;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code PIN'**
  String get newPinOptional;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Laissez vide pour garder le code actuel.'**
  String get newPinOptionalHint;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un code PIN à 4 chiffres pour ce compte.'**
  String get errPinRequiredNewLogin;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Identifiants mis à jour : {username}'**
  String credentialsUpdated(Object username);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Semaine du {date}'**
  String weekOf(Object date);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'examen pour cet enfant.'**
  String get noExamsForChild;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n} leçons dans cette matière'**
  String lessonsInSubject(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Leçons terminées'**
  String get lessonsCompleted;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Avec exercices faits'**
  String get withExercisesDone;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Chapitre {n} · {title}'**
  String chapterTitle(Object n, Object title);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Exercices faits · {pct} % · tentatives : {n}'**
  String lessonStatusExercised(Object n, Object pct);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Leçon terminée · pas encore d\'exercices'**
  String get lessonStatusViewed;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas encore commencée'**
  String get lessonStatusNotStarted;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu pour le moment.'**
  String get noContentYet;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pendant ces créneaux, Dirassty reste ouvert sur le téléphone de {name}, qui ne peut en sortir qu\'avec votre code.'**
  String focusIntro(Object name);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Actif pendant les créneaux ci-dessous'**
  String get focusStatusOn;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pour déverrouiller le téléphone'**
  String get parentCodeSub;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'(lendemain)'**
  String get nextDay;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Sur iPhone'**
  String get onIphone;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'L\'iPhone ne permet pas à une app de se verrouiller seule. Une fois, sur le téléphone de l\'enfant : Réglages → Accessibilité → Accès guidé → activez-le et choisissez un code. Pendant les créneaux, Dirassty lui demandera de triple-cliquer le bouton latéral.'**
  String get iphoneGuidedAccessSetup;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Enregistré — appliqué dès que l\'enfant ouvre l\'application.'**
  String get focusSavedParent;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Enregistré — actif sur ce téléphone.'**
  String get focusSavedDevice;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Définissez un code parent avant d\'activer.'**
  String get errFocusPinRequired;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins un créneau.'**
  String get errFocusNeedWindow;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Chaque créneau doit avoir au moins un jour et deux heures différentes.'**
  String get errFocusWindowInvalid;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne correspondent pas.'**
  String get errPinMismatch;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Code parent incorrect.'**
  String get errParentPinWrong;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Trop de codes incorrects — réessayez dans 15 minutes.'**
  String get errParentPinLocked;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Rien pour le moment.'**
  String get noFocusEvents;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'A quitté l\'application'**
  String get logLeftAppShort;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Réservé aux parents'**
  String get parentsOnly;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code parent à 4 chiffres.'**
  String get enterParentCodeBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Une connexion Internet est nécessaire pour modifier ces réglages.'**
  String get needsInternetSettings;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code'**
  String get newCode;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le code'**
  String get confirmCode;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Toutes les matières, vidéos, exercices et examens du programme scolaire.'**
  String get subscriptionIntro;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Sans engagement'**
  String get planNoCommitment;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{days} jours · −{pct} %'**
  String planDaysDiscount(Object days, Object pct);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{days} jours'**
  String planDays(Object days);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'actif jusqu\'au {date}'**
  String childActiveUntil(Object date);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'essai, {n} jours restants'**
  String childTrialDaysLeft(Object n);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'paiement en vérification'**
  String get childInReview;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'sans abonnement'**
  String get childNoPlan;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Voir mes abonnements'**
  String get seeMySubscriptions;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Payer manuellement'**
  String get payByContact;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Choisissez au moins un enfant.'**
  String get selectAtLeastOneChild;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucun forfait disponible pour le moment.'**
  String get noPlans;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Payer manuellement'**
  String get contactConfirmTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe vous contacte sur WhatsApp pour finaliser le paiement avec vous. Votre demande est enregistrée en attendant.'**
  String get contactConfirmBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, je souhaite m\'abonner au forfait {plan} ({amount} MRU) pour : {names}.'**
  String contactWhatsappMessage(Object amount, Object names, Object plan);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Il figure dans le SMS de confirmation Bankily.'**
  String get transactionCodeHint;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Nous vérifions le paiement puis activons l\'abonnement.'**
  String get bankilyVerifyNote;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un numéro de téléphone valide.'**
  String get errPhoneInvalid;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code de transaction reçu de Bankily.'**
  String get errTransactionCode;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Copié'**
  String get copied;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Paiement envoyé'**
  String get paymentSentTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Nous vérifions votre paiement Bankily. L\'accès sera activé dès validation.'**
  String get paymentSentBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Demande enregistrée'**
  String get contactSentTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Notre équipe finalise le paiement avec vous sur WhatsApp, puis active l\'abonnement.'**
  String get contactSentBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Paiement Bankily reçu le {date} · code {code}. Activation dès validation.'**
  String pendingDetails(Object code, Object date);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'En attente du paiement avec notre équipe.'**
  String get unpaidDetails;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get contactSupport;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get statusCancelled;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Non payé'**
  String get statusUnpaid;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Programmé'**
  String get statusScheduled;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get statusPaused;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Essai terminé'**
  String get statusTrialEnded;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Prochain forfait : {plan}, du {start} au {end}.'**
  String upcomingPlan(Object end, Object plan, Object start);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Terminé le {date}.'**
  String endedOn(Object date);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner'**
  String get subscribeAction;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement passé.'**
  String get noHistory;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Essai gratuit'**
  String get freeTrial;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 enfant} other{{n} enfants}} × {plan}'**
  String childrenTimesPlan(int n, Object plan);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Cette action est définitive'**
  String get deleteFinalTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'En supprimant ce compte, vous perdez définitivement :'**
  String get deleteLosesIntro;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'La progression dans tous les cours'**
  String get deleteLossProgress;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Les points XP, le niveau et la série'**
  String get deleteLossXp;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'L\'historique des exercices'**
  String get deleteLossHistory;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Cette action ne peut pas être annulée.'**
  String get deleteCannotUndo;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pour confirmer, écrivez {word} ci-dessous :'**
  String deleteTypeToConfirm(Object word);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get deleteForever;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'La suppression a échoué. Réessayez ou contactez le support.'**
  String get deleteFailed;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le téléchargement ?'**
  String get deleteDownloadTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'La vidéo restera disponible en ligne.'**
  String get deleteDownloadBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get videoLabel;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offlineShort;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get nowPlaying;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previousVideo;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get nextVideo;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Connecte-toi'**
  String get signInWho;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Vidéo {n} sur {total} · {min} min'**
  String videoOfMeta(Object min, Object n, Object total);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{min} min'**
  String videoMinutes(Object min);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Réduction famille (−{pct} % dès le 2e enfant)'**
  String familyDiscountLine(Object pct);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Offre famille : −{p2} % sur le 2e enfant, −{p3} % sur chaque enfant suivant dès 3 — appliquée automatiquement.'**
  String familyOfferBanner(Object p2, Object p3);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez {name} : économisez {amount} MRU'**
  String addChildForDiscount(Object amount, Object name);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addAction;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'−{amount} MRU'**
  String minusPriceMru(Object amount);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'{done} sur {total} examens faits'**
  String weekProgress(Object done, Object total);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Dès {day}'**
  String availableOn(Object day);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'À faire'**
  String get examToDo;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Bravo, tous les examens de la semaine sont faits !'**
  String get weekExamsDone;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pas encore d\'examen cette semaine.'**
  String get noExamsThisWeek;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Examens de la semaine'**
  String get examsOfTheWeek;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Je n\'arrive pas à bien lire ta photo'**
  String get photoUnreadableTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Reprends-la bien éclairée, à plat, avec toute la page dans le cadre et une écriture nette.'**
  String get photoUnreadableBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'floue'**
  String get issueBlurry;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'trop sombre'**
  String get issueDark;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'de travers'**
  String get issueRotated;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'coupée'**
  String get issueCropped;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'incomplète'**
  String get issueMissingParts;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'écriture illisible'**
  String get issueIllegible;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'ce n\'est pas l\'exercice'**
  String get issueNotExercise;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aide de Dirassty'**
  String get askDirassty;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Rafiq t\'aide'**
  String get tutorTitle;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Je ne te donne pas la réponse tout de suite : on va y arriver ensemble. Choisis une aide ou écris où tu bloques.'**
  String get tutorIntroExercise;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pose-moi une question sur la leçon, ou choisis une aide ci-dessous.'**
  String get tutorIntroLesson;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'💡 Un indice'**
  String get tutorHint;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Guide-moi'**
  String get tutorGuide;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Vérifier mon étape'**
  String get tutorCheckStep;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Explique cette étape'**
  String get tutorExplainStep;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Solution complète'**
  String get tutorSolution;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Explique simplement'**
  String get tutorExplain;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Étape par étape'**
  String get tutorStepByStep;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Un exemple'**
  String get tutorExample;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Un autre exemple'**
  String get tutorAnotherExample;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get tutorSummary;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Écris ton étape ou ta question…'**
  String get tutorInputHintExercise;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pose ta question sur la leçon…'**
  String get tutorInputHintLesson;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Écris d\'abord ton étape (ou la partie à expliquer) dans la case.'**
  String get tutorNeedsText;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Dirassty réfléchit…'**
  String get tutorThinking;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Réponse finale'**
  String get tutorFinalAnswer;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi :'**
  String get tutorWhy;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'À retenir'**
  String get tutorFormulas;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Étape juste ✓'**
  String get tutorStepCorrect;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Presque'**
  String get tutorStepPartial;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'À revoir'**
  String get tutorStepIncorrect;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Aide de Rafiq restante aujourd\'hui : {pct} %'**
  String aiBudgetLeft(Object pct);

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'📷 Vérifier ma copie'**
  String get checkWithPhoto;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Résous sur papier, puis prends ta copie en photo (jusqu\'à 3 pages).'**
  String get checkPhotoBody;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get chooseFromGallery;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Dirassty lit ta copie…'**
  String get checkingCopy;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Raisonnement'**
  String get resultReasoning;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Calculs'**
  String get resultCalculation;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Réponse finale'**
  String get resultFinalAnswer;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Autre méthode, elle aussi valable 👍'**
  String get alternativeMethod;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Ce que j\'ai lu sur ta copie'**
  String get whatIRead;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get verdictUndetermined;

  /// Added during implementation (not in the design handoff).
  ///
  /// In fr, this message translates to:
  /// **'Écrire ma réponse à la place'**
  String get writeAnswerInstead;

  /// Open-exercise correction result redesign.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu as bien fait'**
  String get correctionWellDone;

  /// Open-exercise correction result redesign.
  ///
  /// In fr, this message translates to:
  /// **'À corriger'**
  String get correctionToFix;

  /// Open-exercise correction result redesign.
  ///
  /// In fr, this message translates to:
  /// **'Voir la solution complète'**
  String get correctionSeeSolution;

  /// Open-exercise correction result redesign.
  ///
  /// In fr, this message translates to:
  /// **'Masquer la solution'**
  String get correctionHideSolution;

  /// Subscription lock screen: no trial wording (trials are disabled).
  ///
  /// In fr, this message translates to:
  /// **'Aucun abonnement actif'**
  String get noActiveSubscriptionTitle;

  /// Subscription lock screen: no trial wording (trials are disabled).
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier ton abonnement'**
  String get subscriptionCheckFailedTitle;

  /// Subscription lock screen: no trial wording (trials are disabled).
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion internet, puis appuie sur le bouton pour actualiser.'**
  String get subscriptionCheckFailedBody;

  /// App update prompt / required-update screen.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour nécessaire'**
  String get updateRequiredTitle;

  /// App update prompt / required-update screen.
  ///
  /// In fr, this message translates to:
  /// **'Une nouvelle version de Dirassty est disponible. Installe-la pour continuer à utiliser l\'application — tes progrès sont gardés.'**
  String get updateRequiredBody;

  /// App update prompt / required-update screen.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle version disponible'**
  String get updateAvailableTitle;

  /// App update prompt / required-update screen.
  ///
  /// In fr, this message translates to:
  /// **'Mets à jour Dirassty pour profiter des dernières améliorations.'**
  String get updateAvailableBody;

  /// App update prompt / required-update screen.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get updateNow;

  /// App update prompt / required-update screen.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get updateLater;

  /// App update prompt / required-update screen.
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés'**
  String get updateWhatsNew;

  /// App update prompt / required-update screen.
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get updateNoLink;

  /// App update prompt / required-update screen.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String updateVersionLabel(String version);

  /// Homework helper: heading of the revealed full written solution.
  ///
  /// In fr, this message translates to:
  /// **'Réponse complète'**
  String get fullAnswerLabel;

  /// Homework helper: heading above the drawn geometry figure.
  ///
  /// In fr, this message translates to:
  /// **'Figure'**
  String get figureLabel;

  /// Marketing promo / influencer code (tracking only).
  ///
  /// In fr, this message translates to:
  /// **'J\'ai un code promo'**
  String get promoHaveCode;

  /// Marketing promo / influencer code (tracking only).
  ///
  /// In fr, this message translates to:
  /// **'Code promo (facultatif)'**
  String get promoCodeOptional;

  /// Marketing promo / influencer code (tracking only).
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get promoApply;

  /// Marketing promo / influencer code (tracking only).
  ///
  /// In fr, this message translates to:
  /// **'Code de {name} enregistré ✓'**
  String promoApplied(String name);

  /// Marketing promo / influencer code (tracking only).
  ///
  /// In fr, this message translates to:
  /// **'Code inconnu — vérifiez l\'orthographe.'**
  String get promoUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
