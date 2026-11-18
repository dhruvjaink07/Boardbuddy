import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/ai_assistant/ai_assistant_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/board_detail/board_detail_bloc.dart';
import 'blocs/board_list/board_list_bloc.dart';
import 'core/theme/app_theme.dart';
import 'repositories/board_repository.dart';
import 'screens/onboarding/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F11),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final boardRepository = InMemoryBoardRepository();

  runApp(BoardBuddyApp(boardRepository: boardRepository));
}

class BoardBuddyApp extends StatelessWidget {
  final BoardRepository boardRepository;

  const BoardBuddyApp({super.key, required this.boardRepository});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BoardRepository>.value(value: boardRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(),
          ),
          BlocProvider<BoardListBloc>(
            create: (ctx) => BoardListBloc(repository: ctx.read<BoardRepository>()),
          ),
          BlocProvider<BoardDetailBloc>(
            create: (ctx) => BoardDetailBloc(repository: ctx.read<BoardRepository>()),
          ),
          BlocProvider<AiAssistantBloc>(
            create: (_) => AiAssistantBloc(),
          ),
        ],
        child: MaterialApp(
          title: 'BoardBuddy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const WelcomeScreen(),
        ),
      ),
    );
  }
}
