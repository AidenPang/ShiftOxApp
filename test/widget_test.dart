import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftox/models/schedule_model.dart';

void main() {
  group('ScheduleModel Tests', () {
    test('ScheduleModel should correctly parse multiple shifts and transactions', () {
      final model = ScheduleModel(
        date: '2026-11-09',
        position: '',
        startTime: '',
        endTime: '',
        expenseAmount: 150,
        expenseNote: '[{"title":"午餐","amount":100},{"title":"飲料","amount":50}]',
        incomeAmount: 500,
        incomeNote: '[{"title":"二手書","amount":500}]',
        shiftsNote: '[{"position":"晚班","start_time":"17:00","end_time":"22:00"}]',
      );

      final expenses = model.getExpenseList();
      final incomes = model.getIncomeList();
      final shifts = model.getShiftsList();

      expect(expenses.length, 2);
      expect(expenses[0]['title'], '午餐');
      expect(expenses[0]['amount'], 100);

      expect(incomes.length, 1);
      expect(incomes[0]['title'], '二手書');
      expect(incomes[0]['amount'], 500);

      expect(shifts.length, 1);
      expect(shifts[0]['position'], '晚班');
      expect(shifts[0]['start_time'], '17:00');
      expect(shifts[0]['end_time'], '22:00');
    });

    test('ScheduleModel backward compatibility with legacy single shift', () {
      final legacyModel = ScheduleModel(
        date: '2026-07-08',
        position: '盛飯',
        startTime: '17:00',
        endTime: '22:00',
        shiftsNote: '[]',
      );

      final shifts = legacyModel.getShiftsList();
      expect(shifts.length, 1);
      expect(shifts[0]['position'], '盛飯');
      expect(shifts[0]['start_time'], '17:00');
      expect(shifts[0]['end_time'], '22:00');
    });

    test('Backup Payload JSON validation', () {
      final model = ScheduleModel(
        date: '2026-11-23',
        position: '',
        startTime: '',
        endTime: '',
        expenseAmount: 200,
        expenseNote: '[{"title":"晚餐","amount":200}]',
        incomeAmount: 0,
        incomeNote: '[]',
        shiftsNote: '[{"position":"晚班","start_time":"18:00","end_time":"22:00"}]',
      );

      final backup = {
        'app': 'ShiftOx',
        'version': 1,
        'schedules': [model.toMap()],
        'settings': {'hourly_wage': 200},
        'preferences': {'monthlyTarget': 12000, 'currentCash': 8000},
      };

      final jsonStr = jsonEncode(backup);
      final decoded = jsonDecode(jsonStr);

      expect(decoded['app'], 'ShiftOx');
      expect(decoded['version'], 1);
      expect(decoded['settings']['hourly_wage'], 200);
      expect(decoded['preferences']['monthlyTarget'], 12000);

      final restoredModel = ScheduleModel.fromMap(decoded['schedules'][0]);
      expect(restoredModel.date, '2026-11-23');
      expect(restoredModel.expenseAmount, 200);
      expect(restoredModel.getShiftsList().first['position'], '晚班');
    });
  });
}
