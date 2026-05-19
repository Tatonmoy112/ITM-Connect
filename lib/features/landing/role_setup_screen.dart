import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itm_connect/features/user/home/user_home_screen.dart';
import 'package:itm_connect/theme/app_colors.dart';
import 'package:itm_connect/services/schedule_service.dart';
import 'package:itm_connect/services/teacher_service.dart';
import 'package:itm_connect/services/routine_service.dart';
import 'package:itm_connect/services/batch_service.dart';
import 'package:itm_connect/widgets/notification_schedule_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoleSetupScreen extends StatefulWidget {
  final bool isFromSettings;
  const RoleSetupScreen({super.key, this.isFromSettings = false});

  @override
  State<RoleSetupScreen> createState() => _RoleSetupScreenState();
}

class _RoleSetupScreenState extends State<RoleSetupScreen> {
  String _selectedRole = 'Student'; // Default
  final TextEditingController _identifierController = TextEditingController();
  final FocusNode _identifierFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isFetchingSuggestions = false;

  // Suggestions
  List<String> _allSuggestions = [];
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _fetchSuggestions();

    _identifierController.addListener(_onIdentifierChanged);
    _identifierFocusNode.addListener(() {
      if (!_identifierFocusNode.hasFocus) {
        // Delay hiding to allow tap on suggestion
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  Future<void> _loadExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    final identifier = prefs.getString('user_identifier');
    if (role != null) {
      setState(() {
        _selectedRole = role;
      });
    }
    if (identifier != null) {
      _identifierController.text = identifier;
    }
  }

  /// Fetch available batches or teacher initials from Firebase
  Future<void> _fetchSuggestions() async {
    setState(() => _isFetchingSuggestions = true);
    try {
      if (_selectedRole == 'Student') {
        // Fetch from both routines and batches collections
        final routineBatches =
            await RoutineService().streamAllBatches().first;
        final batchIds = await BatchService().getAllBatchIds();

        // Merge and deduplicate
        final allBatches = <String>{};
        for (final b in routineBatches) {
          allBatches.add(b.toUpperCase());
        }
        for (final b in batchIds) {
          allBatches.add(b.toUpperCase());
        }
        _allSuggestions = allBatches.toList()..sort();
      } else {
        // Fetch teacher initials
        final teachers = await TeacherService().getAllTeachers();
        _allSuggestions = teachers
            .map((t) => t.teacherInitial.toUpperCase())
            .where((i) => i.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
      _allSuggestions = [];
    }
    if (mounted) {
      setState(() {
        _isFetchingSuggestions = false;
        _filterSuggestions(_identifierController.text);
      });
    }
  }

  void _onIdentifierChanged() {
    _filterSuggestions(_identifierController.text);
  }

  void _filterSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredSuggestions = List.from(_allSuggestions);
        _showSuggestions = _identifierFocusNode.hasFocus && _allSuggestions.isNotEmpty;
      });
      return;
    }

    final q = query.toUpperCase();
    final filtered = _allSuggestions
        .where((s) => s.contains(q))
        .toList();
    setState(() {
      _filteredSuggestions = filtered;
      _showSuggestions = _identifierFocusNode.hasFocus && filtered.isNotEmpty;
    });
  }

  void _selectSuggestion(String suggestion) {
    _identifierController.text = suggestion;
    _identifierController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() => _showSuggestions = false);
    _identifierFocusNode.unfocus();
  }

  @override
  void dispose() {
    _identifierController.removeListener(_onIdentifierChanged);
    _identifierController.dispose();
    _identifierFocusNode.dispose();
    super.dispose();
  }

  /// Validate teacher initial against Firestore teachers collection
  Future<bool> _validateTeacherInitial(String initial) async {
    try {
      // Check against fetched suggestions first (already from Firebase)
      if (_allSuggestions
          .any((s) => s.toUpperCase() == initial.toUpperCase())) {
        return true;
      }
      // Double-check directly from Firestore
      final teacher = await TeacherService().getTeacher(initial.toUpperCase());
      return teacher != null;
    } catch (e) {
      debugPrint('Teacher validation error: $e');
      return false;
    }
  }

  /// Validate student batch — exact match against routines + batches collections
  Future<bool> _validateStudentBatch(String batch) async {
    try {
      // Check against fetched suggestions first (already from Firebase)
      if (_allSuggestions
          .any((s) => s.toUpperCase() == batch.toUpperCase())) {
        return true;
      }
      // Double-check: routines collection
      final routineBatches =
          await RoutineService().streamAllBatches().first;
      if (routineBatches
          .any((b) => b.toUpperCase() == batch.toUpperCase())) {
        return true;
      }
      // Double-check: batches collection
      final batchIds = await BatchService().getAllBatchIds();
      return batchIds.any((b) => b.toUpperCase() == batch.toUpperCase());
    } catch (e) {
      debugPrint('Batch validation error: $e');
      return false;
    }
  }

  Future<void> _saveAndContinue() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedRole == 'Student'
              ? 'Please enter your Batch to continue.'
              : 'Please enter your Initial to continue.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ── Strict Validation ──
      bool found = false;
      if (_selectedRole == 'Teacher') {
        found = await _validateTeacherInitial(identifier);
      } else {
        found = await _validateStudentBatch(identifier);
      }

      // ❌ BLOCK if not found — do NOT save or navigate
      if (!found) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        final entityLabel =
            _selectedRole == 'Student' ? 'Batch' : 'Initial';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$entityLabel "$identifier" doesn\'t exist in our records. Please check and try again.',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
        return; // ← Stop here, do NOT save
      }

      // ✅ Valid — Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', _selectedRole);
      await prefs.setString('user_identifier', identifier);
      await prefs.setBool('has_completed_setup', true);

      // Cache routines for offline notification scheduling
      try {
        await ScheduleService().cacheRoutinesForUser(_selectedRole, identifier);
      } catch (e) {
        debugPrint('Routine caching error: $e');
      }

      // Schedule class notifications
      try {
        await ScheduleService().scheduleClassNotifications();
      } catch (e) {
        debugPrint('Notification scheduling error: $e');
      }

      if (!mounted) return;

      // Show schedule dialog
      await NotificationScheduleDialog.show(
        context,
        role: _selectedRole,
        identifier: identifier,
      );

      if (!mounted) return;

      if (widget.isFromSettings) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const UserHomeScreen(initialTabIndex: -1)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Skip setup — user won't receive notifications
  Future<void> _skipSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_setup', true);
    // Don't save role or identifier — user opts out of notifications

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => const UserHomeScreen(initialTabIndex: -1)),
    );
  }

  Widget _buildRoleCard(
      String role, IconData icon, String description, bool isDark) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
            _identifierController.clear();
            _showSuggestions = false;
            _filteredSuggestions = [];
          });
          // Re-fetch suggestions for the new role
          _fetchSuggestions();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? ITMColors.gradientStart.withOpacity(isDark ? 0.2 : 0.1)
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? ITMColors.gradientStart
                  : (isDark ? Colors.white12 : Colors.black12),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ITMColors.gradientStart.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: isSelected
                    ? ITMColors.gradientStart
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(
                role,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? ITMColors.gradientStart
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the autocomplete suggestion chips
  Widget _buildSuggestionDropdown(bool isDark) {
    if (!_showSuggestions || _filteredSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? ITMColors.gradientEnd.withOpacity(0.3)
              : ITMColors.gradientStart.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _filteredSuggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          itemBuilder: (context, index) {
            final suggestion = _filteredSuggestions[index];
            final query = _identifierController.text.toUpperCase();
            final isExactMatch = suggestion == query;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectSuggestion(suggestion),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        _selectedRole == 'Student'
                            ? Icons.school_rounded
                            : Icons.badge_rounded,
                        size: 18,
                        color: isExactMatch
                            ? ITMColors.gradientStart
                            : (isDark ? Colors.white54 : Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedRole == 'Student'
                            ? 'Batch $suggestion'
                            : suggestion,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isExactMatch
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isExactMatch
                              ? ITMColors.gradientStart
                              : (isDark
                                  ? Colors.white
                                  : Colors.black87),
                        ),
                      ),
                      const Spacer(),
                      if (isExactMatch)
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: ITMColors.gradientStart,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.isFromSettings
          ? AppBar(
              title: const Text('Edit Your Status'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [ITMColors.darkBackground, const Color(0xFF0D2137)]
                : [const Color(0xFFf5f7fa), const Color(0xFFe0f7fa)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? ITMColors.gradientEnd.withOpacity(0.2)
                            : ITMColors.gradientStart.withOpacity(0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.isFromSettings
                              ? 'Update Your Details'
                              : 'Welcome to ITM Connect!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideY(),
                        const SizedBox(height: 8),
                        Text(
                          'Select your role to personalize your experience and receive class notifications.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ).animate().fadeIn(delay: 150.ms).slideY(),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            _buildRoleCard(
                              'Student',
                              Icons.school_rounded,
                              'Enter your batch to get routine',
                              isDark,
                            ),
                            const SizedBox(width: 16),
                            _buildRoleCard(
                              'Teacher',
                              Icons.person_pin_rounded,
                              'Enter your initial to get routine',
                              isDark,
                            ),
                          ],
                        ).animate().fadeIn(delay: 300.ms).scale(),
                        const SizedBox(height: 32),

                        // ── Input Field with Suggestions ──
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            key: ValueKey('${_selectedRole}_input'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _identifierController,
                                focusNode: _identifierFocusNode,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: _selectedRole == 'Student'
                                      ? 'Enter Batch (e.g. 56)'
                                      : 'Enter Initial (e.g. MSI)',
                                  prefixIcon: Icon(
                                    _selectedRole == 'Student'
                                        ? Icons.class_
                                        : Icons.badge,
                                    color: ITMColors.gradientStart,
                                  ),
                                  suffixIcon: _isFetchingSuggestions
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : (_identifierController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear,
                                                  size: 20),
                                              onPressed: () {
                                                _identifierController.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.black12
                                      : Colors.white.withOpacity(0.5),
                                  hintText: _selectedRole == 'Student'
                                      ? 'Type to search available batches...'
                                      : 'Type to search teacher initials...',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black26,
                                    fontSize: 13,
                                  ),
                                ),
                                onTap: () {
                                  _filterSuggestions(
                                      _identifierController.text);
                                },
                              ),

                              // Suggestion dropdown
                              _buildSuggestionDropdown(isDark),

                              // Available count hint
                              if (!_isFetchingSuggestions &&
                                  _allSuggestions.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 6, left: 4),
                                  child: Text(
                                    _selectedRole == 'Student'
                                        ? '${_allSuggestions.length} batches available'
                                        : '${_allSuggestions.length} teachers available',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 450.ms).slideX(),

                        const SizedBox(height: 24),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  // Continue Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _saveAndContinue,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        backgroundColor:
                                            ITMColors.gradientStart,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        widget.isFromSettings
                                            ? 'Save Changes'
                                            : 'Continue',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Skip Button — only on first launch, not from settings
                                  if (!widget.isFromSettings) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton(
                                        onPressed: _skipSetup,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            side: BorderSide(
                                              color: isDark
                                                  ? Colors.white24
                                                  : Colors.black12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Skip for now',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black45,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'You won\'t receive personalized notifications',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ],
                              ).animate().fadeIn(delay: 600.ms).slideY(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
