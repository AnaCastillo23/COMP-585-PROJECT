import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/equipment_card.dart';
import 'tutorial_demo_screen.dart';

/// Opens the intro tutorial full screen. Used for first login and for the
/// "Replay tutorial" button on the profile screen.
///
/// Flow: intro slides, then "Try it yourself" opens the practice dashboard.
Future<void> showTutorial(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (routeContext) => TutorialScreen(
        onFinished: () => Navigator.of(routeContext).pop(),
        onTryIt: () => Navigator.of(routeContext).pushReplacement(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (demoContext) => TutorialDemoScreen(
              onFinished: () => Navigator.of(demoContext).pop(),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TutorialSlide {
  const _TutorialSlide({
    required this.icon,
    required this.title,
    required this.body,
    this.previewWidth = 320,
    this.preview,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Optional live snippet of the real UI. Falls back to the icon circle.
  final Widget Function()? preview;
  final double previewWidth;
}

final _slides = <_TutorialSlide>[
  const _TutorialSlide(
    icon: Icons.waving_hand_outlined,
    title: 'Welcome to Equipment Checkout',
    body:
        'Borrow cameras, laptops, microcontrollers, and more for your class '
        'projects. This quick tour shows you how it works.',
  ),
  _TutorialSlide(
    icon: Icons.explore_outlined,
    title: 'Get around the app',
    body:
        'On a computer, use the side panel to switch between your Dashboard, '
        'Browse, and My Rentals. On your phone, the same three options are in '
        'the bar at the bottom.',
    previewWidth: 380,
    preview: () => const _NavOverviewPreview(),
  ),
  _TutorialSlide(
    icon: Icons.dashboard_outlined,
    title: 'Your dashboard',
    body:
        'The dashboard shows how many items are available right now, what you '
        'have checked out, your reservations, and what is due soon.',
    preview: () => const _DashboardPreview(),
  ),
  _TutorialSlide(
    icon: Icons.grid_view,
    title: 'Browse the catalog',
    body:
        'Choose Browse in the side panel, or tap Browse all on the dashboard. '
        'Search by name or category, or tap a category chip to narrow the list.',
    previewWidth: 380,
    preview: () => const _CatalogScreenPreview(),
  ),
  _TutorialSlide(
    icon: Icons.event_available_outlined,
    title: 'Reserve it',
    body:
        'Tap Reserve on an item to request it. Reservations are held for one '
        'day, so pick up your equipment before the pickup window expires, and '
        'bring your student ID.',
    previewWidth: 280,
    preview: () => SizedBox(
      height: 336,
      child: EquipmentCard(
        equipment: mockEquipment.first,
        onReserve: () {},
      ),
    ),
  ),
  _TutorialSlide(
    icon: Icons.format_list_numbered,
    title: 'Join the waitlist',
    body:
        'If every unit is checked out, you can join the waitlist. Your '
        'position shows in My Rentals. When an item is assigned to you, your '
        'one-day pickup window begins.',
    preview: () => const _PreviewRentalCard(
      icon: Icons.format_list_numbered,
      color: Color(0xFF1565C0),
      name: 'Arduino Starter Kit',
      status: 'Waitlist position #2',
    ),
  ),
  _TutorialSlide(
    icon: Icons.assignment_outlined,
    title: 'Keep track in My Rentals',
    body:
        'My Rentals has three sections: Pending Pickup, Waitlist, and Checked '
        'Out. After staff checks an item out to you, the standard rental '
        'period is 14 days, so return it on time.',
    previewWidth: 360,
    preview: () => const _RentalsScreenPreview(),
  ),
];

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, required this.onFinished, this.onTryIt});

  /// Called when the student taps Skip (or finishes, if [onTryIt] is null).
  final VoidCallback onFinished;

  /// If set, the last slide's button becomes "Try it yourself" and calls this.
  final VoidCallback? onTryIt;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_isLast) {
      (widget.onTryIt ?? widget.onFinished)();
    } else {
      _goTo(_index + 1);
    }
  }

  void _back() {
    if (_index > 0) {
      _goTo(_index - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _back,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: TextButton(
                      onPressed: widget.onFinished,
                      child: const Text('Skip'),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (page) => setState(() => _index = page),
                    itemBuilder: (context, page) =>
                        _SlidePage(slide: _slides[page]),
                  ),
                ),
                _DotsIndicator(count: _slides.length, index: _index),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: _index > 0
                              ? TextButton(
                                  onPressed: _back,
                                  child: const Text('Back'),
                                )
                              : null,
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.csunRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                          ),
                          child: Text(
                            _isLast
                                ? (widget.onTryIt != null
                                      ? 'Try it yourself'
                                      : 'Get started')
                                : 'Next',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide});

  final _TutorialSlide slide;

  @override
  Widget build(BuildContext context) {
    final preview = slide.preview;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (preview != null)
                _PreviewFrame(width: slide.previewWidth, child: preview())
              else
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.csunRed.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(slide.icon, size: 44, color: AppColors.csunRed),
                ),
              const SizedBox(height: 32),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              Text(
                slide.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frames a UI snippet so it reads as a screenshot: non-interactive,
/// hidden from screen readers, and scaled down on narrow screens.
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            width: width,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Side panel previews (mirror the shell's desktop sidebar)
// ---------------------------------------------------------------------------

const double _sidebarWidth = 108;
const double _headerHeight = 56;

class _NavItemData {
  const _NavItemData(this.label, this.icon, this.selectedIcon, this.caption);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String caption;
}

const _navItems = <_NavItemData>[
  _NavItemData(
    'Dashboard',
    Icons.dashboard_outlined,
    Icons.dashboard,
    'Your activity at a glance',
  ),
  _NavItemData(
    'Browse',
    Icons.grid_view_outlined,
    Icons.grid_view,
    'Search and filter the catalog',
  ),
  _NavItemData(
    'My Rentals',
    Icons.assignment_outlined,
    Icons.assignment,
    'Reservations, waitlist, and checkouts',
  ),
];

class _PreviewSidebarHeader extends StatelessWidget {
  const _PreviewSidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _headerHeight,
      color: AppColors.csunRed,
      alignment: Alignment.center,
      child: const Text(
        'CSUN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
      ),
    );
  }
}

class _PreviewNavItem extends StatelessWidget {
  const _PreviewNavItem({required this.data, required this.selected});

  final _NavItemData data;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFFD3D3D3);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent,
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
            selected ? data.selectedIcon : data.icon,
            color: color,
            size: 25,
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The side panel with a one-line caption beside each item.
class _NavOverviewPreview extends StatelessWidget {
  const _NavOverviewPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                SizedBox(width: _sidebarWidth, child: _PreviewSidebarHeader()),
                Expanded(child: SizedBox(height: _headerHeight)),
              ],
            ),
            for (var i = 0; i < _navItems.length; i++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: _sidebarWidth,
                      child: ColoredBox(
                        color: AppColors.charcoal,
                        child: _PreviewNavItem(
                          data: _navItems[i],
                          selected: i == 0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_back,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _navItems[i].caption,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors the top of the Browse Equipment screen: title, search box,
/// category chips, and item count. Uses the real theme widgets.
class _CatalogScreenPreview extends StatelessWidget {
  const _CatalogScreenPreview();

  @override
  Widget build(BuildContext context) {
    final categories = <String>[
      'All',
      ...{for (final item in mockEquipment) item.category},
    ].take(4).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse Equipment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Search by equipment name or category',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < categories.length; i++)
              FilterChip(
                label: Text(categories[i]),
                selected: i == 0,
                onSelected: (_) {},
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${mockEquipment.length} items',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Mirrors the My Rentals screen: three sections with one sample card each.
class _RentalsScreenPreview extends StatelessWidget {
  const _RentalsScreenPreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Rentals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 14),
        _PreviewSectionTitle('Pending Pickup'),
        _PreviewRentalCard(
          icon: Icons.event_available_outlined,
          color: AppColors.warning,
          name: 'Raspberry Pi 5',
          status: '5 hr 12 min remaining to pick up',
        ),
        SizedBox(height: 16),
        _PreviewSectionTitle('Waitlist'),
        _PreviewRentalCard(
          icon: Icons.format_list_numbered,
          color: Color(0xFF1565C0),
          name: 'Arduino Starter Kit',
          status: 'Waitlist position #2',
        ),
        SizedBox(height: 16),
        _PreviewSectionTitle('Checked Out'),
        _PreviewRentalCard(
          icon: Icons.inventory_2_outlined,
          color: AppColors.csunRed,
          name: 'DSLR Camera Kit',
          status: '2 days remaining',
        ),
      ],
    );
  }
}

class _PreviewSectionTitle extends StatelessWidget {
  const _PreviewSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Compact copy of the cards on the My Rentals screen.
class _PreviewRentalCard extends StatelessWidget {
  const _PreviewRentalCard({
    required this.icon,
    required this.color,
    required this.name,
    required this.status,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard previews
// ---------------------------------------------------------------------------

/// Mirrors the dashboard's stat cards and "Browse all" button.
class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    final available = mockEquipment.fold<int>(
      0,
      (total, equipment) => total + equipment.availableUnits,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _PreviewStat(
                label: 'Available items',
                value: '$available',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _PreviewStat(
                label: 'Reservations',
                value: '1',
                icon: Icons.event_available_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Featured equipment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const ShapeDecoration(
                color: AppColors.background,
                shape: StadiumBorder(),
              ),
              child: const Text(
                'Browse all',
                style: TextStyle(
                  color: AppColors.csunRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.csunRed.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppColors.csunRed, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? AppColors.csunRed : AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}