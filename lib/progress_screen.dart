import 'package:flutter/material.dart';
import 'services/analytics_service.dart';
import 'diagnosis_report.dart';
import 'colours.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with WidgetsBindingObserver {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  int _streak = 0;
  List<DayData> _weeklyStats = [];
  String? _diagnosis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible (e.g., navigating back to this tab)
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final streak = await _analyticsService.getStreak();
      final stats = await _analyticsService.getWeeklyStats();
      final diagnosis = await _analyticsService.getUserDiagnosis();
      
      if (mounted) {
        setState(() {
          _streak = streak;
          _weeklyStats = stats;
          _diagnosis = diagnosis;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: light,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: dark))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: dark,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // View Initial Assessment Report Button
                      _buildReportButton(),
                      const SizedBox(height: 24),
                      
                      // Streak Display
                      _buildStreakCard(),
                      const SizedBox(height: 24),
                      
                      // Time Spent Chart
                      _buildChartCard(
                        title: 'Time spent doing exercises',
                        child: _buildTimeChart(),
                      ),
                      const SizedBox(height: 20),
                      
                      // Accuracy Chart
                      _buildChartCard(
                        title: 'Exercise accuracy',
                        child: _buildAccuracyChart(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildReportButton() {
    return GestureDetector(
      onTap: () {
        if (_diagnosis != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiagnosisReport(diagnosis: _diagnosis!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No assessment report available')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dark.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: light,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.description_outlined, color: dark, size: 24),
            ),
            const SizedBox(width: 14),
            Text(
              'View Initial Assessment Report',
              style: TextStyle(
                color: dark,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: dark.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fire emoji/icon
        Image.asset(
          'assets/fire.png',
          width: 70,
          height: 70,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.shade300,
                  Colors.orange.shade600,
                  Colors.red.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(35),
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_streak',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: dark,
              ),
            ),
            Text(
              'day streak!',
              style: TextStyle(
                fontSize: 18,
                color: dark.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Title pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: dark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTimeChart() {
    if (_weeklyStats.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No data yet')),
      );
    }

    // Find max value for scaling
    final maxTime = _weeklyStats.fold<int>(
      1,
      (max, stat) => stat.time > max ? stat.time : max,
    );

    return SizedBox(
      height: 150,
      child: Column(
        children: [
          // Y-axis labels and chart
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$maxTime', style: _axisLabelStyle),
                      Text('${(maxTime * 0.5).round()}', style: _axisLabelStyle),
                      Text('0', style: _axisLabelStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chart area
                Expanded(
                  child: CustomPaint(
                    painter: _LineChartPainter(
                      data: _weeklyStats.map((s) => s.time.toDouble()).toList(),
                      maxValue: maxTime.toDouble(),
                      lineColor: dark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels (days)
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weeklyStats.map((stat) {
                return Text(
                  _getDayLabel(stat.date),
                  style: _axisLabelStyle,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyChart() {
    if (_weeklyStats.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No data yet')),
      );
    }

    return SizedBox(
      height: 150,
      child: Column(
        children: [
          // Y-axis labels and chart
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis labels
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('100', style: _axisLabelStyle),
                      Text('50', style: _axisLabelStyle),
                      Text('0', style: _axisLabelStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chart area
                Expanded(
                  child: CustomPaint(
                    painter: _LineChartPainter(
                      data: _weeklyStats.map((s) => s.accuracy).toList(),
                      maxValue: 100,
                      lineColor: const Color(0xFF4ECDC4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels (days)
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weeklyStats.map((stat) {
                return Text(
                  _getDayLabel(stat.date),
                  style: _axisLabelStyle,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _axisLabelStyle => TextStyle(
    fontSize: 9,
    color: dark.withOpacity(0.5),
  );

  String _getDayLabel(DateTime date) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[date.weekday - 1];
  }
}

/// Custom painter for line charts
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  final Color lineColor;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 0; i <= 2; i++) {
      final y = size.height * (i / 2);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculate points
    final points = <Offset>[];
    final stepX = size.width / (data.length - 1).clamp(1, data.length);
    
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = maxValue > 0 ? data[i] / maxValue : 0;
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y.clamp(0, size.height)));
    }

    // Draw line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(
        point,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.maxValue != maxValue ||
           oldDelegate.lineColor != lineColor;
  }
}
