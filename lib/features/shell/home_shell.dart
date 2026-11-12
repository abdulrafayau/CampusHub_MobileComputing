import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../admin/admin_dashboard.dart';
import '../admin/admin_manage_screen.dart';
import '../admin/admin_requests_screen.dart';
import '../attendance/scan_screen.dart';
import '../auth/login_screen.dart';
import '../events/events_screen.dart';
import '../faculty/faculty_home.dart';
import '../faculty/verify_queue_screen.dart';
import '../profile/profile_screen.dart';
import '../societies/societies_screen.dart';
import '../society/members_screen.dart';
import '../society/society_home.dart';
import '../student/student_home.dart';

/// Space screens leave at the bottom so content clears the floating nav.
const kNavClearance = 112.0;

class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;
  const _Tab(this.icon, this.activeIcon, this.label, this.page);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  /// Lets nested screens switch tabs (e.g. "See all events").
  static void goTo(BuildContext context, int index) =>
      context.findAncestorStateOfType<_HomeShellState>()?._select(index);
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  List<_Tab> _tabsFor(AppUser u) => switch (u.role) {
        UserRole.student => const [
            _Tab(Icons.home_outlined, Icons.home_rounded, 'Home', StudentHome()),
            _Tab(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Events', EventsScreen()),
            _Tab(Icons.hub_outlined, Icons.hub_rounded, 'Societies', SocietiesScreen()),
            _Tab(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', ProfileScreen()),
          ],
        UserRole.faculty => const [
            _Tab(Icons.home_outlined, Icons.home_rounded, 'Home', FacultyHome()),
            _Tab(Icons.fact_check_outlined, Icons.fact_check_rounded, 'Verify', VerifyQueueScreen()),
            _Tab(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Events', EventsScreen()),
            _Tab(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', ProfileScreen()),
          ],
        UserRole.society => const [
            _Tab(Icons.home_outlined, Icons.home_rounded, 'Home', SocietyHome()),
            _Tab(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Events', EventsScreen(mineOnly: true)),
            _Tab(Icons.groups_outlined, Icons.groups_rounded, 'Members', MembersScreen()),
            _Tab(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', ProfileScreen()),
          ],
        UserRole.admin => const [
            _Tab(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Dashboard', AdminDashboard()),
            _Tab(Icons.tune_rounded, Icons.tune_rounded, 'Manage', AdminManageScreen()),
            _Tab(Icons.inbox_outlined, Icons.inbox_rounded, 'Requests', AdminRequestsScreen()),
            _Tab(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', ProfileScreen()),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final u = store.currentUser;
    if (u == null) {
      // signed out (or account removed) -> back to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      });
      return const Scaffold();
    }
    final tabs = _tabsFor(u);
    if (_index >= tabs.length) _index = 0;
    final isStudent = u.role == UserRole.student;
    final pendingReq = store.requests.where((r) => r.status == RequestStatus.pending).length;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: [for (final t in tabs) t.page]),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(children: [
          Expanded(
            child: Container(
              height: 66,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Row(children: [
                for (var i = 0; i < tabs.length; i++)
                  _NavItem(
                    tab: tabs[i],
                    selected: i == _index,
                    badge: u.role == UserRole.admin && i == 2 && pendingReq > 0,
                    onTap: () => _select(i),
                  ),
              ]),
            ),
          ),
          if (isStudent) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: 'Scan check-in QR',
              child: Material(
                color: AppColors.brand,
                shape: const CircleBorder(),
                elevation: 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => push(context, const ScanScreen()),
                  child: const SizedBox(
                    width: 66,
                    height: 66,
                    child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Tab tab;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;
  const _NavItem({required this.tab, required this.selected, required this.onTap, this.badge = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: selected ? 5 : 3,
      child: Semantics(
        selected: selected,
        button: true,
        label: tab.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Stack(clipBehavior: Clip.none, children: [
                Icon(selected ? tab.activeIcon : tab.icon,
                    size: 22, color: selected ? AppColors.navy : Colors.white70),
                if (badge)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.live,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.navy, width: 1.5),
                      ),
                    ),
                  ),
              ]),
              if (selected) ...[
                const SizedBox(width: 7),
                Flexible(
                  child: Text(tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: AppText.bodyStrong.copyWith(color: AppColors.navy, fontSize: 13)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
