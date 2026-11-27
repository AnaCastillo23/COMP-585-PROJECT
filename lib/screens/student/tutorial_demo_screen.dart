import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/reservation_service.dart';
import 'equipment_catalog.dart';
import 'my_rentals.dart';
import 'student_dashboard.dart';

enum _Goal { none, openBrowse, reserve, openRentals, waitlist }

class _DemoStep {
  const _DemoStep({
    required this.title,
    required this.body,
    this.goal = _Goal.none,
    this.doneMessage,
  });

  final String title;
  final String body;

  /// What the student must do to finish this step (they can always skip).
  final _Goal goal;

  /// Shown once the goal is completed.
  final String? doneMessage;
}

const _steps = <_DemoStep>[
  _DemoStep(
    title: 'Welcome to practice mode',
    body:
        'This is a practice copy of the app with sample data, so nothing you '
        'do is real. The side panel on the left (or the bar at the bottom on '
        'a phone) switches between Dashboard, Browse, and My Rentals.',
  ),
  _DemoStep(
    title: 'Open Browse',
    body:
        'Tap Browse in the side panel (or the bottom bar). You can also tap '
        'Browse all on the dashboard.',
    goal: _Goal.openBrowse,
    doneMessage:
        'This is the full catalog. Try the search box or a category chip to '
        'narrow the list.',
  ),
  _DemoStep(
    title: 'Reserve an item',
    body:
        'Tap Reserve on any available item and confirm. This is practice '
        'mode, so nothing real will be reserved.',
    goal: _Goal.reserve,
    doneMessage:
        'Reservation made! In the real app it is held for you for 24 hours.',
  ),
  _DemoStep(
    title: 'Check My Rentals',
    body:
        'Tap My Rentals to see your reservation under Pending Pickup, with a '
        'countdown to your pickup deadline.',
    goal: _Goal.openRentals,
    doneMessage:
        'Your reservation is listed under Pending Pickup. Tap Pickup details '
        'to see what to bring.',
  ),
  _DemoStep(
    title: 'Try the waitlist',
    body:
        'Go back to Browse and tap the button on an unavailable item to join '
        'its waitlist.',
    goal: _Goal.waitlist,
    doneMessage:
        'You joined the waitlist! Your position now shows under Waitlist in '
        'My Rentals.',
  ),
  _DemoStep(
    title: 'You are ready',
    body:
        'That is it. After staff checks equipment out to you, the standard '
        'rental period is 14 days, so return it on time.',
  ),
];

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

// Same destinations as the real app shell.
const _destinations = <_Destination>[
  _Destination('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  _Destination('Browse', Icons.grid_view_outlined, Icons.grid_view),
  _Destination('My Rentals', Icons.assignment_outlined, Icons.assignment),
];

/// Practice mode: the real student screens (dashboard, Browse, My Rentals)
/// with the real side panel, running on a throwaway in-memory reservation
/// service, plus a step-by-step instruction panel. Nothing here touches
/// Firebase or the shared demo service.
class TutorialDemoScreen extends StatefulWidget {
  const TutorialDemoScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<TutorialDemoScreen> createState() => _TutorialDemoScreenState();
}

class _TutorialDemoScreenState extends State<TutorialDemoScreen> {
  static const _studentUid = 'tutorial-student';

  late final InMemoryReservationService _service;

  int _stepIndex = 0;
  int _tab = 0;

  bool _visitedBrowse = false;
  bool _visitedRentals = false;
  bool _reserved = false;
  bool _waitlisted = false;

  _DemoStep get _step => _steps[_stepIndex];
  bool get _isLast => _stepIndex == _steps.length - 1;

  bool get _goalDone => switch (_step.goal) {
    _Goal.none => true,
    _Goal.openBrowse => _visitedBrowse,
    _Goal.reserve => _reserved,
    _Goal.openRentals => _visitedRentals,
    _Goal.waitlist => _waitlisted,
  };

  @override
  void initState() {
    super.initState();

    // Separate instance (not .shared) so practice never leaks into the app.
    _service = InMemoryReservationService(
      initialWaitlistCounts: const {'EQ-1003': 2},
    );
    _service.addListener(_handleServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_handleServiceChanged);
    _service.dispose();
    super.dispose();
  }

  void _handleServiceChanged() {
    unawaited(_refreshProgress());
  }

  Future<void> _refreshProgress() async {
    final reservations = await _service.getReservationsForStudent(_studentUid);
    final waitlist = await _service.getWaitlistEntriesForStudent(_studentUid);

    if (!mounted) {
      return;
    }

    setState(() {
      _reserved = reservations.isNotEmpty;
      _waitlisted = waitlist.isNotEmpty;
    });
  }

  void _selectTab(int index) {
    setState(() {
      _tab = index;
      if (index == 1) _visitedBrowse = true;
      if (index == 2) _visitedRentals = true;
    });
  }

  void _next() {
    if (_isLast) {
      widget.onFinished();
    } else {
      setState(() => _stepIndex++);
    }
  }

  void _back() {
    if (_stepIndex > 0) {
      setState(() => _stepIndex--);
    }
  }

  Widget _buildScreen() {
    return switch (_tab) {
      0 => StudentDashboardScreen(
        studentUid: _studentUid,
        reservationService: _service,
        checkFirstLoginTutorial: false,
        onBrowseAll: () => _selectTab(1),
      ),
      1 => EquipmentCatalogScreen(
        studentUid: _studentUid,
        reservationService: _service,
      ),
      _ => MyRentalsScreen(
        studentUid: _studentUid,
        reservationService: _service,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Same breakpoint as the real app shell.
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tutorial'),
        actions: [
          TextButton(
            onPressed: widget.onFinished,
            child: const Text('Exit tutorial'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF1F2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'Practice mode: nothing you do here is real.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.csunRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  _DemoSidebar(selectedIndex: _tab, onSelected: _selectTab),
                Expanded(child: _buildScreen()),
              ],
            ),
          ),
        ],
      ),
      // Using bottomNavigationBar keeps snackbars above the panel.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepPanel(
            step: _step,
            stepNumber: _stepIndex + 1,
            stepCount: _steps.length,
            goalDone: _goalDone,
            isLast: _isLast,
            onBack: _stepIndex > 0 ? _back : null,
            onNext: _next,
          ),
          if (!wide)
            NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: _selectTab,
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Copy of the real app's desktop side panel.
class _DemoSidebar extends StatelessWidget {
  const _DemoSidebar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: ColoredBox(
        color: AppColors.charcoal,
        child: Column(
          children: [
            Container(
              height: 86,
              color: AppColors.csunRed,
              alignment: Alignment.center,
              child: const Text(
                'CSUN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < _destinations.length; index++)
              _DemoSidebarItem(
                destination: _destinations[index],
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
          ],
        ),
      ),
    );
  }
}

class _DemoSidebarItem extends StatelessWidget {
  const _DemoSidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFFD3D3D3);

    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.csunRed : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: color,
                size: 25,
              ),
              const SizedBox(height: 6),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({
    required this.step,
    required this.stepNumber,
    required this.stepCount,
    required this.goalDone,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  final _DemoStep step;
  final int stepNumber;
  final int stepCount;
  final bool goalDone;
  final bool isLast;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final doneMessage = step.doneMessage;

    return Material(
      color: Colors.white,
      elevation: 8,
      child: Center(
        // Without heightFactor, Center stretches to the full screen height
        // and the white panel covers the app.
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $stepNumber of $stepCount',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                if (goalDone && doneMessage != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doneMessage,
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  )
                else
                  Text(step.body, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onBack != null)
                      TextButton(onPressed: onBack, child: const Text('Back')),
                    const Spacer(),
                    if (goalDone)
                      FilledButton(
                        onPressed: onNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.csunRed,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isLast ? 'Finish' : 'Next'),
                      )
                    else
                      TextButton(
                        onPressed: onNext,
                        child: const Text('Skip step'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}