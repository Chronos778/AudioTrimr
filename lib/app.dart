import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/trimmer_cubit.dart';
import 'cubit/trimmer_state.dart';
import 'data/audio_repository.dart';
import 'domain/trim_audio_usecase.dart';
import 'ui/trimmer_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final audioRepository = AudioRepository();
    final trimAudioUseCase = TrimAudioUseCase(repository: audioRepository);

    return BlocProvider<TrimmerCubit>(
      create: (_) => TrimmerCubit(
        trimAudioUseCase: trimAudioUseCase,
        audioRepository: audioRepository,
      ),
      child: MaterialApp(
        title: 'Audio Trimmer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1DB954),
            brightness: Brightness.dark,
          ),
        ),
        home: const TrimmerScreen(),
      ),
    );
  }
}
