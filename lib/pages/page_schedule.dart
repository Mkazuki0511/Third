import 'package:flutter/material.dart';

// 状態(State)を持つために StatefulWidget に変更します
class Page_schedule extends StatefulWidget {
  const Page_schedule({super.key});

  @override
  State<Page_schedule> createState() => _Page_scheduleState();
}

class _Page_scheduleState extends State<Page_schedule> {
  // 「提供」がtrue、「利用」がfalse
  bool _isProvidingSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // このページにもAppBarはありません
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildToggleButtons(), // 「提供」「利用」のトグルボタン

            // カードリスト
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: 3, // ダミーで3つの予定を表示
                itemBuilder: (context, index) {
                  // index に応じてダミーデータを切り替える
                  return _buildScheduleCard(
                    status: index == 2 ? '完了済み' : '予約確定',
                    date: index == 0 ? '2025年11月13日 19:00~20:00' : (index == 1 ? '2025年11月8日 19:00~20:00' : '2025年9月13日 19:00~20:00'),
                    name: '名前 地域 (年齢)',
                    service: 'プログラミング講座',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 「提供」「利用」のトグルボタン
  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildToggleButton(
            text: '提供',
            isSelected: _isProvidingSelected,
            onPressed: () {
              setState(() {
                _isProvidingSelected = true;
              });
            },
          ),
          const SizedBox(width: 12),
          _buildToggleButton(
            text: '利用',
            isSelected: !_isProvidingSelected,
            onPressed: () {
              setState(() {
                _isProvidingSelected = false;
              });
            },
          ),
        ],
      ),
    );
  }

  /// トグルボタンの共通ウィジェット
  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.cyan : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.cyan,
          side: BorderSide(color: isSelected ? Colors.cyan : Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// 予定カード
  Widget _buildScheduleCard({
    required String status,
    required String date,
    required String name,
    required String service,
  }) {
    // ステータスに応じて色を変更
    final Color statusColor = (status == '予約確定') ? Colors.cyan : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上段：ステータスと日付
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
            const Divider(height: 24.0),

            // 下段：画像と詳細
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左側の画像
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Center(child: Icon(Icons.person, size: 40, color: Colors.white)),
                ),
                const SizedBox(width: 16),

                // 右側の詳細
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ご利用サービス', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            const SizedBox(height: 4),
                            Text(service, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}