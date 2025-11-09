import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false; // Thêm biến trạng thái loading

  // Data holders
  String? _selectedGoal;
  String? _selectedOccupation;
  double _currentAge = 25;
  String? _selectedGender;

  // Options for choices
  final _goals = ['Du lịch', 'Công việc', 'Giao tiếp hằng ngày', 'Thi cử (IELTS/TOEIC)', 'Khác'];
  final _occupations = ['Học sinh/Sinh viên', 'Nhân viên văn phòng', 'Lập trình viên', 'Kỹ sư', 'Bác sĩ', 'Giáo viên', 'Khác'];
  final _genders = ['Nam', 'Nữ', 'Không muốn tiết lộ'];

  Future<void> _completeOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'hasCompletedOnboarding': true,
        'profile': {
          'learningGoal': _selectedGoal ?? 'General',
          'occupation': _selectedOccupation ?? 'Other',
          'age': _currentAge.round(),
          'gender': _selectedGender ?? 'Prefer not to say',
        },
        'interests': FieldValue.delete(), 
      });
      // Không cần làm gì sau khi thành công, AuthGate/RoleGate sẽ tự điều hướng
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi lưu thông tin: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildSingleChoicePage("Mục tiêu học của bạn là gì?", "Chọn một mục tiêu chính để chúng tôi đề xuất nội dung phù hợp nhất.", _goals, _selectedGoal, (value) => setState(() => _selectedGoal = value)),
                  _buildSingleChoicePage("Nghề nghiệp của bạn là gì?", "Điều này giúp chúng tôi hiểu hơn về ngữ cảnh sử dụng tiếng Anh của bạn.", _occupations, _selectedOccupation, (value) => setState(() => _selectedOccupation = value)),
                  _buildAgeAndGenderPage(),
                ],
              ),
            ),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS FOR PAGES ---

  Widget _buildWelcomePage() {
    return _buildPageContent(
      icon: Icons.flag_rounded,
      title: "Chào mừng tới Engademy!",
      subtitle: "Hãy trả lời một vài câu hỏi để chúng tôi cá nhân hóa lộ trình học cho bạn.",
    );
  }

  Widget _buildSingleChoicePage(String title, String subtitle, List<String> options, String? groupValue, ValueChanged<String?> onChanged) {
    return _buildPageContent(
      title: title,
      subtitle: subtitle,
      content: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: options.map((option) => ChoiceChip(
          label: Text(option),
          selected: groupValue == option,
          onSelected: (selected) => onChanged(option),
        )).toList(),
      ),
    );
  }

  Widget _buildAgeAndGenderPage() {
    return _buildPageContent(
      title: "Một vài thông tin về bạn",
      subtitle: "Các thông tin này sẽ được giữ riêng tư và chỉ dùng cho mục đích đề xuất.",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tuổi của bạn", style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _currentAge,
            min: 13,
            max: 80,
            divisions: 67,
            label: _currentAge.round().toString(),
            onChanged: (double value) => setState(() => _currentAge = value),
          ),
          const SizedBox(height: 32),
          const Text("Giới tính", style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8.0,
            children: _genders.map((gender) => ChoiceChip(
              label: Text(gender),
              selected: _selectedGender == gender,
              onSelected: (selected) => setState(() => _selectedGender = gender),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent({IconData? icon, required String title, required String subtitle, Widget? content}) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        if (icon != null) Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
        if (icon != null) const SizedBox(height: 32),
        Text(title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
        const SizedBox(height: 32),
        if (content != null) content,
      ],
    );
  }
  
  Widget _buildNavigation() {
    final isLastPage = _currentPage == 3;
    final canProceed = (_currentPage == 1 && _selectedGoal != null) || (_currentPage == 2 && _selectedOccupation != null) || (_currentPage == 3 && _selectedGender != null) || _currentPage == 0;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: _currentPage > 0 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: [
          if (_currentPage > 0)
            TextButton(onPressed: _isLoading ? null : () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn), child: const Text("Back")),
          
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: canProceed ? () {
                if (isLastPage) {
                  _completeOnboarding();
                } else {
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                }
              } : null,
              child: Text(isLastPage ? "Hoàn tất" : "Tiếp theo"),
            ),
        ],
      ),
    );
  }
}
