import 'dart:math';
import 'dart:ui';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import 'card.dart';
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
  List<PCard> handCards = [];

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

  getName() {
    return this.name;
  }

  takeIn(card) {
    card.picking = false;
    this.handCards.add(card);
  }

  moveCardOut(card) {
    this.handCards.remove(card);
  }

  playOutByID(id) {
    var card = this.handCards.firstWhere((c) {
      return c.id == id;
    });
    this.handCards.removeWhere((c) {
      return c.id == id;
    });
    return card;
  }

  pickingCard() {
    var n = Random().nextInt(this.handCards.length);
    var toPickCard = this.handCards[n];
    toPickCard.picking = true;
    return {'card': toPickCard, 'id': n};
  }

  pickCardOut(n) {
    var card = this.handCards.elementAt(n);
    card.picking = false;
    this.handCards.removeAt(n);
    return card;
  }

  setAlive(alive) {
    this.alive = alive;
  }

  isAlive() {
    return this.alive;
  }

  void render(Canvas canvas) {
    spriteAvatar.renderRect(canvas, _playerRect.inflate(2));
  }

  void update(double t) {}
}
