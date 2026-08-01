import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/discover_service.dart';
import 'professional_profile_screen.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_loading_widget.dart';

class DiscoverProfessionalsScreen extends StatefulWidget {
  const DiscoverProfessionalsScreen({super.key});

  @override
  State<DiscoverProfessionalsScreen> createState() => _DiscoverProfessionalsScreenState();
}

class _DiscoverProfessionalsScreenState extends State<DiscoverProfessionalsScreen> {
  final DiscoverService _discoverService = DiscoverService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _professionals = [];
  bool _isLoading = true;
  String? _error;

  String _selectedSpecialty = 'All';
  final List<String> _specialties = ['All', 'Anxiety', 'Depression', 'Relationships', 'ADHD', 'Trauma'];

  @override
  void initState() {
    super.initState();
    _fetchProfessionals();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfessionals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final search = _searchController.text.trim();
      final specialty = _selectedSpecialty == 'All' ? null : _selectedSpecialty;
      
      final results = await _discoverService.getProfessionals(
        search: search,
        specialization: specialty,
      );
      
      if (mounted) {
        setState(() {
          _professionals = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load professionals. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Find a Professional',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance back button
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          _fetchProfessionals();
                        });
                      },
                      onSubmitted: (_) => _fetchProfessionals(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search by name or specialty...',
                        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchProfessionals();
                                },
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _specialties.length,
                    itemBuilder: (context, index) {
                      final specialty = _specialties[index];
                      final isSelected = specialty == _selectedSpecialty;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(specialty),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSpecialty = specialty);
                              _fetchProfessionals();
                            }
                          },
                          labelStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          selectedColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // List View
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: 4,
                          itemBuilder: (context, index) => const ProfessionalCardSkeleton(),
                        )
                      : _error != null
                          ? Center(
                              child: Text(_error!,
                                  style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFFEF4444))))
                          : _professionals.isEmpty
                              ? EmptyStateWidget(
                                  icon: Icons.search_off_rounded,
                                  title: 'No professionals found',
                                  description: 'We couldn\'t find any professionals matching your criteria. Try clearing some filters.',
                                  buttonText: _selectedSpecialty != 'All' ? 'Clear Filters' : null,
                                  onButtonPressed: _selectedSpecialty != 'All'
                                      ? () => setState(() {
                                            _selectedSpecialty = 'All';
                                            _fetchProfessionals();
                                          })
                                      : null,
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  itemCount: _professionals.length,
                                  itemBuilder: (context, index) {
                                    final prof = _professionals[index];
                                    return _buildProfessionalCard(prof);
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalCard(Map<String, dynamic> prof) {
    final firstName = prof['first_name'] ?? '';
    final lastName = prof['last_name'] ?? '';
    final profession = prof['profession'] ?? 'Therapist';
    final specialization = prof['specialization'] ?? '';
    final experience = prof['years_of_experience'] ?? 0;
    final heroTag = 'avatar_${prof['user_id'] ?? firstName}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          slideRoute(ProfessionalProfileScreen(professionalData: prof, heroTag: heroTag))
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Hero(
              tag: heroTag,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withAlpha(20),
                child: Text(
                  _getInitials(firstName, lastName),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profession,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 4),
                      const Text(
                        '5.0', // Hardcoded rating for now
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.work_outline_rounded, color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$experience yrs exp',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (specialization.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        specialization,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
