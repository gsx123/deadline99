import 'dart:math';
import 'dart:ui';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../poker99GameCtrl.dart';
// import '../pacman.dart';

class PCard extends Component {
  static Poker99GameCtrl GameCtrl = null;
  Sprite sprite = Sprite('poker1.png');

  Rect _playerRect;
  // PacMan _game;
  Point _position;
  Point _targetLocation;
  bool _died = false;
  int _points = 0;

  int get points => _points;
  Point get position => _position;
  Rect get rect => _playerRect;
  bool get died => _died;

  set targetLocation(Point targetPoint) {
    _targetLocation = targetPoint;
  }

  PCard(String val, int decor) {
    _position = Point(7.0, 10.0); // starting position

    _playerRect = Rect.fromLTWH(20, 20, 100, 150);
  }

  void die() {
    _position = null;
    _died = true;
    _points = 0;
  }

  void render(Canvas canvas) {
    sprite.renderRect(canvas, _playerRect.inflate(2));
  }

  void update(double t) {}
}

class CardScore extends PCard {
  CardScore(String val, int decor) : super(val, decor) {}

  execute(player) {
    // PCard.GameCtrl.score.add(parseInt(this.value));
    // PCard.GameCtrl.getCardToPlayer(player);
    // super.execute(player);
  }

  executeTest(player) {
    // PCard.GameCtrl.score.add(parseInt(this.value));
    // let fail = false;
    // if (PCard.GameCtrl.score.get() > C.DeadlineScore) {
    //   fail = true;
    // }
    // PCard.GameCtrl.score.restore();
    // return fail;
  }
}

class CardPlusMinus extends PCard {
  CardPlusMinus(String val, int decor, int score) : super(val, decor) {}
}

class CardSteal extends PCard {
  CardSteal(String val, int decor) : super(val, decor) {}
}

class CardReverse extends PCard {
  CardReverse(String val, int decor) : super(val, decor) {}
}

class CardExchange extends PCard {
  CardExchange(String val, int decor) : super(val, decor) {}
}

class CardScoreToTop extends PCard {
  CardScoreToTop(String val, int decor) : super(val, decor) {}
}

class CardPickNext extends PCard {
  CardPickNext(String val, int decor) : super(val, decor) {}
}

createCard(val, decor) {
  switch (val.toString()) {
    case 'A':
      return new CardPickNext(val, decor);
    case '3':
    case '4':
    case '5':
    case '6':
    case '9':
      return new CardScore(val, decor);
    case '10':
      return new CardPlusMinus(val, decor, 10);
    case 'Q':
      return new CardPlusMinus(val, decor, 20);
    case 'J':
      return new CardSteal(val, decor);
    case 'K':
      return new CardScoreToTop(val, decor);
    case '8':
      return new CardReverse(val, decor);
    case '7':
      return new CardExchange(val, decor);

    default:
      break;
  }
  return null;
}
