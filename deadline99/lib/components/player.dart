import 'dart:math';
import 'dart:ui';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
// import '../pacman.dart';

class Player extends Component {
  Sprite spriteAvatar;

  Rect _playerRect;
  // PacMan _game;
  Point _position;
  Point _targetLocation;
  bool _died = false;
  int _points = 0;

  String name;
  int id;
  bool alive;

  int get points => _points;
  Point get position => _position;
  Rect get rect => _playerRect;
  bool get died => _died;

  set targetLocation(Point targetPoint) {
    _targetLocation = targetPoint;
  }

  Player(name, id, Offset center) {
    _position = Point(7.0, 10.0); // starting position

    _playerRect = Rect.fromCenter(center: center, width: 50, height: 60);
    name = name;
    id = id;
    alive = true;
    spriteAvatar = Sprite('avatar/' + id.toString() + '.png');
  }

  void die() {
    _position = null;
    _died = true;
    _points = 0;
  }

  void render(Canvas canvas) {
    spriteAvatar.renderRect(canvas, _playerRect.inflate(2));
  }

  void update(double t) {}
}
