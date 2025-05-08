import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/activity_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ActivityProvider>(context, listen: false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Activity Analysis"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  const SizedBox(height: 10),
                  _buildTabSelector(),
                  const SizedBox(height: 20),
                  _buildStatsSection(provider),
                  const SizedBox(height: 20),
                  _buildAchievements(provider),
                  const SizedBox(height: 20),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActivities(provider, days: 1),
                        _buildActivities(provider, days: 7),
                        _buildActivities(provider),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFE5EAF1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: DefaultTabController(
          length: 3,
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              dividerColor: Colors.transparent,
              tabBarTheme: const TabBarTheme(
                dividerColor: Colors.transparent,
                overlayColor: MaterialStatePropertyAll(Colors.transparent),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(30),
              ),
              indicatorColor: Colors.transparent,
              indicatorWeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorPadding: const EdgeInsets.all(6),
              tabs: const [
                Tab(child: Center(child: Text("Today"))),
                Tab(child: Center(child: Text("7 Days"))),
                Tab(child: Center(child: Text("All"))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(ActivityProvider provider) {
    int? days;
    if (_tabController.index == 0) {
      days = 1;
    } else if (_tabController.index == 1) {
      days = 7;
    } else {
      days = null;
    }

    final activities =
        days != null
            ? provider.recentActivities
                .where(
                  (a) => a.timestamp.isAfter(
                    DateTime.now().subtract(Duration(days: days ?? 0)),
                  ),
                )
                .toList()
            : provider.recentActivities;

    final distance = provider.getDistanceForPeriod(days: days);
    final rating = provider.getDrivingRating(days: days);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showDistanceGraph(context, activities, days),
              child: _buildStatCard(
                "${distance.toStringAsFixed(1)} km",
                "Distance",
                Colors.grey[300]!,
                0.0,
                description: "Total distance you've driven",
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => _showRatingGraph(context, activities, days),
              child: _buildStatCard(
                rating,
                "Rating",
                _ratingColor(rating),
                _ratingPercent(rating),
                description: "Your recent driving behavior",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String center,
    String label,
    Color color,
    double percent, {
    String? description, // الوصف الإضافي
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 50,
            lineWidth: 10,
            percent: percent,
            center: Text(
              center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.grey[200]!,
            progressColor: color,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (description != null)
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  void _showDistanceGraph(
    BuildContext context,
    List<Activity>? activities,
    int? days,
  ) {
    final activityList = activities ?? [];
    String timePeriod;
    if (days == 1) {
      timePeriod = "Today";
    } else if (days == 7) {
      timePeriod = "Last 7 Days";
    } else {
      timePeriod = "All Time";
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Distance Graph",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, __, ___) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF6F7F9), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [Colors.blue, Colors.lightBlueAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                        child: const Text(
                          "Speed Over Time (km/h)",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("🚀", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timePeriod,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: Stack(
                      children: [
                        BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipPadding: const EdgeInsets.all(8),
                                tooltipMargin: 8,
                                getTooltipColor:
                                    (group) =>
                                        Colors.blueAccent.withOpacity(0.8),
                                getTooltipItem: (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) {
                                  return BarTooltipItem(
                                    '${rod.toY.toInt()} km/h',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            barGroups:
                                activityList.isEmpty
                                    ? [
                                      BarChartGroupData(
                                        x: 0,
                                        barRods: [
                                          BarChartRodData(
                                            toY: 0.0,
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.blue,
                                                Colors.lightBlueAccent,
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                            width: 20,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            backDrawRodData:
                                                BackgroundBarChartRodData(
                                                  show: true,
                                                  toY: 100,
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ]
                                    : activityList.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final activity = entry.value;
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: activity.speed ?? 0.0,
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.blue,
                                                Colors.lightBlueAccent,
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                            width: 20,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            backDrawRodData:
                                                BackgroundBarChartRodData(
                                                  show: true,
                                                  toY:
                                                      (activityList
                                                              .map(
                                                                (a) =>
                                                                    a.speed ??
                                                                    0.0,
                                                              )
                                                              .reduce(
                                                                (a, b) =>
                                                                    a > b
                                                                        ? a
                                                                        : b,
                                                              ) *
                                                          1.2),
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            offset: const Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    if (activityList.isEmpty) {
                                      return const Text(
                                        'No Data',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      );
                                    }
                                    if (value.toInt() < activityList.length) {
                                      return Text(
                                        DateFormat('h:mm a').format(
                                          activityList[value.toInt()].timestamp,
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              offset: const Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: false,
                              horizontalInterval: 20,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                );
                              },
                            ),
                          ),
                        ),
                        if (activityList.isEmpty)
                          const Center(
                            child: Text(
                              "No speed data available",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    color: Colors.black12,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRatingGraph(
    BuildContext context,
    List<Activity>? activities,
    int? days,
  ) {
    final activityList = activities ?? [];
    String timePeriod;
    if (days == 1) {
      timePeriod = "Today";
    } else if (days == 7) {
      timePeriod = "Last 7 Days";
    } else {
      timePeriod = "All Time";
    }

    final ratingCounts = {"Dangerous": 0, "Normal": 0, "Excellent": 0};

    for (var activity in activityList) {
      final rating = activity.rating ?? "Excellent";
      ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Rating Graph",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, __, ___) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: EdgeInsets.zero,
            content: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF6F7F9), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback:
                            (bounds) => const LinearGradient(
                              colors: [Colors.green, Colors.lightGreenAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                        child: const Text(
                          "Rating Distribution",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text("🌟", style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timePeriod,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: Stack(
                      children: [
                        BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipPadding: const EdgeInsets.all(8),
                                tooltipMargin: 8,
                                getTooltipColor:
                                    (group) => Colors.green.withOpacity(0.8),
                                getTooltipItem: (
                                  group,
                                  groupIndex,
                                  rod,
                                  rodIndex,
                                ) {
                                  String rating = '';
                                  switch (group.x) {
                                    case 0:
                                      rating = 'Dangerous';
                                      break;
                                    case 1:
                                      rating = 'Normal';
                                      break;
                                    case 2:
                                      rating = 'Excellent';
                                      break;
                                  }
                                  return BarTooltipItem(
                                    '$rating: ${rod.toY.toInt()}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: ratingCounts["Dangerous"]!.toDouble(),
                                    gradient: const LinearGradient(
                                      colors: [Colors.red, Colors.redAccent],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(8),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY:
                                          (ratingCounts.values.reduce(
                                                (a, b) => a > b ? a : b,
                                              ) *
                                              1.2),
                                      color: Colors.grey.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: ratingCounts["Normal"]!.toDouble(),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.orange,
                                        Colors.orangeAccent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(8),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY:
                                          (ratingCounts.values.reduce(
                                                (a, b) => a > b ? a : b,
                                              ) *
                                              1.2),
                                      color: Colors.grey.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 2,
                                barRods: [
                                  BarChartRodData(
                                    toY: ratingCounts["Excellent"]!.toDouble(),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.green,
                                        Colors.lightGreenAccent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(8),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY:
                                          (ratingCounts.values.reduce(
                                                (a, b) => a > b ? a : b,
                                              ) *
                                              1.2),
                                      color: Colors.grey.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            offset: const Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    switch (value.toInt()) {
                                      case 0:
                                        return Text(
                                          "Dangerous",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                offset: const Offset(1, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        );
                                      case 1:
                                        return Text(
                                          "Normal",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                offset: const Offset(1, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        );
                                      case 2:
                                        return Text(
                                          "Excellent",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                offset: const Offset(1, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        );
                                      default:
                                        return const Text('');
                                    }
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey.withOpacity(0.2),
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                );
                              },
                            ),
                          ),
                        ),
                        if (activityList.isEmpty)
                          const Center(
                            child: Text(
                              "No rating data available",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    color: Colors.black12,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievements(ActivityProvider provider) {
    final distance = provider.distanceTraveled;
    final activities = provider.recentActivities;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Achievements",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showGeneralDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "About Achievements",
                    transitionDuration: const Duration(milliseconds: 250),
                    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
                    transitionBuilder: (_, anim, __, ___) {
                      return ScaleTransition(
                        scale: CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutBack,
                        ),
                        child: AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          title: const Center(
                            child: Text(
                              "About Achievements",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 60,
                                color: Colors.lightBlue,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Achievements reward your safe driving habits. Earn trophies for milestones like distance traveled or accident-free days. Tap on each trophy to see more details!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          actionsPadding: const EdgeInsets.only(bottom: 12),
                          actions: [
                            Center(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  "OK",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.lightBlue.withAlpha((0.2 * 255).round()),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.lightBlue,
                    semanticLabel: "Learn more about achievements",
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTrophy("Safe Driver:\n100 km", distance >= 100),
                const SizedBox(width: 16),
                _buildTrophy("Safe Driver:\n500 km", distance >= 500),
                const SizedBox(width: 16),
                _buildTrophy("Safe Driver:\n1000 km", distance >= 1000),
                const SizedBox(width: 16),
                _buildTrophy("Safe Driver:\n2000 km", distance >= 2000),
                const SizedBox(width: 16),
                _buildTrophy(
                  "7 Days\nNo Accident",
                  _noAccidentFor(activities, 7),
                ),
                const SizedBox(width: 16),
                _buildTrophy(
                  "14 Days\nNo Accident",
                  _noAccidentFor(activities, 14),
                ),
                const SizedBox(width: 16),
                _buildTrophy(
                  "Safe Speed:\n100 km",
                  provider.badges.contains("Safe Speed: 100 km"),
                ),
                const SizedBox(width: 16),
                _buildTrophy(
                  "City\nExplorer",
                  provider.badges.contains("City Explorer"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophy(String label, bool unlocked) {
    return GestureDetector(
      onTap: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: "Achievement",
          transitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => const SizedBox.shrink(),
          transitionBuilder: (_, anim, __, ___) {
            return ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: const Center(
                  child: Text(
                    "Achievement Details",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectAchievementIcon(label),
                      size: 80,
                      color: unlocked ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label.replaceAll("\n", " "),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _achievementDescription(label),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.only(bottom: 12),
                actions: [
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "OK",
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Column(
        children: [
          Icon(
            _selectAchievementIcon(label),
            size: 36,
            color: unlocked ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  IconData _selectAchievementIcon(String label) {
    if (label == "City\nExplorer") {
      return Icons.location_city;
    }
    return Icons.emoji_events;
  }

  String _achievementDescription(String label) {
    switch (label) {
      case "Safe Driver:\n100 km":
        return "Awarded for driving 100 km without any accidents.";
      case "Safe Driver:\n500 km":
        return "Awarded for driving 500 km without any accidents.";
      case "Safe Driver:\n1000 km":
        return "Awarded for driving 1000 km without any accidents.";
      case "Safe Driver:\n2000 km":
        return "Awarded for driving 2000 km without any accidents.";
      case "7 Days\nNo Accident":
        return "No accidents recorded for 7 consecutive days.";
      case "14 Days\nNo Accident":
        return "No accidents recorded for 14 consecutive days.";
      case "Safe Speed:\n100 km":
        return "Maintained a safe speed for 100 km of driving.";
      case "City\nExplorer":
        return "Completed 100 trips inside a city.";
      default:
        return "Achievement unlocked!";
    }
  }

  Widget _buildActivities(ActivityProvider provider, {int? days}) {
    final activities =
        days != null
            ? provider.recentActivities
                .where(
                  (a) => a.timestamp.isAfter(
                    DateTime.now().subtract(Duration(days: days ?? 0)),
                  ),
                )
                .toList()
            : provider.recentActivities;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Activities",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  activities.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 72,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "No activities",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(0),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final a = activities[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: Icon(
                                a.type == 'accident'
                                    ? Icons.warning_amber_rounded
                                    : Icons.history,
                                color:
                                    a.type == 'accident'
                                        ? Colors.red
                                        : Colors.blueGrey,
                              ),
                              title: Text(a.description),
                              subtitle: Text(
                                DateFormat('MMM d, h:mm a').format(a.timestamp),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => Provider.of<ActivityProvider>(
                                      context,
                                      listen: false,
                                    ).removeActivity(a.id),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  bool _noAccidentFor(List<Activity> activities, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return activities
        .where((a) => a.timestamp.isAfter(cutoff))
        .every((a) => a.type != 'accident');
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case "Dangerous":
        return Colors.red;
      case "Normal":
        return Colors.orange;
      case "Excellent":
      default:
        return Colors.green;
    }
  }

  double _ratingPercent(String rating) {
    switch (rating) {
      case "Dangerous":
        return 0.3;
      case "Normal":
        return 0.6;
      case "Excellent":
      default:
        return 1.0;
    }
  }
}
