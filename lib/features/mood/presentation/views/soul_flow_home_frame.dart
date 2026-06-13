import 'package:flutter/material.dart';
import '../../../../core/theme/soul_flow_theme.dart';
import '../../../../core/services/localizations.dart';
import 'dashboard_view.dart';
import 'journal_view.dart';
import 'room_view.dart';
import 'profile_stats_view.dart';
import 'add_mood_screen.dart';


class SoulFlowHomeFrame extends StatefulWidget {
  const SoulFlowHomeFrame({super.key});

  @override
  State<SoulFlowHomeFrame> createState() => _SoulFlowHomeFrameState();
}

class _SoulFlowHomeFrameState extends State<SoulFlowHomeFrame> {
  int _currentIndex = 0;

  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      DashboardView(
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onOpenJournalForm: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddMoodScreen()),
          );
        },
      ),
      const JournalView(),
      const RoomView(),
      const ProfileStatsView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121816)
          : SoulFlowTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SoulFlow',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: SoulFlowTheme.primarySage,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddMoodScreen()),
              );
            },
            icon: const Icon(
              Icons.edit_calendar_outlined,
              color: SoulFlowTheme.primarySage,
            ),
            tooltip: localizations.translate('add_mood_title'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _views[_currentIndex],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: SoulFlowTheme.primarySage.withValues(
                alpha: isDark ? 0.02 : 0.08,
              ),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: isDark
                ? SoulFlowTheme.surfaceCardDark
                : Colors.white,
            selectedItemColor: SoulFlowTheme.primarySage,
            unselectedItemColor: isDark
                ? Colors.grey.shade600
                : SoulFlowTheme.textMuted,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.space_dashboard_outlined),
                activeIcon: const Icon(Icons.space_dashboard),
                label: localizations.translate('home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.book_outlined),
                activeIcon: const Icon(Icons.book),
                label: localizations.translate('journal'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.group_outlined),
                activeIcon: const Icon(Icons.group),
                label: localizations.translate('sharing_room'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: localizations.translate('profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
