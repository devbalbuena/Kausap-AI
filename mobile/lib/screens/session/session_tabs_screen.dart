import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'upcoming_sessions_view.dart';
import 'past_sessions_view.dart';
import 'book_session_screen.dart';

class SessionTabsScreen extends StatelessWidget {
  const SessionTabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FF),
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                'Kausap AI',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primary,
                  fontSize: 20,
                  letterSpacing: -0.55,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
              onPressed: () {},
            ),
            const Padding(
              padding: EdgeInsets.only(right: 24.0, left: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.divider,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: AppTextStyles.body,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UpcomingSessionsView(),
            PastSessionsView(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookSessionScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Book Session',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
