import 'dart:math';
import 'dart:ui';
import 'package:Deadline99/defines.dart';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../poker99GameCtrl.dart';
// import '../pacman.dart';

const CW = 77.0;
const CH = 108.0;
const CHGap = 12.0;
const CWGap = 17.0;
const CMap = {
  '2': [0.0, 0.0, CW, CH],
  '3': [CW + CWGap, 0.0, CW, CH],
  '4': [(CW + CWGap) * 2, 0.0, CW, CH],
  '5': [(CW + CWGap) * 3, 0.0, CW, CH],
  '6': [(CW + CWGap) * 4, 0.0, CW, CH],
  '7': [0.0, CH + CHGap, CW, CH],
  '8': [CW + CWGap, CH + CHGap, CW, CH],
  '9': [(CW + CWGap) * 2, CH + CHGap, CW, CH],
  '10': [(CW + CWGap) * 3, CH + CHGap, CW, CH],
  'A': [(CW + CWGap) * 4, CH + CHGap, CW, CH],
  'J': [0.0, (CH + CHGap) * 2, CW, CH],
  'Q': [CW + CWGap, (CH + CHGap) * 2, CW, CH],
  'K': [(CW + CWGap) * 2, (CH + CHGap) * 2, CW, CH],
  'M1': [(CW + CWGap) * 3, (CH + CHGap) * 2, CW, CH],
  'M2': [(CW + CWGap) * 4, (CH + CHGap) * 2, CW, CH],
};

class PCard extends Component {
  static Poker99GameCtrl GameCtrl = null;

  static getSprite(String val, int decor) {
    var a = CMap[val];
    return Sprite('poker' + decor.toString() + '.png',
        x: a[0], y: a[1], width: a[2], height: a[3]);
  }

  Sprite sprite;

  Rect _playerRect;
  // PacMan _game;
  Point _position;
  Point _targetLocation;
  bool _died = false;
  int _points = 0;

  int id = 0;
  bool picking = false;
  int get points => _points;
  Point get position => _position;
  Rect get rect => _playerRect;
  bool get died => _died;

  set targetLocation(Point targetPoint) {
    _targetLocation = targetPoint;
  }

  String value;
  int decor;
  PCard(this.value, this.decor) {
    sprite = PCard.getSprite(this.value, this.decor);

    // _playerRect = Rect.fromLTWH(20, 20, 77, 108);
  }

  getName() {
    return this.value;
  }

  setRect(Offset ofs, {width: CardWidth, height: CardHeight}) {
    _playerRect = Rect.fromLTWH(ofs.dx, ofs.dy, width, height);
  }

  void die() {
    _position = null;
    _died = true;
    _points = 0;
  }

  execute(player) {
    PCard.GameCtrl.callJudge(player);
  }

  void render(Canvas canvas) {
    if (_playerRect != null) sprite.renderRect(canvas, _playerRect.inflate(1));
  }

  void update(double t) {}
}

class CardScore extends PCard {
  CardScore(String val, int decor) : super(val, decor) {}

  @override
  execute(player) {
    PCard.GameCtrl.score.add(int.parse(this.value));
    PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }

  executeTest(player) {
    // PPCard.GameCtrl.score.add(parseInt(this.value));
    // var fail = false;
    // if (PPCard.GameCtrl.score.get() > C.DeadlineScore) {
    //   fail = true;
    // }
    // PPCard.GameCtrl.score.restore();
    // return fail;
  }
}

class CardPlusMinus extends PCard {
  var scoreVal = 0;
  CardPlusMinus(String val, int decor, int score) : super(val, decor) {
    this.scoreVal = score;
  }
  @override
  execute(player) async {
    var toPlus =
        await PCard.GameCtrl.askToSelectPlusOrMinusScore(player, this.scoreVal);
    PCard.GameCtrl.score.add(toPlus ? this.scoreVal : -this.scoreVal);
    PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }
}

class CardSteal extends PCard {
  CardSteal(String val, int decor) : super(val, decor) {}
  @override
  execute(player) async {
    var targetPlayer =
        await PCard.GameCtrl.askToSelectTargetPlayer(player, (targetPlayer) {
      var a = targetPlayer.pickingCard();
      // PCard.GameCtrl.tick();
      // await sleep(1000);
      player.takeIn(a['card']);
      // PCard.GameCtrl.getCardToPlayer(player);
      super.execute(player);
    });
  }
}

class CardReverse extends PCard {
  CardReverse(String val, int decor) : super(val, decor) {}
  @override
  execute(player) async {
    PCard.GameCtrl.reversePlayOrder();
    PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }
}

class CardExchange extends PCard {
  CardExchange(String val, int decor) : super(val, decor) {}
  @override
  execute(player) async {
    var targetPlayer =
        await PCard.GameCtrl.askToSelectTargetPlayer(player, (targetPlayer) {
      // PCard.GameCtrl.getCardToPlayer(player);
      var c = targetPlayer.handCards;
      targetPlayer.handCards = player.handCards;
      player.handCards = c;
      super.execute(player);
    });
  }
}

class CardScoreToTop extends PCard {
  CardScoreToTop(String val, int decor) : super(val, decor) {}
  @override
  execute(player) async {
    PCard.GameCtrl.score.set(C.DeadlineScore);
    PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }
}

class CardPickNext extends PCard {
  CardPickNext(String val, int decor) : super(val, decor) {}
  @override
  execute(player) async {
    var targetPlayer =
        await PCard.GameCtrl.askToSelectTargetPlayer(player, (targetPlayer) {
      PCard.GameCtrl.setNextPlayer(targetPlayer);
      PCard.GameCtrl.getCardToPlayer(player);
      super.execute(player);
    });
  }
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
