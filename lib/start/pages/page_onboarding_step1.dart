import 'package:flutter/material.dart';
// import 'page_onboarding_step2.dart'; // ← 次のステップで作成するパスワード入力ページ

class Page_onboarding_step1 extends StatefulWidget {
  const Page_onboarding_step1({super.key});

  @override
  State<Page_onboarding_step1> createState() => _Page_onboarding_step1State();
}

class _Page_onboarding_step1State extends State<Page_onboarding_step1> {
  // フォームの入力値を管理するための変数
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthday;
  String? _selectedLocation;
  bool _is18OrOlder = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // 「withをはじめる」ボタンが押されたときの処理
  void _goToNextStep() {
    // 【フェーズ4.3】
    // ここで、入力された情報（_nicknameController.text など）を
    // 次の「パスワード入力ページ」に渡して遷移します

    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => Page_onboarding_step2(
    //     nickname: _nicknameController.text,
    //     email: _emailController.text,
    //     // ... 他のデータも渡す
    //   ),
    // ));
    print("次のステップ（パスワード入力）へ");
  }

  // 生年月日ピッカーを表示する
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ボタンが押せるかどうかを判定
    final bool isButtonEnabled = _is18OrOlder && _agreedToTerms;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // (Navigator.pushで遷移すると自動で戻るボタンが表示されます)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. ヘッダー (ロゴ) ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/skill_link_logo.png', // あなたのロゴ
                    height: 30, // 高さを調整
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'へようこそ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // --- 2. フォーム ---
            _buildTextField(
              controller: _nicknameController,
              label: 'ニックネーム',
              hint: 'ニックネームを入力', // ヒント
            ),
            _buildSelectorField(
              label: '性別',
              value: _selectedGender ?? '男性', // ダミー
              onTap: () {
                // TODO: 性別選択のDropdown
                print("性別を選択");
              },
            ),
            _buildSelectorField(
              label: '生年月日',
              value: _selectedBirthday == null
                  ? '2000年 01月 01日'
                  : '${_selectedBirthday!.year}年 ${_selectedBirthday!.month}月 ${_selectedBirthday!.day}日',
              onTap: () => _selectDate(context), // DatePickerを呼び出す
            ),
            _buildSelectorField(
              label: '居住地',
              value: _selectedLocation ?? '東京', // ダミー
              onTap: () {
                // TODO: 居住地選択
                print("居住地を選択");
              },
            ),
            _buildTextField(
              controller: _emailController,
              label: 'メールアドレス',
              hint: 'メールアドレスを入力',
            ),
            const SizedBox(height: 24),

            // --- 3. 同意チェックボックス ---
            _buildCheckbox(
              title: '私は18歳以上で独身です。',
              value: _is18OrOlder,
              onChanged: (bool? newValue) {
                setState(() {
                  _is18OrOlder = newValue!;
                });
              },
            ),
            _buildCheckbox(
              title: 'SKILL LINKの利用規約・プライバシーポリシー・コミュニティガイドラインの内容を確認のうえ、同意します。',
              value: _agreedToTerms,
              onChanged: (bool? newValue) {
                setState(() {
                  _agreedToTerms = newValue!;
                });
              },
            ),
            const SizedBox(height: 24),

            // --- 4. 登録ボタン ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                // isButtonEnabled が false の場合、ボタンは自動で無効化(null)される
                disabledBackgroundColor: Colors.grey[300],
              ),
              onPressed: isButtonEnabled ? _goToNextStep : null,
              child: const Text(
                'SKILL LINK をはじめる',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40), // 画面下部の余白
          ],
        ),
      ),
    );
  }

  /// ニックネーム、メール用のカスタムテキストフィールド
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            // 下線のみ
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyan),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 性別、生年月日、居住地用のカスタム選択フィールド
  Widget _buildSelectorField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 16)),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 同意用のカスタムチェックボックス
  Widget _buildCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading, // チェックボックスを左側に
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.cyan,
    );
  }
}