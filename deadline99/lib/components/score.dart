import 'dart:math';
import 'dart:ui';
import 'package:Deadline99/defines.dart';
import 'package:flame/anchor.dart';
import 'package:flame/components/component.dart';
import 'package:flame/position.dart';
import 'package:flame/sprite.dart';
import 'package:flame/text_config.dart';
import 'package:flutter/material.dart';

class Score extends Component {
  var score = 0;
  var scoreBackup = 0;
  TextConfig config = TextConfig(fontSize: 30.0, color: Colors.red);
  Rect _rect;

  Score(Offset center) {
    _rect = Rect.fromCenter(center: center, width: 60, height: 60);
  }

  get() {
    return this.score;
  }

  set(s) {
    this.scoreBackup = this.score;
    this.score = s;
  }

  add(plusValue) {
    this.scoreBackup = this.score;
    this.score += plusValue;
  }

  restore() {
    this.score = this.scoreBackup;
  }

  @override
  void render(Canvas canvas) {
    // TODO: implement render
    config.render(canvas, this.score.toString(),
        Position(_rect.center.dx, _rect.center.dy),
        anchor: Anchor.topCenter);
  }

  @override
  void update(double t) {
    // TODO: implement update
  }
}
