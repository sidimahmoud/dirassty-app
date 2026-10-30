// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Dirassty';

  @override
  String get continueAction => 'Continuer';

  @override
  String get back => 'Retour';

  @override
  String get close => 'Fermer';

  @override
  String get retry => 'Réessayer';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get see => 'Voir';

  @override
  String get offlineBanner =>
      'Hors ligne · tes téléchargements restent disponibles';

  @override
  String get errorLoad =>
      'Chargement impossible. Vérifie ta connexion puis réessaie.';

  @override
  String get screenRecordingBlocked => 'Enregistrement d\'écran non autorisé';

  @override
  String get screenRecordingBody =>
      'Pour protéger le travail de nos professeurs, ce contenu ne peut pas être filmé.';

  @override
  String get tagline => 'Apprendre · Pratiquer · Réussir';

  @override
  String get welcomeTitle => 'Bienvenue sur Dirassty';

  @override
  String get welcomeBody =>
      'Du Primaire au Bac, apprends à ton rythme et réussis ton année.';

  @override
  String get whoAreYou => 'Qui es-tu ?';

  @override
  String get iAmStudent => 'Je suis élève';

  @override
  String get iAmStudentSub => 'Leçons, exercices et examens';

  @override
  String get iAmParent => 'Je suis parent';

  @override
  String get iAmParentSub => 'Suivre les progrès de mes enfants';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get trialLine =>
      'Programme scolaire mauritanien · Leçons, exercices et examens';

  @override
  String get studentLoginTitle => 'Connexion élève';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get pinCode => 'Code PIN';

  @override
  String get forgotPin => 'Code oublié ?';

  @override
  String get signIn => 'Se connecter';

  @override
  String get parentLoginTitle => 'Connexion parent';

  @override
  String get whatsappNumber => 'Numéro WhatsApp';

  @override
  String get newDeviceHint =>
      'Nouveau téléphone ? Nous vous enverrons un code de vérification par WhatsApp.';

  @override
  String get verifyTitle => 'Vérifiez votre numéro';

  @override
  String verifyBody(Object phone) {
    return 'Saisissez le code à 6 chiffres envoyé par WhatsApp au $phone.';
  }

  @override
  String resendIn(Object time) {
    return 'Renvoyer le code dans $time';
  }

  @override
  String get changeNumber => 'Modifier le numéro';

  @override
  String get verify => 'Vérifier';

  @override
  String get registerTitle => 'Créer un compte';

  @override
  String stepOf(Object n, Object total) {
    return 'Étape $n sur $total';
  }

  @override
  String get fullName => 'Prénom et nom';

  @override
  String get myGrade => 'Ma classe';

  @override
  String get noGradesOpen =>
      'Aucune classe n\'est ouverte aux inscriptions pour le moment.';

  @override
  String get errGradeClosed =>
      'Cette classe n\'est plus ouverte aux inscriptions. Choisis-en une autre.';

  @override
  String get aiDisclaimer =>
      'Rafiq est une intelligence artificielle : il peut se tromper.';

  @override
  String get reportAiAnswer => 'Signaler';

  @override
  String get reportAiTitle => 'Signaler une réponse de Rafiq';

  @override
  String get reportAiReasonWrong => 'La réponse est fausse';

  @override
  String get reportAiReasonInappropriate => 'Contenu inapproprié ou choquant';

  @override
  String get reportAiReasonOther => 'Autre problème';

  @override
  String get reportAiCommentHint => 'Explique en quelques mots (facultatif)';

  @override
  String get reportAiSend => 'Envoyer le signalement';

  @override
  String get reportAiThanks =>
      'Merci ! Notre équipe va vérifier cette réponse.';

  @override
  String get reportAiError => 'Envoi impossible. Réessaie plus tard.';

  @override
  String get parentGateTitle => 'Demande à un parent';

  @override
  String parentGateBody(int a, int b) {
    return 'Pour continuer, un parent doit répondre : combien font $a × $b ?';
  }

  @override
  String get parentGateWrong => 'Ce n\'est pas la bonne réponse.';

  @override
  String get parentGateConfirm => 'Valider';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get selfSignupFromC2 =>
      'Primaire et 1re année de collège : c\'est un parent qui crée le compte depuis son espace.';

  @override
  String get chooseRoleTitle => 'Qui crée le compte ?';

  @override
  String get chooseRoleBody =>
      'Choisis ton profil pour commencer. Tu pourras tout changer plus tard.';

  @override
  String get roleStudentDesc =>
      'J\'apprends avec mes leçons, mes exercices et Rafiq à mes côtés.';

  @override
  String get roleStudentBadge => 'Collège C2 → Lycée';

  @override
  String get roleStudentPoint1 => 'Cours et exercices du programme mauritanien';

  @override
  String get roleStudentPoint2 => 'Rafiq m\'aide pas à pas sur mes devoirs';

  @override
  String get roleParentDesc =>
      'Je crée les comptes de mes enfants et je suis leurs progrès.';

  @override
  String get roleParentBadge => 'Primaire → Lycée';

  @override
  String get roleParentPoint1 =>
      'Un compte pour chaque enfant, dès le primaire';

  @override
  String get roleParentPoint2 => 'Un résumé de leurs progrès chaque semaine';

  @override
  String get paymentProof => 'Capture d\'écran du paiement';

  @override
  String get addPaymentProof => 'Ajouter la capture d\'écran';

  @override
  String get paymentProofHint =>
      'La confirmation Bankily avec le montant et la date.';

  @override
  String get paymentProofAdded => 'Capture ajoutée';

  @override
  String get changePaymentProof => 'Changer';

  @override
  String get errPaymentProofRequired =>
      'Ajoutez la capture d\'écran du paiement.';

  @override
  String get bankilyNumberSoon =>
      'Le numéro Bankily sera bientôt affiché ici. En attendant, choisissez « Payer manuellement ».';

  @override
  String get lockedNoPlanTitle => 'Choisis ton offre';

  @override
  String get lockedNoPlanBody =>
      'Ton compte est prêt ! Choisis une offre pour débloquer toutes les leçons, les exercices et Rafiq.';

  @override
  String get lockedPendingTitle => 'Paiement en vérification';

  @override
  String get lockedPendingBody =>
      'Nous vérifions ton paiement. L\'accès s\'ouvre dès qu\'il est validé — touche « Actualiser » pour vérifier.';

  @override
  String get lockedManualTitle => 'Demande enregistrée';

  @override
  String get lockedManualBody =>
      'Notre équipe te contacte pour finaliser le paiement. L\'accès s\'ouvre dès qu\'il est validé.';

  @override
  String get chooseClassTitle => 'Tu es en quelle classe ?';

  @override
  String get chooseClassBody => 'On prépare ton programme selon ta classe.';

  @override
  String get havePromoCode => 'J\'ai un code promo';

  @override
  String get changeClass => 'Modifier';

  @override
  String get cyclePrimary => 'Primaire';

  @override
  String get cycleMiddle => 'Collège';

  @override
  String get cycleHigh => 'Lycée';

  @override
  String get available => '✓ Disponible';

  @override
  String get choosePin => 'Choisis un code PIN';

  @override
  String get acceptTerms => 'J\'accepte la politique de confidentialité';

  @override
  String get getWhatsappCode => 'Recevoir le code WhatsApp';

  @override
  String get trialTitle => '7 jours offerts';

  @override
  String get trialBody =>
      'Accès complet à tout le programme de ta classe, sans paiement.';

  @override
  String get startTrial => 'Commencer mon essai';

  @override
  String get claimBody =>
      'Ton parent t\'a créé un compte. Saisis le code d\'invitation qu\'il t\'a envoyé.';

  @override
  String hello(Object name) {
    return 'Bonjour $name';
  }

  @override
  String level(Object n) {
    return 'Niveau $n';
  }

  @override
  String xpToNext(Object xp, Object n) {
    return 'Encore $xp XP pour atteindre le niveau $n';
  }

  @override
  String get myWeek => 'Ma semaine';

  @override
  String get correctAnswers => 'Bonnes réponses';

  @override
  String get exercisesDone => 'Exercices faits';

  @override
  String get activeDays => 'Jours actifs';

  @override
  String get studyTime => 'Temps d\'étude';

  @override
  String get mySubjects => 'Mes matières';

  @override
  String lessonsCount(Object n) {
    return '$n leçons';
  }

  @override
  String get weeklyExam => 'Examen de la semaine';

  @override
  String get prepare => 'Me préparer';

  @override
  String get homeworkHelper => 'Rafiq – Aide aux devoirs';

  @override
  String get homeworkHelperSub =>
      'Prends ton exercice en photo, Rafiq te guide étape par étape.';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabSubjects => 'Matières';

  @override
  String get tabExams => 'Examens';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabSubscription => 'Abonnement';

  @override
  String get journeyVideo => 'Vidéo';

  @override
  String get journeyLesson => 'Leçon';

  @override
  String get journeyExercises => 'Exercices';

  @override
  String get statusMastered => 'Maîtrisée';

  @override
  String get statusViewed => 'Vue';

  @override
  String get statusNotStarted => 'Non commencée';

  @override
  String download(Object size) {
    return 'Télécharger · $size';
  }

  @override
  String get downloadWifiHint =>
      'Télécharge en Wi-Fi pour regarder sans connexion et économiser tes données.';

  @override
  String get inThisLesson => 'Dans cette leçon';

  @override
  String get continueToLesson => 'Continuer vers la leçon';

  @override
  String get realLife => 'Dans la vraie vie';

  @override
  String get checkUnderstanding => 'Vérifie ta compréhension';

  @override
  String get nextConcept => 'Notion suivante';

  @override
  String get answerToContinue => 'Réponds juste pour continuer';

  @override
  String get workedExample => 'Exemple résolu';

  @override
  String get commonMistake => 'Erreur fréquente';

  @override
  String get revisionSheet => 'Fiche de révision';

  @override
  String get formulas => 'Formules à retenir';

  @override
  String get definitions => 'Définitions';

  @override
  String get keyFacts => 'À savoir';

  @override
  String get goToExercises => 'Passer aux exercices';

  @override
  String questionOf(Object n, Object total) {
    return 'Question $n/$total';
  }

  @override
  String get check => 'Vérifier';

  @override
  String get correctFeedback => 'Bravo, c\'est juste !';

  @override
  String get wrongFeedback => 'Pas tout à fait';

  @override
  String xpGain(Object xp) {
    return '+$xp XP';
  }

  @override
  String streakDays(Object n) {
    return '$n jours de suite';
  }

  @override
  String get streakBody => 'Ta série continue. Reviens demain pour la garder.';

  @override
  String get score => 'Score';

  @override
  String get duration => 'Durée';

  @override
  String get xpEarned => 'XP gagnés';

  @override
  String reviewMistakes(Object n) {
    return 'Revoir mes $n erreurs';
  }

  @override
  String get backHome => 'Retour à l\'accueil';

  @override
  String get leaveSessionTitle => 'Quitter la session ?';

  @override
  String get yourAnswer => 'Ta réponse';

  @override
  String get aiCorrection => 'Correction de Rafiq';

  @override
  String get almost => 'Presque !';

  @override
  String get correctAnswer => 'Bonne réponse';

  @override
  String get similarExercise => 'Exercice similaire';

  @override
  String get watchMethod => 'Voir la méthode en vidéo';

  @override
  String get helperGuideNote =>
      'Dirassty te guide sans donner la réponse directement.';

  @override
  String get typeAnswer => 'Écris ta réponse…';

  @override
  String get exams => 'Examens';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get recentResults => 'Résultats récents';

  @override
  String get upcoming => 'À venir';

  @override
  String get startExam => 'Commencer l\'examen';

  @override
  String get finishExam => 'Terminer l\'examen';

  @override
  String get previous => 'Précédente';

  @override
  String get next => 'Suivante';

  @override
  String get byChapter => 'Par chapitre';

  @override
  String get myDownloads => 'Mes téléchargements';

  @override
  String get wifiOnly => 'Télécharger uniquement en Wi-Fi';

  @override
  String get offlineExpired => 'Accès hors ligne expiré';

  @override
  String get reconnect => 'Se reconnecter';

  @override
  String get noDownloads => 'Aucun téléchargement';

  @override
  String get language => 'Langue';

  @override
  String get parentalControl => 'Contrôle parental';

  @override
  String get faq => 'Questions fréquentes';

  @override
  String get whatsappSupport => 'Support WhatsApp';

  @override
  String get rateApp => 'Noter l\'application';

  @override
  String get shareApp => 'Partager Dirassty';

  @override
  String get about => 'À propos';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get deleteAccount => 'Supprimer mon compte';

  @override
  String get subscriptionActive => 'Abonnement actif';

  @override
  String get trialEnded => 'Ton essai est terminé';

  @override
  String get trialEndedBody =>
      'Demande à ton parent de choisir une offre pour continuer tes leçons et tes exercices.';

  @override
  String get notifyParent => 'Prévenir mon parent sur WhatsApp';

  @override
  String get alreadyPaid => 'Déjà payé ? Actualiser';

  @override
  String focusUntil(Object time) {
    return 'Mode concentration jusqu\'à $time';
  }

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get parentCode => 'Code parent';

  @override
  String get guidedAccessHint =>
      'Sur iPhone : active l\'Accès guidé (triple clic sur le bouton latéral) pour rester dans Dirassty.';

  @override
  String get focusBlockedTitle => 'Pas tout de suite !';

  @override
  String focusBlockedBody(Object time) {
    return 'Le mode concentration est actif jusqu\'à $time. Tu pourras te déconnecter après, ou avec le code de ton parent.';
  }

  @override
  String get keepStudying => 'Continuer à étudier';

  @override
  String get parentSpace => 'Espace parent';

  @override
  String get myChildren => 'Mes enfants';

  @override
  String get addChild => 'Ajouter un enfant';

  @override
  String subscribeFor(Object name) {
    return 'S\'abonner pour $name';
  }

  @override
  String get subscribed => 'Abonnée';

  @override
  String trialDaysLeft(Object n) {
    return 'Essai · $n j';
  }

  @override
  String get childFirstName => 'Prénom de l\'enfant';

  @override
  String get createChildAccount => 'Créer le compte';

  @override
  String childReady(Object name) {
    return 'Le compte de $name est prêt';
  }

  @override
  String get shareWhatsapp => 'Partager par WhatsApp';

  @override
  String get copyCredentials => 'Copier les identifiants';

  @override
  String daysUntilExam(Object n, Object exam) {
    return '$n jours avant le $exam';
  }

  @override
  String get examConcours => 'Concours';

  @override
  String get examBrevet => 'Brevet';

  @override
  String get examBac => 'Bac';

  @override
  String get weeklyInsight => 'Analyse de la semaine';

  @override
  String get masteryBySubject => 'Maîtrise par matière';

  @override
  String get examHistory => 'Historique des examens';

  @override
  String get lessonDetail => 'Détail leçon par leçon';

  @override
  String get focusMode => 'Mode concentration';

  @override
  String get enableFocus => 'Activer le mode concentration';

  @override
  String timeWindow(Object n) {
    return 'Créneau $n';
  }

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get addWindow => 'Ajouter un créneau';

  @override
  String get focusLog => 'Journal';

  @override
  String logLeftApp(Object min) {
    return 'A quitté l\'application $min min';
  }

  @override
  String get logUnlocked => 'Déverrouillé avec votre code';

  @override
  String get subscription => 'Abonnement';

  @override
  String get planMonthly => 'Mensuel';

  @override
  String get planQuarterly => 'Trimestriel';

  @override
  String get planYearly => 'Annuel';

  @override
  String get popular => 'Populaire';

  @override
  String get forWhichChildren => 'Pour quels enfants ?';

  @override
  String get familyDiscount => 'Réduction famille';

  @override
  String get total => 'Total';

  @override
  String priceMru(Object amount) {
    return '$amount MRU';
  }

  @override
  String get payWithBankily => 'Payer avec Bankily';

  @override
  String get choosePaymentMethod => 'Choisissez votre moyen de paiement';

  @override
  String payWithMethod(Object method) {
    return 'Payer avec $method';
  }

  @override
  String paymentMethodTitle(Object method) {
    return 'Paiement $method';
  }

  @override
  String methodNumber(Object method) {
    return 'Numéro $method de Dirassty';
  }

  @override
  String methodStep1(Object method) {
    return 'Ouvrez $method et envoyez le montant au numéro ci-dessus.';
  }

  @override
  String get methodPhone => 'Numéro utilisé pour payer';

  @override
  String get paymentProofHintGeneric =>
      'La confirmation du paiement avec le montant et la date.';

  @override
  String paymentSentBodyMethod(Object method) {
    return 'Nous vérifions votre paiement $method. L\'accès sera activé dès validation.';
  }

  @override
  String get bankilyTitle => 'Paiement Bankily';

  @override
  String get amountToSend => 'Montant à envoyer';

  @override
  String get merchantNumber => 'Numéro Bankily Dirassty';

  @override
  String get bankilyStep1 =>
      'Ouvrez Bankily et envoyez le montant au numéro Bankily Dirassty ci-dessus.';

  @override
  String get bankilyStep2 =>
      'Faites une capture d\'écran de la confirmation du paiement.';

  @override
  String get bankilyStep3 =>
      'Ajoutez-la ci-dessous avec votre numéro, puis confirmez.';

  @override
  String get bankilyPhone => 'Numéro Bankily utilisé';

  @override
  String get transactionCode => 'Code de transaction';

  @override
  String get confirmPayment => 'Confirmer le paiement';

  @override
  String get mySubscriptions => 'Mes abonnements';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusPending => 'En vérification';

  @override
  String get statusExpired => 'Expiré';

  @override
  String get statusRefused => 'Paiement refusé';

  @override
  String get renew => 'Renouveler';

  @override
  String get history => 'Historique';

  @override
  String get statusDownloaded => 'Disponible hors ligne';

  @override
  String get downloadNoSize => 'Télécharger';

  @override
  String get downloadFailed =>
      'Échec du téléchargement — vérifie ta connexion et réessaie.';

  @override
  String get backspace => 'Effacer';

  @override
  String get studentLoginBody => 'Utilise l\'identifiant donné par ton parent.';

  @override
  String get parentLoginBody =>
      'Entrez votre numéro WhatsApp et votre code PIN.';

  @override
  String get noAccountYet => 'Pas encore de compte ?';

  @override
  String get forgotPinStudentTitle => 'Code oublié ?';

  @override
  String get forgotPinStudentBody =>
      'Demande à ton parent : il peut voir ou changer ton code PIN depuis son espace parent.';

  @override
  String get forgotPinParentBody =>
      'Contactez notre support WhatsApp pour réinitialiser votre code PIN.';

  @override
  String get ok => 'D\'accord';

  @override
  String get wrongStudentCredentials =>
      'Nom d\'utilisateur ou code PIN incorrect.';

  @override
  String get wrongParentCredentials => 'Numéro ou code PIN incorrect.';

  @override
  String pinLocked(Object min) {
    return 'Trop d\'essais. Réessaie dans $min min.';
  }

  @override
  String get askParentForPin => 'Code oublié ? Demande à ton parent';

  @override
  String get registerBody =>
      'Quelques informations pour préparer ton programme.';

  @override
  String get registerParentBody =>
      'Quelques informations pour créer votre espace parent.';

  @override
  String get phoneHintVerify => 'Pour recevoir ton code de vérification';

  @override
  String get phoneHintOptional =>
      'Facultatif · pour vérifier ton compte et suivre tes progrès';

  @override
  String get pinHint =>
      '4 chiffres, faciles à retenir pour toi mais pas pour les autres.';

  @override
  String get enterPin => 'Saisis ton code PIN';

  @override
  String get validate => 'Valider';

  @override
  String get createMyAccount => 'Créer mon compte';

  @override
  String get errNameRequired => 'Saisis ton prénom et ton nom.';

  @override
  String get errUsernameFormat =>
      '3 à 20 lettres ou chiffres latins, sans espace.';

  @override
  String get errPhoneRequired => 'Saisis ton numéro WhatsApp.';

  @override
  String get errPinFormat => 'Le code PIN doit contenir 4 chiffres.';

  @override
  String get errTermsRequired =>
      'Accepte la politique de confidentialité pour continuer.';

  @override
  String get errAccountExists =>
      'Un compte existe déjà avec ce numéro — connecte-toi plutôt.';

  @override
  String get errUsernameTaken =>
      'Ce nom d\'utilisateur est déjà pris — essaie-en un autre.';

  @override
  String get errTooSoon => 'Attends un instant avant de redemander un code.';

  @override
  String get errCodeExpired => 'Code expiré — redemande un nouveau code.';

  @override
  String get errIncorrectCode => 'Code incorrect.';

  @override
  String get errTooManyAttempts =>
      'Trop de tentatives — redemande un nouveau code.';

  @override
  String get errNoPendingCode =>
      'Aucun code en attente — redemande un nouveau code.';

  @override
  String get errGeneric =>
      'Une erreur est survenue. Vérifie ta connexion puis réessaie.';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get pasteCode => 'Coller le code';

  @override
  String get pasteCodeHint => 'Appui long pour coller le code';

  @override
  String get accountCreated => 'Compte créé';

  @override
  String trialTitleDays(Object n) {
    return '$n jours offerts';
  }

  @override
  String trialBodyGrade(Object grade) {
    return 'Accès complet à tout le programme de $grade, sans paiement.';
  }

  @override
  String get trialFeatureLessons => 'Toutes les leçons et vidéos';

  @override
  String get trialFeatureQcm => 'QCM et exercices corrigés par Rafiq (IA)';

  @override
  String get trialFeatureExams => 'Examens hebdomadaires';

  @override
  String get trialFeatureHelper => 'Aide aux devoirs par photo avec Rafiq';

  @override
  String trialFooterPrice(Object price) {
    return 'Ensuite à partir de $price MRU par mois. Aucun prélèvement automatique : un parent choisit l\'offre et paie via Bankily.';
  }

  @override
  String get trialFooterNoPrice =>
      'Aucun prélèvement automatique : un parent choisit l\'offre et paie via Bankily.';

  @override
  String get accountReadyTitle => 'Ton compte est prêt';

  @override
  String accountReadyBody(Object grade) {
    return 'Choisis une offre pour accéder à tout le programme de $grade.';
  }

  @override
  String get choosePlan => 'Choisir une offre';

  @override
  String get later => 'Plus tard';

  @override
  String xpOfTotal(Object xp, Object total) {
    return '$xp / $total XP';
  }

  @override
  String inDays(Object n) {
    return 'Dans $n jours';
  }

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get tomorrow => 'Demain';

  @override
  String get availableNow => 'Disponible';

  @override
  String questionsCount(Object n) {
    return '$n questions';
  }

  @override
  String hoursMinutes(Object h, Object m) {
    return '$h h $m';
  }

  @override
  String minutesShort(Object m) {
    return '$m min';
  }

  @override
  String get noSubjects =>
      'Aucune matière disponible pour ta classe pour le moment.';

  @override
  String get noExamThisWeek => 'Pas d\'examen cette semaine';

  @override
  String get noExamThisWeekBody =>
      'Le prochain examen apparaîtra ici dès qu\'il sera disponible.';

  @override
  String get profileLoadError => 'Impossible de charger ton profil.';

  @override
  String chaptersCount(Object n) {
    return '$n chapitres';
  }

  @override
  String masteredLessonsCount(Object n) {
    return '$n leçons maîtrisées';
  }

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterToReview => 'À revoir';

  @override
  String get filterOffline => 'Hors ligne';

  @override
  String chapterMeta(Object n, Object m) {
    return '$n leçons · $m maîtrisées';
  }

  @override
  String get comingSoon => 'Contenu à venir';

  @override
  String get comingSoonBody => 'Les leçons de cette matière arrivent bientôt.';

  @override
  String get noLessonsToReview => 'Rien à revoir pour l\'instant';

  @override
  String get noLessonsToReviewBody =>
      'Les leçons vues mais pas encore maîtrisées apparaîtront ici.';

  @override
  String get noOfflineLessons => 'Aucune leçon hors ligne';

  @override
  String get noOfflineLessonsBody =>
      'Télécharge la vidéo d\'une leçon pour la retrouver ici sans connexion.';

  @override
  String get subjectLoadError => 'Impossible de charger cette matière.';

  @override
  String get mySubjectsTitle => 'Mes matières';

  @override
  String lessonLabel(Object chapter, Object n) {
    return '$chapter · Leçon $n';
  }

  @override
  String conceptOf(Object n, Object total) {
    return 'Notion $n sur $total';
  }

  @override
  String get correctUnlocked => '✓ Juste ! La notion suivante est débloquée.';

  @override
  String get wrongTryAgain => 'Pas tout à fait — relis la notion et réessaie.';

  @override
  String get revealedAnswer => 'Voici la bonne réponse :';

  @override
  String get finishExamplesFirst =>
      'Termine les exemples pour débloquer la question.';

  @override
  String get nextExample => 'Exemple suivant';

  @override
  String exampleOf(Object n, Object total) {
    return 'Exemple $n sur $total';
  }

  @override
  String get statement => 'Énoncé';

  @override
  String get showSolution => 'Afficher la solution étape par étape';

  @override
  String get reviewVideo => 'Revoir la vidéo';

  @override
  String get lessonComingSoon => 'Le contenu de cette leçon arrive bientôt.';

  @override
  String get lessonNotFound => 'Leçon introuvable.';

  @override
  String get lessonLoadError => 'Impossible de charger cette leçon.';

  @override
  String get alreadyReadTitle => 'Tu as déjà lu cette leçon';

  @override
  String get alreadyReadBody => 'Que veux-tu faire maintenant ?';

  @override
  String get redoLesson => 'Revoir le cours';

  @override
  String get redoLessonSub => 'La vidéo et l\'explication depuis le début';

  @override
  String get qcmTitle => 'QCM';

  @override
  String get qcmSub => 'Questions à choix multiples, correction immédiate';

  @override
  String get guidedExercises => 'Exercices guidés';

  @override
  String get guidedExercisesSub => 'Exercices ouverts corrigés par Rafiq (IA)';

  @override
  String get alreadyDone => 'Déjà fait';

  @override
  String get startQcm => 'Commencer le QCM';

  @override
  String get finishLesson => 'Terminer la leçon';

  @override
  String questionTopic(Object lesson, Object n) {
    return '$lesson · Question $n';
  }

  @override
  String get leaveSessionBody =>
      'Tes réponses de ce QCM ne seront pas enregistrées.';

  @override
  String get leave => 'Quitter';

  @override
  String get stayInSession => 'Continuer le QCM';

  @override
  String get seeResults => 'Voir mes résultats';

  @override
  String get hint => 'Indice';

  @override
  String get lessonValidated => 'Leçon validée';

  @override
  String notMasteredYet(Object pct) {
    return 'Pas encore maîtrisée ($pct %) — refais le QCM pour progresser.';
  }

  @override
  String get retryQcm => 'Recommencer le QCM';

  @override
  String get noQcmTitle => 'Pas encore de QCM';

  @override
  String get noQcmBody => 'Les questions de cette leçon arrivent bientôt.';

  @override
  String get backToLesson => 'Retour à la leçon';

  @override
  String get qcmLoadError => 'Impossible de charger les questions.';

  @override
  String get mistakesTitle => 'Tes erreurs';

  @override
  String yourAnswerWas(Object a) {
    return 'Ta réponse : $a';
  }

  @override
  String correctAnswerWas(Object a) {
    return 'Bonne réponse : $a';
  }

  @override
  String qcmScoreTitle(Object lesson) {
    return '$lesson · QCM';
  }

  @override
  String openExerciseLabel(Object lesson) {
    return 'Exercice ouvert · $lesson';
  }

  @override
  String exerciseN(Object n) {
    return 'Exercice $n';
  }

  @override
  String attemptN(Object n) {
    return 'Essai $n';
  }

  @override
  String get submitAnswer => 'Soumettre ma réponse';

  @override
  String get usefulSymbols => 'Symboles utiles';

  @override
  String get seeCorrection => 'Voir la correction';

  @override
  String get hintBeforeCorrection =>
      'Relis l\'indice, puis demande la correction — ou corrige d\'abord ta réponse.';

  @override
  String get correcting => 'Correction en cours…';

  @override
  String get generatingExercise => 'Création d\'un exercice similaire…';

  @override
  String get verdictCorrect => 'Juste !';

  @override
  String get verdictReview => 'À revoir';

  @override
  String get reviseAnswer => 'Corriger ma réponse';

  @override
  String get nextExercise => 'Exercice suivant';

  @override
  String get noExercisesTitle => 'Pas encore d\'exercices';

  @override
  String get noExercisesBody =>
      'Les exercices de cette leçon arrivent bientôt.';

  @override
  String get exercisesLoadError => 'Impossible de charger les exercices.';

  @override
  String get methodVideos => 'La méthode en vidéo';

  @override
  String get photoPrompt => 'Prends ton exercice en photo';

  @override
  String get photoPromptBody => 'Cadre bien l\'énoncé, avec une bonne lumière.';

  @override
  String get camera => 'Caméra';

  @override
  String get gallery => 'Galerie';

  @override
  String get analyze => 'Analyser';

  @override
  String get analyzingPhoto => 'Dirassty lit ton exercice…';

  @override
  String detectedSubject(Object subject) {
    return '$subject · détecté';
  }

  @override
  String get readProblem => 'Voici ce que j\'ai lu :';

  @override
  String get letsSolveTogether => 'On le résout ensemble, étape par étape.';

  @override
  String get nextStep => 'Étape suivante';

  @override
  String get showAnswer => 'Voir la réponse';

  @override
  String get answerLabel => 'Réponse';

  @override
  String get keyConceptsLabel => 'Notions clés';

  @override
  String get newPhoto => 'Nouvelle photo';

  @override
  String get retakePhoto => 'Reprendre la photo';

  @override
  String get examsBody => 'Un examen par semaine et par matière principale.';

  @override
  String get seeExam => 'Voir l\'examen';

  @override
  String get filterPast => 'Passés';

  @override
  String get weeklyExamBadge => 'Examen hebdomadaire';

  @override
  String get dueBy => 'À rendre';

  @override
  String get questionsLabel => 'Questions';

  @override
  String get xpMax => 'XP max';

  @override
  String get beforeStart => 'Avant de commencer';

  @override
  String get examRuleTimer =>
      'Le chronomètre démarre dès que tu appuies sur Commencer.';

  @override
  String get examRuleSkip =>
      'Tu peux passer une question et y revenir avant la fin.';

  @override
  String get examRuleCalm =>
      'Installe-toi au calme : l\'examen ne peut pas être mis en pause.';

  @override
  String get examRuleSaved =>
      'Chaque réponse est enregistrée dès que tu la choisis.';

  @override
  String skippedHint(Object n) {
    return 'Question $n passée · tu pourras y revenir';
  }

  @override
  String get finishExamTitle => 'Terminer l\'examen ?';

  @override
  String finishExamUnanswered(Object n) {
    return '$n questions sans réponse compteront comme fausses.';
  }

  @override
  String get finishExamAll => 'Tu as répondu à toutes les questions.';

  @override
  String get finishNow => 'Terminer maintenant';

  @override
  String get keepGoing => 'Continuer l\'examen';

  @override
  String resultsGreat(Object name) {
    return 'Très bon travail, $name';
  }

  @override
  String resultsGood(Object name) {
    return 'Bon travail, $name';
  }

  @override
  String resultsKeepGoing(Object name) {
    return 'Continue tes efforts, $name';
  }

  @override
  String get byLesson => 'Par leçon';

  @override
  String get yourAnswers => 'Tes réponses';

  @override
  String get done => 'Terminé';

  @override
  String get missed => 'Manqué';

  @override
  String get noExams => 'Aucun examen pour le moment';

  @override
  String get noExamsBody => 'Tes examens de la semaine apparaîtront ici.';

  @override
  String get noPastExams => 'Aucun examen passé';

  @override
  String get examsLoadError => 'Impossible de charger tes examens.';

  @override
  String get examLoadError => 'Impossible de charger cet examen.';

  @override
  String get submitError =>
      'L\'envoi a échoué. Vérifie ta connexion puis réessaie.';

  @override
  String get seeResultsExam => 'Voir le résultat';

  @override
  String storageUsed(Object size) {
    return '$size utilisés';
  }

  @override
  String get offlineExpiredBody =>
      'Connecte-toi à Internet pour réactiver tes vidéos.';

  @override
  String get downloadsFooter =>
      'Les vidéos téléchargées restent disponibles hors ligne jusqu\'à la fin de ton abonnement.';

  @override
  String get noDownloadsBody =>
      'Ouvre une leçon et touche « Télécharger » sur la vidéo pour la regarder sans connexion.';

  @override
  String get deleteAll => 'Tout supprimer';

  @override
  String get deleteAllDownloadsConfirm =>
      'Supprimer tous les téléchargements ?';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get myVideos => 'Mes vidéos';

  @override
  String videosCountSize(Object n, Object size) {
    return '$n vidéos · $size';
  }

  @override
  String get statusTrial => 'Essai';

  @override
  String get statusEnded => 'Terminé';

  @override
  String accessUntil(Object date) {
    return 'Accès complet jusqu\'au $date.';
  }

  @override
  String trialUntil(Object date) {
    return 'Essai gratuit jusqu\'au $date.';
  }

  @override
  String get pendingBody => 'Ton paiement est en cours de vérification.';

  @override
  String get noSubscription => 'Aucun abonnement';

  @override
  String get noSubscriptionBody =>
      'Choisis une offre pour accéder à tout le programme.';

  @override
  String get protectedByParent => 'Protégé par le code parent';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageArabic => 'العربية';

  @override
  String get subscriptionEndedTitle => 'Ton abonnement est terminé';

  @override
  String get nothingLost => 'Rien n\'est perdu';

  @override
  String nothingLostBody(Object streak, Object xp) {
    return 'Ta série de $streak jours, tes $xp XP et tous tes progrès sont sauvegardés.';
  }

  @override
  String get subscribeMyself => 'Choisir une offre moi-même';

  @override
  String get parentWhatsappMessage =>
      'Bonjour, mon accès à Dirassty est terminé. Peux-tu choisir une offre pour que je continue mes leçons ?';

  @override
  String get parentCodeBody =>
      'Demande à ton parent de saisir son code à 4 chiffres pour quitter le mode concentration.';

  @override
  String get enterParentCode => 'Saisir le code parent';

  @override
  String parentWeekTotal(Object time) {
    return 'Cette semaine, vos enfants ont étudié $time au total.';
  }

  @override
  String get parentWeekNone =>
      'Pas encore d\'étude cette semaine — un petit encouragement ?';

  @override
  String streakDaysShort(Object n) {
    return '$n jours';
  }

  @override
  String get noStreak => 'Pas de série';

  @override
  String timeThisWeek(Object time) {
    return '· $time cette semaine';
  }

  @override
  String get noChildrenTitle => 'Ajoutez votre premier enfant';

  @override
  String get noChildrenBody =>
      'Créez son compte en une minute : il se connectera avec son nom d\'utilisateur et son code PIN.';

  @override
  String get childrenLoadError => 'Impossible de charger vos enfants.';

  @override
  String get activityLast7Days => 'Activité sur 7 jours';

  @override
  String get childClass => 'Classe';

  @override
  String gradeExamNote(Object exam, Object grade) {
    return '$grade se termine par le $exam.';
  }

  @override
  String get childPinLabel => 'Code PIN de l\'enfant';

  @override
  String get childPinHint =>
      'Il l\'utilisera pour se connecter sur son téléphone.';

  @override
  String get errChildNameRequired => 'Saisissez le prénom de l\'enfant.';

  @override
  String get addChildError => 'Impossible d\'ajouter cet enfant — réessayez.';

  @override
  String get giveCredentials =>
      'Donnez-lui ces identifiants pour qu\'il se connecte.';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get credentialsCopied => 'Identifiants copiés';

  @override
  String credentialsShareMessage(Object pin, Object username) {
    return 'Ton compte Dirassty est prêt !\nNom d\'utilisateur : $username\nCode PIN : $pin';
  }

  @override
  String get daysUnit => 'jours';

  @override
  String beforeExam(Object exam) {
    return 'avant le $exam';
  }

  @override
  String get currentStreak => 'Série en cours';

  @override
  String daysShortN(Object n) {
    return '$n j';
  }

  @override
  String get focusOn => 'Activé';

  @override
  String get focusOff => 'Désactivé';

  @override
  String get loginCredentials => 'Identifiants de connexion';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Enregistrer';

  @override
  String get setLogin => 'Définir';

  @override
  String get insightLoading => 'Rafiq prépare l\'analyse de la semaine…';

  @override
  String get insightUnavailable =>
      'Analyse indisponible pour l\'instant — réessayez plus tard.';

  @override
  String get insightGenerated => 'Généré par Rafiq (IA)';

  @override
  String get childNotFound => 'Enfant introuvable.';

  @override
  String get noSubjectsForChild =>
      'Aucune matière disponible pour cette classe pour le moment.';

  @override
  String get chooseSubject => 'Choisir une matière';

  @override
  String get editCredentials => 'Modifier les identifiants';

  @override
  String get newPinOptional => 'Nouveau code PIN';

  @override
  String get newPinOptionalHint => 'Laissez vide pour garder le code actuel.';

  @override
  String get errPinRequiredNewLogin =>
      'Choisissez un code PIN à 4 chiffres pour ce compte.';

  @override
  String credentialsUpdated(Object username) {
    return 'Identifiants mis à jour : $username';
  }

  @override
  String weekOf(Object date) {
    return 'Semaine du $date';
  }

  @override
  String get noExamsForChild => 'Pas encore d\'examen pour cet enfant.';

  @override
  String lessonsInSubject(Object n) {
    return '$n leçons dans cette matière';
  }

  @override
  String get lessonsCompleted => 'Leçons terminées';

  @override
  String get withExercisesDone => 'Avec exercices faits';

  @override
  String chapterTitle(Object n, Object title) {
    return 'Chapitre $n · $title';
  }

  @override
  String lessonStatusExercised(Object n, Object pct) {
    return 'Exercices faits · $pct % · tentatives : $n';
  }

  @override
  String get lessonStatusViewed => 'Leçon terminée · pas encore d\'exercices';

  @override
  String get lessonStatusNotStarted => 'Pas encore commencée';

  @override
  String get noContentYet => 'Aucun contenu pour le moment.';

  @override
  String focusIntro(Object name) {
    return 'Pendant ces créneaux, Dirassty reste ouvert sur le téléphone de $name, qui ne peut en sortir qu\'avec votre code.';
  }

  @override
  String get focusStatusOn => 'Actif pendant les créneaux ci-dessous';

  @override
  String get parentCodeSub => 'Pour déverrouiller le téléphone';

  @override
  String get nextDay => '(lendemain)';

  @override
  String get onIphone => 'Sur iPhone';

  @override
  String get iphoneGuidedAccessSetup =>
      'L\'iPhone ne permet pas à une app de se verrouiller seule. Une fois, sur le téléphone de l\'enfant : Réglages → Accessibilité → Accès guidé → activez-le et choisissez un code. Pendant les créneaux, Dirassty lui demandera de triple-cliquer le bouton latéral.';

  @override
  String get focusSavedParent =>
      'Enregistré — appliqué dès que l\'enfant ouvre l\'application.';

  @override
  String get focusSavedDevice => 'Enregistré — actif sur ce téléphone.';

  @override
  String get errFocusPinRequired =>
      'Définissez un code parent avant d\'activer.';

  @override
  String get errFocusNeedWindow => 'Ajoutez au moins un créneau.';

  @override
  String get errFocusWindowInvalid =>
      'Chaque créneau doit avoir au moins un jour et deux heures différentes.';

  @override
  String get errPinMismatch => 'Les deux codes ne correspondent pas.';

  @override
  String get errParentPinWrong => 'Code parent incorrect.';

  @override
  String get errParentPinLocked =>
      'Trop de codes incorrects — réessayez dans 15 minutes.';

  @override
  String get noFocusEvents => 'Rien pour le moment.';

  @override
  String get logLeftAppShort => 'A quitté l\'application';

  @override
  String get parentsOnly => 'Réservé aux parents';

  @override
  String get enterParentCodeBody => 'Saisissez le code parent à 4 chiffres.';

  @override
  String get needsInternetSettings =>
      'Une connexion Internet est nécessaire pour modifier ces réglages.';

  @override
  String get newCode => 'Nouveau code';

  @override
  String get confirmCode => 'Confirmer le code';

  @override
  String get subscriptionIntro =>
      'Toutes les matières, vidéos, exercices et examens du programme scolaire.';

  @override
  String get planNoCommitment => 'Sans engagement';

  @override
  String planDaysDiscount(Object days, Object pct) {
    return '$days jours · −$pct %';
  }

  @override
  String planDays(Object days) {
    return '$days jours';
  }

  @override
  String childActiveUntil(Object date) {
    return 'actif jusqu\'au $date';
  }

  @override
  String childTrialDaysLeft(Object n) {
    return 'essai, $n jours restants';
  }

  @override
  String get childInReview => 'paiement en vérification';

  @override
  String get childNoPlan => 'sans abonnement';

  @override
  String get seeMySubscriptions => 'Voir mes abonnements';

  @override
  String get payByContact => 'Payer manuellement';

  @override
  String get selectAtLeastOneChild => 'Choisissez au moins un enfant.';

  @override
  String get noPlans => 'Aucun forfait disponible pour le moment.';

  @override
  String get contactConfirmTitle => 'Payer manuellement';

  @override
  String get contactConfirmBody =>
      'Notre équipe vous contacte sur WhatsApp pour finaliser le paiement avec vous. Votre demande est enregistrée en attendant.';

  @override
  String contactWhatsappMessage(Object amount, Object names, Object plan) {
    return 'Bonjour, je souhaite m\'abonner au forfait $plan ($amount MRU) pour : $names.';
  }

  @override
  String get transactionCodeHint =>
      'Il figure dans le SMS de confirmation Bankily.';

  @override
  String get bankilyVerifyNote =>
      'Nous vérifions le paiement puis activons l\'abonnement.';

  @override
  String get errPhoneInvalid => 'Saisissez un numéro de téléphone valide.';

  @override
  String get errTransactionCode =>
      'Saisissez le code de transaction reçu de Bankily.';

  @override
  String get copied => 'Copié';

  @override
  String get paymentSentTitle => 'Paiement envoyé';

  @override
  String get paymentSentBody =>
      'Nous vérifions votre paiement Bankily. L\'accès sera activé dès validation.';

  @override
  String get contactSentTitle => 'Demande enregistrée';

  @override
  String get contactSentBody =>
      'Notre équipe finalise le paiement avec vous sur WhatsApp, puis active l\'abonnement.';

  @override
  String pendingDetails(Object code, Object date) {
    return 'Paiement Bankily reçu le $date · code $code. Activation dès validation.';
  }

  @override
  String get unpaidDetails => 'En attente du paiement avec notre équipe.';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get statusCancelled => 'Annulé';

  @override
  String get statusUnpaid => 'Non payé';

  @override
  String get statusScheduled => 'Programmé';

  @override
  String get statusPaused => 'En pause';

  @override
  String get statusTrialEnded => 'Essai terminé';

  @override
  String upcomingPlan(Object end, Object plan, Object start) {
    return 'Prochain forfait : $plan, du $start au $end.';
  }

  @override
  String endedOn(Object date) {
    return 'Terminé le $date.';
  }

  @override
  String get subscribeAction => 'S\'abonner';

  @override
  String get noHistory => 'Aucun abonnement passé.';

  @override
  String get freeTrial => 'Essai gratuit';

  @override
  String childrenTimesPlan(int n, Object plan) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n enfants',
      one: '1 enfant',
    );
    return '$_temp0 × $plan';
  }

  @override
  String get deleteFinalTitle => 'Cette action est définitive';

  @override
  String get deleteLosesIntro =>
      'En supprimant ce compte, vous perdez définitivement :';

  @override
  String get deleteLossProgress => 'La progression dans tous les cours';

  @override
  String get deleteLossXp => 'Les points XP, le niveau et la série';

  @override
  String get deleteLossHistory => 'L\'historique des exercices';

  @override
  String get deleteCannotUndo => 'Cette action ne peut pas être annulée.';

  @override
  String deleteTypeToConfirm(Object word) {
    return 'Pour confirmer, écrivez $word ci-dessous :';
  }

  @override
  String get deleteForever => 'Supprimer définitivement';

  @override
  String get deleteFailed =>
      'La suppression a échoué. Réessayez ou contactez le support.';

  @override
  String get deleteDownloadTitle => 'Supprimer le téléchargement ?';

  @override
  String get deleteDownloadBody => 'La vidéo restera disponible en ligne.';

  @override
  String get videoLabel => 'Vidéo';

  @override
  String get offlineShort => 'Hors ligne';

  @override
  String get nowPlaying => 'En cours';

  @override
  String get previousVideo => 'Précédent';

  @override
  String get nextVideo => 'Suivant';

  @override
  String get signInWho => 'Déjà un compte ? Connecte-toi';

  @override
  String videoOfMeta(Object min, Object n, Object total) {
    return 'Vidéo $n sur $total · $min min';
  }

  @override
  String videoMinutes(Object min) {
    return '$min min';
  }

  @override
  String familyDiscountLine(Object pct) {
    return 'Réduction famille (−$pct % dès le 2e enfant)';
  }

  @override
  String familyOfferBanner(Object p2, Object p3) {
    return 'Offre famille : −$p2 % sur le 2e enfant, −$p3 % sur chaque enfant suivant dès 3 — appliquée automatiquement.';
  }

  @override
  String addChildForDiscount(Object amount, Object name) {
    return 'Ajoutez $name : économisez $amount MRU';
  }

  @override
  String get addAction => 'Ajouter';

  @override
  String minusPriceMru(Object amount) {
    return '−$amount MRU';
  }

  @override
  String weekProgress(Object done, Object total) {
    return '$done sur $total examens faits';
  }

  @override
  String availableOn(Object day) {
    return 'Dès $day';
  }

  @override
  String get examToDo => 'À faire';

  @override
  String get weekExamsDone =>
      'Bravo, tous les examens de la semaine sont faits !';

  @override
  String get noExamsThisWeek => 'Pas encore d\'examen cette semaine.';

  @override
  String get examsOfTheWeek => 'Examens de la semaine';

  @override
  String get photoUnreadableTitle => 'Je n\'arrive pas à bien lire ta photo';

  @override
  String get photoUnreadableBody =>
      'Reprends-la bien éclairée, à plat, avec toute la page dans le cadre et une écriture nette.';

  @override
  String get issueBlurry => 'floue';

  @override
  String get issueDark => 'trop sombre';

  @override
  String get issueRotated => 'de travers';

  @override
  String get issueCropped => 'coupée';

  @override
  String get issueMissingParts => 'incomplète';

  @override
  String get issueIllegible => 'écriture illisible';

  @override
  String get issueNotExercise => 'ce n\'est pas l\'exercice';

  @override
  String get askDirassty => 'Aide de Dirassty';

  @override
  String get tutorTitle => 'Rafiq t\'aide';

  @override
  String get tutorIntroExercise =>
      'Je ne te donne pas la réponse tout de suite : on va y arriver ensemble. Choisis une aide ou écris où tu bloques.';

  @override
  String get tutorIntroLesson =>
      'Pose-moi une question sur la leçon, ou choisis une aide ci-dessous.';

  @override
  String get tutorHint => '💡 Un indice';

  @override
  String get tutorGuide => 'Guide-moi';

  @override
  String get tutorCheckStep => 'Vérifier mon étape';

  @override
  String get tutorExplainStep => 'Explique cette étape';

  @override
  String get tutorSolution => 'Solution complète';

  @override
  String get tutorExplain => 'Explique simplement';

  @override
  String get tutorStepByStep => 'Étape par étape';

  @override
  String get tutorExample => 'Un exemple';

  @override
  String get tutorAnotherExample => 'Un autre exemple';

  @override
  String get tutorSummary => 'Résumé';

  @override
  String get tutorInputHintExercise => 'Écris ton étape ou ta question…';

  @override
  String get tutorInputHintLesson => 'Pose ta question sur la leçon…';

  @override
  String get tutorNeedsText =>
      'Écris d\'abord ton étape (ou la partie à expliquer) dans la case.';

  @override
  String get tutorThinking => 'Dirassty réfléchit…';

  @override
  String get tutorFinalAnswer => 'Réponse finale';

  @override
  String get tutorWhy => 'Pourquoi :';

  @override
  String get tutorFormulas => 'À retenir';

  @override
  String get tutorStepCorrect => 'Étape juste ✓';

  @override
  String get tutorStepPartial => 'Presque';

  @override
  String get tutorStepIncorrect => 'À revoir';

  @override
  String aiBudgetLeft(Object pct) {
    return 'Aide de Rafiq restante aujourd\'hui : $pct %';
  }

  @override
  String get checkWithPhoto => '📷 Vérifier ma copie';

  @override
  String get checkPhotoBody =>
      'Résous sur papier, puis prends ta copie en photo (jusqu\'à 3 pages).';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get checkingCopy => 'Dirassty lit ta copie…';

  @override
  String get resultReasoning => 'Raisonnement';

  @override
  String get resultCalculation => 'Calculs';

  @override
  String get resultFinalAnswer => 'Réponse finale';

  @override
  String get alternativeMethod => 'Autre méthode, elle aussi valable 👍';

  @override
  String get whatIRead => 'Ce que j\'ai lu sur ta copie';

  @override
  String get verdictUndetermined => 'À vérifier';

  @override
  String get writeAnswerInstead => 'Écrire ma réponse à la place';

  @override
  String get correctionWellDone => 'Ce que tu as bien fait';

  @override
  String get correctionToFix => 'À corriger';

  @override
  String get correctionSeeSolution => 'Voir la solution complète';

  @override
  String get correctionHideSolution => 'Masquer la solution';

  @override
  String get noActiveSubscriptionTitle => 'Aucun abonnement actif';

  @override
  String get subscriptionCheckFailedTitle =>
      'Impossible de vérifier ton abonnement';

  @override
  String get subscriptionCheckFailedBody =>
      'Vérifie ta connexion internet, puis appuie sur le bouton pour actualiser.';

  @override
  String get updateRequiredTitle => 'Mise à jour nécessaire';

  @override
  String get updateRequiredBody =>
      'Une nouvelle version de Dirassty est disponible. Installe-la pour continuer à utiliser l\'application — tes progrès sont gardés.';

  @override
  String get updateAvailableTitle => 'Nouvelle version disponible';

  @override
  String get updateAvailableBody =>
      'Mets à jour Dirassty pour profiter des dernières améliorations.';

  @override
  String get updateNow => 'Mettre à jour';

  @override
  String get updateLater => 'Plus tard';

  @override
  String get updateWhatsNew => 'Nouveautés';

  @override
  String get updateNoLink => 'Contacter le support';

  @override
  String updateVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get fullAnswerLabel => 'Réponse complète';

  @override
  String get figureLabel => 'Figure';

  @override
  String get promoHaveCode => 'J\'ai un code promo';

  @override
  String get promoCodeOptional => 'Code promo (facultatif)';

  @override
  String get promoApply => 'Valider';

  @override
  String promoApplied(String name) {
    return 'Code de $name enregistré ✓';
  }

  @override
  String get promoUnknown => 'Code inconnu — vérifiez l\'orthographe.';

  @override
  String get freeLessonBadge => 'Gratuit';

  @override
  String get lockedLessonLabel => 'Leçon verrouillée';

  @override
  String get accountNotActiveTitle => 'Ton compte n\'est pas encore activé';

  @override
  String get accountNotActiveBody =>
      'La première leçon de chaque matière reste ouverte. Le reste s\'ouvrira dès que ton compte sera activé.';

  @override
  String get accessEndedTitle => 'Ton accès n\'est plus actif';

  @override
  String get requestBeingCheckedTitle => 'Demande en cours de vérification';

  @override
  String get requestBeingCheckedBody =>
      'L\'accès s\'ouvre dès qu\'elle est validée — touche « Actualiser » pour vérifier.';

  @override
  String get refreshAccess => 'Actualiser';

  @override
  String get childNotActiveBody =>
      'Compte pas encore activé. La première leçon de chaque matière est ouverte.';

  @override
  String get getStarted => 'Commencer';

  @override
  String get accountReadyFreeLessonsBody =>
      'La première leçon de chaque matière est déjà ouverte. Bonne découverte !';

  @override
  String get needHelpTitle => 'Besoin d\'aide ?';

  @override
  String get needHelpBody => 'Écris-nous sur WhatsApp, on te répond.';
}
