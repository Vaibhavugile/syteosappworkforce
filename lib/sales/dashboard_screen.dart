import 'package:flutter/material.dart';

import 'history/daily_history_screen.dart';
import 'visits/visits_screen.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() =>
      _SalesDashboardScreenState();
}

class _SalesDashboardScreenState
    extends State<SalesDashboardScreen> {
  int _selectedIndex = 0;

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openVisits() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _openLeads() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _openMore() {
    setState(() {
      _selectedIndex = 3;
    });
  }

  void _openDailyHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DailyHistoryScreen(),
      ),
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          backgroundColor: const Color(0xFF111827),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1)
                      .withOpacity(.15),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  color: Color(0xFFA5B4FC),
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '$title is coming next.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHome(),
                  _buildLeadsTab(),
                  _buildVisitsTab(),
                  _buildMoreTab(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _buildHome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 28),

          _buildWelcomeCard(),

          const SizedBox(height: 24),

          _buildSectionTitle(
            'Today',
            'Your sales activity',
          ),

          const SizedBox(height: 14),

          _buildStatsGrid(),

          const SizedBox(height: 28),

          _buildSectionTitle(
            'Quick Actions',
            'Get things done faster',
          ),

          const SizedBox(height: 14),

          _buildQuickActions(),

          const SizedBox(height: 28),

          _buildSectionTitle(
            'Today\'s Follow-ups',
            '3 follow-ups pending',
          ),

          const SizedBox(height: 14),

          _buildFollowUpCard(
            company: 'ABC Technologies',
            person: 'Rahul Sharma',
            time: '11:30 AM',
            type: 'Call',
            icon: Icons.phone_outlined,
            onTap: () {
              _showComingSoon('Call management');
            },
          ),

          const SizedBox(height: 10),

          _buildFollowUpCard(
            company: 'Bright Solutions',
            person: 'Amit Verma',
            time: '2:00 PM',
            type: 'Follow-up',
            icon: Icons.access_time_outlined,
            onTap: () {
              _showComingSoon('Follow-up management');
            },
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(
            'Upcoming Visits',
            'Your scheduled visits',
            trailing: 'View all',
            onTrailingTap: _openVisits,
          ),

          const SizedBox(height: 14),

          _buildVisitCard(),

          const SizedBox(height: 28),

          _buildSectionTitle(
            'Lead Pipeline',
            'Current sales progress',
          ),

          const SizedBox(height: 14),

          _buildPipelineCard(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1)
                    .withOpacity(.18),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),

        const SizedBox(width: 13),

        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning 👋',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Sales Executive',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        _iconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            _showComingSoon('Notifications');
          },
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF374151),
            size: 23,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF111827),
            Color(0xFF1F2937),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -35,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1)
                    .withOpacity(.14),
              ),
            ),
          ),
          Positioned(
            right: 35,
            bottom: -55,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6)
                    .withOpacity(.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(.08),
                  borderRadius:
                      BorderRadius.circular(30),
                ),
                child: const Text(
                  'TODAY\'S PERFORMANCE',
                  style: TextStyle(
                    color: Color(0xFFA5B4FC),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Keep the momentum going.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'You have 3 visits and 8 follow-ups '
                'scheduled today.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.58),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  _smallMetric(
                    value: '68%',
                    label: 'Target',
                  ),
                  const SizedBox(width: 28),
                  _smallMetric(
                    value: '12',
                    label: 'Calls',
                  ),
                  const SizedBox(width: 28),
                  _smallMetric(
                    value: '3',
                    label: 'Visits',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallMetric({
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(.45),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle, {
    String? trailing,
    VoidCallback? onTrailingTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Row(
              children: [
                Text(
                  trailing,
                  style: const TextStyle(
                    color: Color(0xFF4F46E5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF4F46E5),
                  size: 17,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.people_alt_outlined,
            title: 'Leads',
            value: '24',
            change: '+4 today',
            onTap: _openLeads,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.phone_outlined,
            title: 'Calls',
            value: '12',
            change: '+3 today',
            onTap: () {
              _showComingSoon('Call management');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.location_on_outlined,
            title: 'Visits',
            value: '3',
            change: 'Today',
            onTap: _openVisits,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String change,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6366F1),
                  size: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                change,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return SizedBox(
      height: 102,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          SizedBox(width: 82, child: _quickAction(icon: Icons.person_add_alt_1_outlined, title: 'Add Lead', onTap: () { _showComingSoon('Lead creation'); })),
          const SizedBox(width: 10),
          SizedBox(width: 82, child: _quickAction(icon: Icons.location_on_outlined, title: 'Add Visit', onTap: _openVisits, highlighted: true)),
          const SizedBox(width: 10),
          SizedBox(width: 82, child: _quickAction(icon: Icons.phone_outlined, title: 'Log Call', onTap: () { _showComingSoon('Call logging'); })),
          const SizedBox(width: 10),
          SizedBox(width: 82, child: _quickAction(icon: Icons.schedule_outlined, title: 'Follow-up', onTap: () { _showComingSoon('Follow-up creation'); })),
          const SizedBox(width: 10),
          SizedBox(width: 82, child: _quickAction(icon: Icons.timeline_rounded, title: 'History', onTap: _openDailyHistory, highlighted: true)),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFFEEF2FF)
                : Colors.white,
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFC7D2FE)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFF4F46E5),
                size: 21,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FOLLOW-UP
  // ============================================================

  Widget _buildFollowUpCard({
    required String company,
    required String person,
    required String time,
    required String type,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4F46E5),
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      company,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      person,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VISIT PREVIEW
  // ============================================================

  Widget _buildVisitCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _openVisits,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.business_outlined,
                      color: Color(0xFF059669),
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 13),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'XYZ Technologies',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Client meeting',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Text(
                    '3:00 PM',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Baner, Pune',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PIPELINE
  // ============================================================

  Widget _buildPipelineCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          _pipelineRow(
            title: 'New',
            count: '8',
            percentage: .8,
          ),
          const SizedBox(height: 14),
          _pipelineRow(
            title: 'Contacted',
            count: '6',
            percentage: .6,
          ),
          const SizedBox(height: 14),
          _pipelineRow(
            title: 'Interested',
            count: '5',
            percentage: .5,
          ),
          const SizedBox(height: 14),
          _pipelineRow(
            title: 'Follow-up',
            count: '3',
            percentage: .3,
          ),
          const SizedBox(height: 14),
          _pipelineRow(
            title: 'Proposal',
            count: '2',
            percentage: .2,
          ),
        ],
      ),
    );
  }

  Widget _pipelineRow({
    required String title,
    required String count,
    required double percentage,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 7,
              backgroundColor:
                  const Color(0xFFF3F4F6),
              color: const Color(0xFF6366F1),
            ),
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 22,
          child: Text(
            count,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LEADS TAB
  // ============================================================

  Widget _buildLeadsTab() {
    return _buildModulePlaceholder(
      icon: Icons.people_alt_outlined,
      title: 'Leads',
      subtitle:
          'Manage your prospects, customers and sales pipeline.',
      primaryLabel: 'Add Lead',
      primaryIcon:
          Icons.person_add_alt_1_outlined,
      onPrimaryTap: () {
        _showComingSoon('Lead creation');
      },
    );
  }

  // ============================================================
  // VISITS TAB
  // ============================================================

  Widget _buildVisitsTab() {
    return const VisitsScreen();
  }

  // ============================================================
  // MORE TAB
  // ============================================================

  Widget _buildMoreTab() {
    return _buildMoreScreen();
  }

  Widget _buildMoreScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'More',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Sales tools and account options',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 24),

          _moreTile(
            icon: Icons.phone_in_talk_outlined,
            title: 'Calls',
            subtitle:
                'View your calling activity',
            onTap: () {
              _showComingSoon('Calls');
            },
          ),

          const SizedBox(height: 10),

          _moreTile(
            icon: Icons.schedule_outlined,
            title: 'Follow-ups',
            subtitle:
                'Manage pending follow-ups',
            onTap: () {
              _showComingSoon('Follow-ups');
            },
          ),

          const SizedBox(height: 10),

          _moreTile(
            icon: Icons.timeline_rounded,
            title: 'Daily History',
            subtitle:
                'Review your activity timeline and visit route',
            onTap: _openDailyHistory,
          ),

          const SizedBox(height: 10),

          _moreTile(
            icon: Icons.bar_chart_outlined,
            title: 'Performance',
            subtitle:
                'View your sales performance',
            onTap: () {
              _showComingSoon('Performance');
            },
          ),

          const SizedBox(height: 10),

          _moreTile(
            icon: Icons.person_outline_rounded,
            title: 'My Profile',
            subtitle:
                'View and manage your profile',
            onTap: () {
              _showComingSoon('Profile');
            },
          ),

          const SizedBox(height: 10),

          _moreTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle:
                'Application preferences',
            onTap: () {
              _showComingSoon('Settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _moreTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4F46E5),
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GENERIC MODULE PLACEHOLDER
  // ============================================================

  Widget _buildModulePlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback onPrimaryTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius:
                    BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6366F1),
                size: 36,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            Material(
              color: const Color(0xFF4F46E5),
              borderRadius:
                  BorderRadius.circular(14),
              child: InkWell(
                onTap: onPrimaryTap,
                borderRadius:
                    BorderRadius.circular(14),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        primaryIcon,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        primaryLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          child: Row(
            children: [
              _navItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              _navItem(
                index: 1,
                icon: Icons.people_alt_outlined,
                label: 'Leads',
              ),
              _navItem(
                index: 2,
                icon: Icons.location_on_outlined,
                label: 'Visits',
              ),
              _navItem(
                index: 3,
                icon: Icons.more_horiz_rounded,
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected =
        _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius:
            BorderRadius.circular(15),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEEF2FF)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF9CA3AF),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}