import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/patient_mood.dart';

enum DateRange { last7Days, last30Days, last3Months, allTime }

class MoodChartData {
  final String mood;
  final int count;
  final Color color;

  MoodChartData({
    required this.mood,
    required this.count,
    required this.color,
  });
}

class MoodAnalyticsChart extends StatefulWidget {
  final Function(String)? onMoodSelected;

  const MoodAnalyticsChart({super.key, this.onMoodSelected});

  @override
  State<MoodAnalyticsChart> createState() => _MoodAnalyticsChartState();
}

class _MoodAnalyticsChartState extends State<MoodAnalyticsChart> {
  DateRange _selectedRange = DateRange.last30Days;
  List<PatientMood> _moodData = [];
  bool _isLoading = true;
  String? _error;
  String? _mostLoggedMood;
  int _totalEntries = 0;

  final Map<String, Color> _moodColors = {
    'Happy': const Color(0xFFFFD700),
    'Sad': const Color(0xFF4169E1),
    'Anxious': const Color(0xFFFF6347),
    'Calm': const Color(0xFF32CD32),
    'Excited': const Color(0xFFFF69B4),
    'Angry': const Color(0xFFDC143C),
    'Tired': const Color(0xFF808080),
    'Content': const Color(0xFF00CED1),
    'Frustrated': const Color(0xFFFF4500),
    'Peaceful': const Color(0xFF98FB98),
  };

  @override
  void initState() {
    super.initState();
    _fetchMoodData();
  }

  Future<void> _fetchMoodData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      DateTime startDate;
      final now = DateTime.now();

      switch (_selectedRange) {
        case DateRange.last7Days:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case DateRange.last30Days:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case DateRange.last3Months:
          startDate = now.subtract(const Duration(days: 90));
          break;
        case DateRange.allTime:
          startDate = DateTime(2000); // Far past date
          break;
      }

      final response = await Supabase.instance.client
          .from('patient_mood')
          .select('''
            id,
            mood_id,
            logged_at,
            user_id,
            description,
            mood:mood_id!inner (
              id,
              name,
              description
            )
          ''')
          .eq('user_id', user.id)
          .not('mood_id', 'is', null)
          .not('logged_at', 'is', null)
          .gte('logged_at', startDate.toIso8601String())
          .order('logged_at', ascending: false);

      final moods = (response as List<dynamic>)
          .map((json) => PatientMood.fromJson(json))
          .toList();

      // Count mood frequencies
      final moodCounts = <String, int>{};
      for (final moodEntry in moods) {
        final moodName = moodEntry.mood?.name ?? 'Unknown';
        moodCounts[moodName] = (moodCounts[moodName] ?? 0) + 1;
      }

      // Find most logged mood
      String? mostLogged;
      int maxCount = 0;
      moodCounts.forEach((mood, count) {
        if (count > maxCount) {
          maxCount = count;
          mostLogged = mood;
        }
      });

      setState(() {
        _moodData = moods;
        _totalEntries = moods.length;
        _mostLoggedMood = mostLogged;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch mood data: $e';
        _isLoading = false;
      });
    }
  }

  void _onRangeChanged(DateRange? range) {
    if (range != null && range != _selectedRange) {
      setState(() {
        _selectedRange = range;
      });
      _fetchMoodData();
    }
  }

  void _onBarTapped(String moodName) {
    widget.onMoodSelected?.call(moodName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filtering memories by $moodName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMoodData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Calculate mood counts for chart
    final moodCounts = <String, int>{};
    for (final moodEntry in _moodData) {
      final moodName = moodEntry.mood?.name ?? 'Unknown';
      moodCounts[moodName] = (moodCounts[moodName] ?? 0) + 1;
    }

    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Time Range',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<DateRange>(
                    segments: const [
                      ButtonSegment(
                        value: DateRange.last7Days,
                        label: Text('7 Days'),
                      ),
                      ButtonSegment(
                        value: DateRange.last30Days,
                        label: Text('30 Days'),
                      ),
                      ButtonSegment(
                        value: DateRange.last3Months,
                        label: Text('3 Months'),
                      ),
                      ButtonSegment(
                        value: DateRange.allTime,
                        label: Text('All Time'),
                      ),
                    ],
                    selected: {_selectedRange},
                    onSelectionChanged: (Set<DateRange> selected) {
                      _onRangeChanged(selected.first);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Total entries and most logged mood
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Entries: $_totalEntries',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                if (_mostLoggedMood != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _moodColors[_mostLoggedMood] ?? Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Most Logged: $_mostLoggedMood',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(fontSize: 10),
                  majorGridLines: const MajorGridLines(width: 0),
                  labelRotation: -45,
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: const TextStyle(fontSize: 12),
                  majorGridLines: const MajorGridLines(width: 0),
                  minimum: 0,
                  maximum: sortedMoods.isNotEmpty
                      ? sortedMoods.first.value.toDouble() + 2
                      : 10,
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  color: Colors.blueGrey,
                  textStyle: const TextStyle(color: Colors.white),
                  builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                    final moodData = data as MoodChartData;
                    return Container(
                      padding: const EdgeInsets.all(8),
                      child: Text('${moodData.mood}\n${moodData.count} entries'),
                    );
                  },
                ),
                series: <CartesianSeries<MoodChartData, String>>[
                  ColumnSeries<MoodChartData, String>(
                    dataSource: sortedMoods.map((entry) {
                      return MoodChartData(
                        mood: entry.key,
                        count: entry.value,
                        color: _moodColors[entry.key] ?? Colors.grey,
                      );
                    }).toList(),
                    xValueMapper: (MoodChartData data, _) => data.mood,
                    yValueMapper: (MoodChartData data, _) => data.count,
                    pointColorMapper: (MoodChartData data, _) => data.color,
                    width: 0.6,
                    borderRadius: BorderRadius.circular(4),
                    onPointTap: (ChartPointDetails details) {
                      if (details.pointIndex != null && details.pointIndex! < sortedMoods.length) {
                        _onBarTapped(sortedMoods[details.pointIndex!].key);
                      }
                    },
                    animationDuration: 800,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          if (sortedMoods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedMoods.take(6).map((entry) {
                  final color = _moodColors[entry.key] ?? Colors.grey;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${entry.key} (${entry.value})'),
                    ],
                  );
                }).toList(),
              ),
            ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}