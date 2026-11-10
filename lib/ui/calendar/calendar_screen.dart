import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:narwhal/ui/calendar/calendar_view_model.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/ui/calendar/components/strategy_goals_bar.dart';
import 'package:narwhal/ui/calendar/components/week_agenda.dart';
import 'package:narwhal/ui/calendar/components/day_details_bottom_sheet.dart';
import 'package:narwhal/ui/calendar/components/calendar_day_cell.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CalendarViewModel(context.read<TaskNodeRepository>()),
      child: Consumer<CalendarViewModel>(
        builder: (context, viewModel, child) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Strategy & Calendar'),
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Month'),
                    Tab(text: 'Week'),
                  ],
                ),
              ),
              body: Column(
                children: [
                  StrategyGoalsBar(viewModel: viewModel),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMonthCalendar(context, viewModel),
                        WeekAgenda(viewModel: viewModel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthCalendar(BuildContext context, CalendarViewModel viewModel) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: viewModel.focusedDay,
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) => isSameDay(viewModel.selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        viewModel.onDaySelected(selectedDay, focusedDay);
        showDayDetailsBottomSheet(context, viewModel, selectedDay);
      },
      rowHeight: 80, // Taller cells for stats
      onPageChanged: (focusedDay) {
        viewModel.onMonthChanged(focusedDay);
      },
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return CalendarDayCell(viewModel: viewModel, day: day);
        },
        todayBuilder: (context, day, focusedDay) {
          return CalendarDayCell(viewModel: viewModel, day: day, isToday: true);
        },
        outsideBuilder: (context, day, focusedDay) {
          return CalendarDayCell(viewModel: viewModel, day: day, isOutside: true);
        },
      ),
    );
  }
}
