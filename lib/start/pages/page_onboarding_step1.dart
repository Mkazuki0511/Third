import 'package:flutter/material.dart';
import 'page_onboarding_step2.dart'; // パスワード入力ページ

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
  bool _agreedToTerms = false;

  // 47都道府県のリスト
  final List<String> _prefectures = [
    '北海道', '青森県', '岩手県', '宮城県', '秋田県', '山形県', '福島県',
    '茨城県', '栃木県', '群馬県', '埼玉県', '千葉県', '東京都', '神奈川県',
    '新潟県', '富山県', '石川県', '福井県', '山梨県', '長野県', '岐阜県',
    '静岡県', '愛知県', '三重県', '滋賀県', '京都府', '大阪府', '兵庫県',
    '奈良県', '和歌山県', '鳥取県', '島根県', '岡山県', '広島県', '山口県',
    '徳島県', '香川県', '愛媛県', '高知県', '福岡県', '佐賀県', '長崎県',
    '熊本県', '大分県', '宮崎県', '鹿児島県', '沖縄県'
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => Page_onboarding_step2(
        nickname: _nicknameController.text,
        email: _emailController.text,
        gender: _selectedGender,
        birthday: _selectedBirthday,
        location: _selectedLocation,
       ),
     ));
    print("次のステップ（パスワード入力）へ");
  }

  // 生年月日ピッカー
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

  // 性別選択ダイアログ
  Future<void> _showGenderDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('性別を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 高さを最小に
            children: [
              // 「男性」を選択するタイル
              ListTile(
                title: const Text('男性'),
                onTap: () {
                  setState(() {
                    _selectedGender = '男性';
                  });
                  Navigator.of(dialogContext).pop(); // ダイアログを閉じる
                },
              ),
              // 「女性」を選択するタイル
              ListTile(
                title: const Text('女性'),
                onTap: () {
                  setState(() {
                    _selectedGender = '女性';
                  });
                  Navigator.of(dialogContext).pop(); // ダイアログを閉じる
                },
              ),
              // TODO: 必要に応じて「その他」や「回答しない」も追加できます
            ],
          ),
        );
      },
    );
  }

  /// --- 居住地選択ダイアログを表示するロジック ---
  Future<void> _showLocationDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('居住地を選択'),
          // content が長くなるので、SizedBox で高さを指定し、スクロール可能にする
          content: SizedBox(
            width: double.maxFinite, // 横幅を最大に
            height: 300, // 高さを300に固定（お好みで調整）
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _prefectures.length, // 47都道府県のリスト
              itemBuilder: (BuildContext context, int index) {
                final prefecture = _prefectures[index];
                return ListTile(
                  title: Text(prefecture),
                  onTap: () {
                    setState(() {
                      _selectedLocation = prefecture; // 選択した都道府県を保存
                    });
                    Navigator.of(dialogContext).pop(); // ダイアログを閉じる
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // ボタンが押せるかどうかを判定
    final bool isButtonEnabled = _agreedToTerms;

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

            // 性別選択ができるように修正
            _buildSelectorField(
              label: '性別',
              value: _selectedGender ?? '選択してください', // ← 選択された値を表示
              onTap: _showGenderDialog,
            ),

            _buildSelectorField(
              label: '生年月日',
              value: _selectedBirthday == null
                  ? '2000年 01月 01日'
                  : '${_selectedBirthday!.year}年 ${_selectedBirthday!.month}月 ${_selectedBirthday!.day}日',
              onTap: () => _selectDate(context), // DatePickerを呼び出す
            ),

            // 居住地が選択できるように修正
            _buildSelectorField(
              label: '居住地',
              value: _selectedLocation ?? '選択してください', // 選択された値を表示
              onTap: _showLocationDialog,
            ),


            _buildTextField(
              controller: _emailController,
              label: 'メールアドレス',
              hint: 'メールアドレスを入力',
            ),
            const SizedBox(height: 24),

            // --- 3. 同意チェックボックス ---
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
                '同意して次へ',
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