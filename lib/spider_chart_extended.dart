library spider_chart_extended;

import 'package:flutter/material.dart';
import 'dart:math' show pi, cos, sin;

import 'dart:math' as math;

const defaultGraphColors = [
  Color(0xffE95E92),
  Colors.blue,
  Colors.red,
  Colors.orange,
];

class SpiderChart extends StatefulWidget {
  final List<Color> tickColor;
  final List<int> ticks;
  final List<String> features;
  final List<List<num>> data;
  final bool reverseAxis;
  final TextStyle ticksTextStyle;
  final TextStyle featuresTextStyle;
  final Color outlineColor;
  final Color axisColor;
  final List<Color> graphColors;
  final int sides;

  const SpiderChart({
    Key? key,
    required this.tickColor,
    required this.ticks,
    required this.features,
    required this.data,
    this.reverseAxis = false,
    this.ticksTextStyle = const TextStyle(color: Colors.grey, fontSize: 12),
    this.featuresTextStyle = const TextStyle(color: Colors.black, fontSize: 16),
    this.outlineColor = Colors.black,
    this.axisColor = Colors.grey,
    this.graphColors = defaultGraphColors,
    this.sides = 0,
  }) : super(key: key);

  @override
  _SpiderChartState createState() => _SpiderChartState();
}

class _SpiderChartState extends State<SpiderChart>
    with SingleTickerProviderStateMixin {
  double fraction = 0;
  late Animation<double> animation;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      parent: animationController,
    ))
      ..addListener(() {
        setState(() {
          fraction = animation.value;
        });
      });

    animationController.forward();
  }

  @override
  void didUpdateWidget(SpiderChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    animationController.reset();
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: SpiderChartPainter(
          widget.tickColor,
          widget.ticks,
          widget.features,
          widget.data,
          widget.reverseAxis,
          widget.ticksTextStyle,
          widget.featuresTextStyle,
          widget.outlineColor,
          widget.axisColor,
          widget.graphColors,
          widget.sides,
          fraction),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}

class SpiderChartPainter extends CustomPainter {
  final List<Color> tickColor;
  final List<int> ticks;
  final List<String> features;
  final List<List<num>> data;
  final bool reverseAxis;
  final TextStyle ticksTextStyle;
  final TextStyle featuresTextStyle;
  final Color outlineColor;
  final Color axisColor;
  final List<Color> graphColors;
  final int sides;
  final double fraction;

  SpiderChartPainter(
    this.tickColor,
    this.ticks,
    this.features,
    this.data,
    this.reverseAxis,
    this.ticksTextStyle,
    this.featuresTextStyle,
    this.outlineColor,
    this.axisColor,
    this.graphColors,
    this.sides,
    this.fraction,
  );

  Path variablePath(Size size, double radius, int sides) {
    var path = Path();
    var angle = (math.pi * 2) / sides;

    Offset center = Offset(size.width / 2, size.height / 2);

    if (sides < 3) {
      // Draw a circle
      path.addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: radius,
      ));
    } else {
      // Draw a polygon
      Offset startPoint = Offset(radius * cos(-pi / 2), radius * sin(-pi / 2));

      path.moveTo(startPoint.dx + center.dx, startPoint.dy + center.dy);

      for (int i = 1; i <= sides; i++) {
        double x = radius * cos(angle * i - pi / 2) + center.dx;
        double y = radius * sin(angle * i - pi / 2) + center.dy;
        path.lineTo(x, y);
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2.0;
    final centerY = size.height / 2.0;
    final centerOffset = Offset(centerX, centerY);
    final radius = math.min(centerX, centerY) * 1;
    final scale = radius / ticks.last;

    var ticksPaint = Paint()
      ..color = axisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    // canvas.drawPath(variablePath(size, radius, this.sides), outlinePaint);
    // Painting the circles and labels for the given ticks (could be auto-generated)
    // The last tick is ignored, since it overlaps with the feature label
    var tickDistance = radius / (ticks.length);
    var tickLabels = reverseAxis ? ticks.reversed.toList() : ticks;

    if (reverseAxis) {
      TextPainter(
        text: TextSpan(text: tickLabels[0].toString(), style: ticksTextStyle),
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(canvas, Offset(centerX, centerY - ticksTextStyle.fontSize!));
    }

    tickLabels
        .sublist(
            reverseAxis ? 1 : 0, reverseAxis ? ticks.length : ticks.length - 1)
        .asMap()
        .forEach((index, tick) {
      var tickRadius = tickDistance * (index + 1);

      canvas.drawPath(variablePath(size, tickRadius, sides), ticksPaint);

      TextPainter(
        text:
            TextSpan(text: tick.toString(), style: TextStyle(color: axisColor)),
        textDirection: TextDirection.ltr,
      )
        ..layout(minWidth: 0, maxWidth: size.width)
        ..paint(canvas,
            Offset(centerX, centerY - tickRadius - ticksTextStyle.fontSize!));
    });

    // Painting the axis for each given feature
    var angle = (2 * pi) / features.length;

    features.asMap().forEach((index, feature) {
      var xAngle = cos(angle * index - pi / 2);
      var yAngle = sin(angle * index - pi / 2);

      var featureOffset =
          Offset(centerX + radius * xAngle, centerY + radius * yAngle);

      canvas.drawLine(centerOffset, featureOffset, ticksPaint);
    });

    var dataPoints = <Offset>[];

    // Painting each graph
    data.asMap().forEach((index, graph) {
      var graphPaint = Paint()
        ..color = graphColors[index % graphColors.length].withOpacity(0.60)
        ..style = PaintingStyle.fill;

      // Start the graph on the initial point
      var scaledPoint = scale * graph[0] * fraction;
      var path = Path();

      if (reverseAxis) {
        path.moveTo(centerX, centerY - (radius * fraction - scaledPoint));
      } else {
        path.moveTo(centerX, centerY - scaledPoint);
      }
      void paintDataPoints(Canvas canvas, List<Offset> points) {
        for (var i = 0; i < points.length; i++) {
          canvas.drawCircle(points[i], 5.0, Paint()..color = tickColor[i]);
        }
        // canvas.drawPoints(PointMode.polygon, points, spokes);
      }

      void paintDataLines(Canvas canvas, List<Offset> points) {
        Path path = Path()..addPolygon(points, true);

        canvas.drawPath(path, graphPaint);
      }

      graph.asMap().forEach((index, point) {
        var xAngle = cos(angle * index - pi / 2);
        var yAngle = sin(angle * index - pi / 2);
        double scaledPoint = 0;

        if (point == 0) {
          scaledPoint = point * scale * fraction + 24;
        } else if (point > 0 && point <= 1) {
          scaledPoint = point * scale * fraction + 22;
        } else if (point > 1 && point <= 2) {
          scaledPoint = point * scale * fraction + 20;
        } else if (point > 2 && point <= 3) {
          scaledPoint = point * scale * fraction + 18;
        } else if (point > 3 && point <= 4) {
          scaledPoint = point * scale * fraction + 16;
        } else if (point > 4 && point <= 5) {
          scaledPoint = point * scale * fraction + 14;
        } else if (point > 5 && point <= 6) {
          scaledPoint = point * scale * fraction + 12;
        } else if (point > 6 && point <= 7) {
          scaledPoint = point * scale * fraction + 10;
        } else if (point > 7 && point <= 8) {
          scaledPoint = point * scale * fraction + 8;
        } else if (point > 8 && point <= 9) {
          scaledPoint = point * scale * fraction + 6;
        } else if (point > 9 && point <= 10) {
          scaledPoint = point * scale * fraction + 4;
        }

        dataPoints.add(Offset(
            centerX + scaledPoint * xAngle, centerY + scaledPoint * yAngle));
      });
      paintDataLines(canvas, dataPoints);
      paintDataPoints(canvas, dataPoints);
    });
  }

  @override
  bool shouldRepaint(SpiderChartPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
