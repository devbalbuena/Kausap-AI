import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class MindfulnessExercisesScreen extends StatefulWidget {
  const MindfulnessExercisesScreen({super.key});

  @override
  State<MindfulnessExercisesScreen> createState() => _MindfulnessExercisesScreenState();
}

class _MindfulnessExercisesScreenState extends State<MindfulnessExercisesScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  
  // Base static list that will be merged with dynamic favorite state
  final List<Map<String, dynamic>> _exercises = [
    {
      'id': '1',
      'title': '4-7-8 Breathing',
      'duration': '5 min',
      'category': 'Breathing',
      'icon': Icons.air_rounded,
      'color': const Color(0xFF60A5FA),
    },
    {
      'id': '2',
      'title': 'Body Scan Meditation',
      'duration': '10 min',
      'category': 'Meditation',
      'icon': Icons.self_improvement_rounded,
      'color': const Color(0xFF34D399),
    },
    {
      'id': '3',
      'title': 'Morning Gratitude',
      'duration': '3 min',
      'category': 'Reflection',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFFFBBF24),
    },
    {
      'id': '4',
      'title': 'Deep Sleep Wind Down',
      'duration': '15 min',
      'category': 'Sleep',
      'icon': Icons.nights_stay_rounded,
      'color': const Color(0xFF818CF8),
    },
  ];

  Map<String, bool> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final String? savedFavs = await _storage.read(key: 'mindfulness_favorites');
      if (savedFavs != null) {
        final decoded = json.decode(savedFavs) as Map<String, dynamic>;
        _favorites = decoded.map((key, value) => MapEntry(key, value as bool));
      }
    } catch (e) {
      // Ignored
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() {
      _favorites[id] = !(_favorites[id] ?? false);
    });
    
    await _storage.write(key: 'mindfulness_favorites', value: json.encode(_favorites));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mindfulness Exercises', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  final id = exercise['id'] as String;
                  final isFavorite = _favorites[id] ?? false;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Starting ${exercise['title']}...')),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: (exercise['color'] as Color).withAlpha(30),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  exercise['icon'] as IconData,
                                  color: exercise['color'] as Color,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise['title'] as String,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${exercise['category']} • ${exercise['duration']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFavorite ? Colors.red : AppColors.textSecondary,
                                ),
                                onPressed: () => _toggleFavorite(id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
