import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_providers.dart';
import '../data/homework_repository.dart';
import 'homework_state.dart';

final Provider<HomeworkRepository> homeworkRepositoryProvider = Provider(
  (ref) => HomeworkRepository(ref.watch(apiClientProvider)),
);

/// Drives the Homework Helper flow: pick a photo, send it for analysis,
/// show the result. Ported from the phase machine in
/// apps/web/app/(student)/homework-helper/page.tsx — this result is
/// ephemeral (never persisted, on either platform), so unlike the
/// exercise session controller there's no provider invalidation to wire
/// up here.
final class HomeworkController extends StateNotifier<HomeworkState> {
  HomeworkController(this._ref) : super(const HomeworkPicking());

  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    state = HomeworkPicking(
      image: PickedHomeworkImage(
        bytes: bytes,
        filename: picked.name.isNotEmpty ? picked.name : 'homework.jpg',
      ),
    );
  }

  void clearImage() => state = const HomeworkPicking();

  Future<void> analyze({required int grade, required String lang}) async {
    final HomeworkState snapshot = state;
    if (snapshot is! HomeworkPicking || snapshot.image == null) return;

    final PickedHomeworkImage image = snapshot.image!;
    state = const HomeworkAnalyzing();
    try {
      final result = await _ref.read(homeworkRepositoryProvider).analyzeImage(
            imageBytes: image.bytes,
            filename: image.filename,
            grade: grade,
            lang: lang,
          );
      state = HomeworkResultReady(result, image: image);
    } catch (e) {
      state = HomeworkPicking(image: image, errorMessage: e.toString());
    }
  }

  /// Back to a clean slate for another photo — the "Nouvelle photo" CTA
  /// after a result.
  void reset() => state = const HomeworkPicking();
}

final StateNotifierProvider<HomeworkController, HomeworkState>
    homeworkControllerProvider =
    StateNotifierProvider<HomeworkController, HomeworkState>(
  (ref) => HomeworkController(ref),
);
