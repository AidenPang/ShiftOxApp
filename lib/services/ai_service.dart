import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart'; // 💡 引入 Gemini SDK

class AIService {
  // 🔑 請在此處填入你的 Gemini API Key
  final String _geminiApiKey = "AQ.Ab8RN6LMlbHdmFp6ZfMqJobydkF0ftRT3GES_wrn-Y4msnmdxg"; 

  /// 📸 核心任務：將傳入的圖片 Byte 送給 Gemini，解析出該日期「定」的班表
  Future<List<Map<String, dynamic>>> scanScheduleImage(Uint8List imageBytes, String targetYear) async {
    try {
      // 1. 初始化 Gemini 1.5 Flash 引擎
      final model = GenerativeModel(
        model: 'gemini-3.5-flash', 
        apiKey: _geminiApiKey,
      );

      // 2. 設定專屬「定」字過濾與店內規則 Prompt
      final prompt = '''
你是「牛馬日誌 (ShiftOx)」 App 的專屬 AI 總管。
這張排班表圖片包含了很多店員的班表。

【關鍵任務】
請「只」提取出名字縮寫為「定」的排班數據。其他人的班表請完全忽略。

【日期與年份動態規範（極重要！）】
1. 照片上的日期通常只寫月/日（例如 7/6、7/8）。
2. 請『強制』將年份設定為 $targetYear 年！輸出的 date 欄位必須嚴格為 "$targetYear-MM-DD" 格式（例如 7/8 必須輸出為 "$targetYear-07-08"）。
3. 絕對禁止輸出其他年份！忽略圖片底部關於過年年假的文字，不要被年假文字影響年份判斷！

【店內特有排班規則】
1. 下半部代表晚班，晚班時段預設為 17:00 至 22:00。
2. 班表上如果寫著數字「4」，代表當天是 16:00 上班。
3. 班表上如果寫著數字「-9」，代表當天是 21:00 下班。
4. 如果「定」這一個字下面或旁邊有標註店內職位（如：盛飯、夾菜），請提取出來；若無，請統一填寫「打工班」。

【輸出格式規範】
請你「嚴格」僅回傳一個 JSON 陣列，不要有 markdown 標記（不要寫 ```json），不要有任何前言 or 解釋。
格式必須是 JSON Array，陣列中的每一筆物件欄位如下：
[
  {
    "date": "$targetYear-07-08",     
    "position": "盛飯 (晚班)", 
    "start_time": "17:00",     
    "end_time": "22:00"        
  }
]
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // 3. 呼叫 API 並取得回應
      final response = await model.generateContent(content);
      final String? jsonResult = response.text;

      if (jsonResult == null || jsonResult.isEmpty) {
        throw Exception("Gemini 回傳了空的結果");
      }

      // 4. 清理 Markdown 標記並解析為 List
      String cleanJson = jsonResult.replaceAll('```json', '').replaceAll('```', '').trim();
      List<dynamic> parsedList = jsonDecode(cleanJson);

      return parsedList.map((item) => Map<String, dynamic>.from(item)).toList();
    } on GenerativeAIException catch (e) {
      // 💡 捕捉 Gemini 專屬的錯誤，提供更詳細的除錯資訊
      throw Exception(" ${e.message}");
    } catch (e) {
      // 捕捉其他一般性錯誤 (如網路問題、JSON 解析失敗等)
      throw Exception("AI 服務發生非預期異常: $e");
    }
  }
}