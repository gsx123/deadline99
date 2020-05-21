import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:Deadline99/defines.dart';
import 'package:Deadline99/poker99.dart';
import 'package:Deadline99/utils/logger.dart';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import 'components/card.dart';
import 'components/player.dart';
import 'components/score.dart';

// import '../pacman.dart';
class C {
  static int HandSize = 5;
  static int DeadlineScore = 99;
}

enum PState { Normal, SelectingTargetPlayer }

class Poker99GameCtrl extends Component {
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

  int tickCnt = 0;
  PState state = PState.Normal;
  Player targetPlayer = null;
  var callBackSelectedTargetPlayer;

  bool playOrderClockwise = true;
  int specifiedNextPlayerId = -1;
  int curPlayerId = 0;

  int rivalNumber = 4;

  Score score;
  Poker99 game;
  Player myPlayer;
  List<Player> players = List();
  List<PCard> cardStock = List();
  List<PCard> cardPlayed = List();
  List<PCard> cardRecyle = List();

  Poker99GameCtrl(this.game) {
    _position = Point(7.0, 10.0); // starting position

    _playerRect = Rect.fromLTWH(20, 20, 100, 150);

    initBoard();
    initCards();
    initPlayers(3);
    initRound();
    PCard.GameCtrl = this;
    Player.GameCtrl = this;
  }

  void die() {
    _position = null;
    _died = true;
    _points = 0;
  }

  initCards() {
    for (var i = 3; i <= 10; ++i) {
      this.cardStock.add(createCard(i.toString(), 1));
      this.cardStock.add(createCard(i.toString(), 2));
      this.cardStock.add(createCard(i.toString(), 3));
      this.cardStock.add(createCard(i.toString(), 4));
    }
    var arr = ['A', 'J', 'Q', 'K'];
    for (var item in arr) {
      this.cardStock.add(createCard(item, 1));
      this.cardStock.add(createCard(item, 2));
      this.cardStock.add(createCard(item, 3));
      this.cardStock.add(createCard(item, 4));
    }
  }

  initBoard() {
    var center =
        Offset(this.game.screenSize.width / 2, this.game.screenSize.height / 2);
    this.score = Score(center);
  }

  initPlayers(rivalNumber) {
    var marginH = 60.0;
    var marginV = 60.0;
    var center = Offset(this.game.screenSize.width / 2,
        this.game.screenSize.height - CardHeight - AvatarHeight - 20);
    this.myPlayer = new Player('Me', 0, center, true);
    var leftCenter = Offset(marginH, this.game.screenSize.height / 2);
    var leftTop = Offset(marginH, marginV);
    var topCenter = Offset(this.game.screenSize.width / 2, marginV);
    var rightTop = Offset(this.game.screenSize.width - marginH, marginV);
    var rightCenter = Offset(
        this.game.screenSize.width - marginH, this.game.screenSize.height / 2);
    List<Offset> posarr = [];
    switch (rivalNumber) {
      case 1:
        posarr.add(topCenter);
        break;
      case 2:
        posarr.add(leftCenter);
        posarr.add(rightCenter);
        break;
      case 3:
        posarr = [leftCenter, topCenter, rightCenter];
        break;
      case 4:
        posarr = [leftCenter, leftTop, rightTop, rightCenter];
        break;
      case 5:
        posarr = [leftCenter, leftTop, topCenter, rightTop, rightCenter];
        break;
      default:
    }
    for (var i = 0; i < rivalNumber; ++i) {
      this.players.add(new Player((i + 1).toString(), i + 1, posarr[i], false));
    }
  }

  callJudge(player) async {
    console.log('onEvent judge');

    var lose = false;
    if (player.handCards.length == 0) {
      lose = true;
    }
    if (this.score.get() > C.DeadlineScore) {
      lose = true;
      this.score.restore();
    }
    if (lose) {
      player.setAlive(false);
    }

    var aliveCnt = this.myPlayer.isAlive() ? 1 : 0;
    var alivePlayer = aliveCnt == 1 ? this.myPlayer : null;
    for (var p in this.players) {
      aliveCnt += p.isAlive() ? 1 : 0;
      if (alivePlayer == null) alivePlayer = p.isAlive() ? p : null;
    }
    if (aliveCnt == 1) {
      console.log('GameOver only one alive');
      new Future.delayed(new Duration(microseconds: 100), () {
        this.onEndARound(alivePlayer);
      });
    } else {
      new Future.delayed(new Duration(microseconds: 100), () {
        this.callNextPlayer();
      });
    }
  }

  callNextPlayer() async {
    console.log('onEvent nextPlayer');
    var np = this.getNextPlayer();
    sleep(Duration(seconds: 1));
    if (this.isMyPlayer(np)) {
      return;
    }
    // var card = np.pickCard();
    // this.playCard(np, card);
    await this.pickingPlayCard(np);
  }

  onEndARound(winner) {
    // window.alert('Winer is ' + winner.getName());

    this.reloadARound();
  }

  reloadARound() {
    console.warn('==== reloadARound');
    this.cardRecyle = this.cardPlayed;
    this.cardPlayed = [];
    this.myPlayer.setAlive(true);
    this.resetPlayer(this.myPlayer);
    this.players.forEach((e) {
      this.resetPlayer(e);
    });
    this.score.set(0);
    new Future.delayed(new Duration(microseconds: 500), () {
      initRound();
    });
  }

  resetPlayer(Player player) {
    this.cardRecyle.addAll(player.handCards);
    player.handCards.clear();
    player.setAlive(true);
  }

  _pickCard() {
    if (this.cardStock.length == 0) {
      console.info('No card in stock ,reload ');
      this.cardStock = this.cardRecyle;
      this.cardRecyle = [];
    }
    var n = Random().nextInt(this.cardStock.length);
    var card = this.cardStock[n];
    this.cardStock.removeAt(n);
    return card;
  }

  setNextPlayer(player) {
    for (var i = 0; i < this.players.length; ++i) {
      if (player == this.players[i]) {
        this.specifiedNextPlayerId = i + 1;
      }
    }
    if (player == this.myPlayer) {
      this.specifiedNextPlayerId = 0;
    }
    console.log('setNextPlayer specify id:${this.specifiedNextPlayerId}');
  }

  getNextPlayer() {
    if (this.specifiedNextPlayerId >= 0) {
      this.curPlayerId = this.specifiedNextPlayerId;
      this.specifiedNextPlayerId = -1;
      if (this.curPlayerId == 0) {
        return this.myPlayer;
      }
      return this.players[this.curPlayerId - 1];
    }
    do {
      this.playOrderClockwise ? this.curPlayerId++ : this.curPlayerId--;
      if (this.curPlayerId > this.players.length) {
        this.curPlayerId = 0;
      }
      if (this.curPlayerId < 0) {
        this.curPlayerId = this.players.length;
      }
      console.log('getNextPlayer id:${this.curPlayerId}');
      if (this.curPlayerId == 0) {
        if (!this.myPlayer.isAlive()) {
          console.error('Me dead');
          continue;
        }
        // this.tick();
        return this.myPlayer;
      }
      var testPlayer = this.players[this.curPlayerId - 1];
      if (!testPlayer.isAlive()) {
        console.log('getNextPlayer player:${testPlayer.getName()} dead');
        continue;
      }
      return testPlayer;
    } while (true);
  }

  reversePlayOrder() {
    this.playOrderClockwise = !this.playOrderClockwise;
  }

  getCardToPlayer(player) {
    var a = this._pickCard();
    player.takeIn(a);
    console
        .log('getCardToPlayer card:${a.getName()} player:${player.getName()}');
  }

  recvPlayedCard(card) {
    this.cardPlayed.add(card);
  }

  setTargetPlayer(player) {
    this.targetPlayer = player;
  }

  getTargetPlayer() {
    return this.targetPlayer;
  }

  buildHands() async {
    console.log('buildHands');
    // this.state = State.BuildHands;
    for (var i = 0; i < C.HandSize; i++) {
      sleep(Duration(seconds: 1));
      var a = this._pickCard();
      this.myPlayer.takeIn(a);
      for (var j = 0; j < this.players.length; j++) {
        var b = this._pickCard();

        this.players[j].takeIn(b);
      }
      // this.tick();
    }
  }

  initRound() async {
    await this.buildHands();
  }

  isMyPlayer(player) {
    return player.getName() == this.myPlayer.getName();
  }

  pickingPlayCard(player) async {
    var picking = player.pickingCard();
    // this.tick();
    // await sleep(2000);
    player.pickCardOut(picking['id']);
    new Future.delayed(new Duration(microseconds: 1000), () {
      this.playCard(player, picking['card']);
    });

    // this.tick();
  }

  playCard(Player player, PCard card) {
    if (card != null) {
      console.warn('[playCard] "${player.getName()}" played ${card.getName()}');
      this.recvPlayedCard(card);
      card.execute(player);
      // this.tick();
    }
    // gt.tick();
  }

  askToSelectPlusOrMinusScore(player, score) async {
    console.log('askToSelectPlusOrMinusScore');
    if (!this.isMyPlayer(player)) {
      var toPlus = Random().nextBool();
      console.log(
          'askToSelectPlusOrMinusScore[auto]: ' + (toPlus ? 'plus' : 'minus'));
      return toPlus;
    }
    var toPlus = true; //await window.confirm(`plus or minus ${score}`);
    // console.log('askToSelectPlusOrMinusScore: ' + toPlus ? 'plus' : 'minus');
    return toPlus;
  }

  askToSelectTargetPlayer(player, callBack) async {
    console.log('askToSelectTargetPlayer');
    this.state = PState.SelectingTargetPlayer;
    this.callBackSelectedTargetPlayer = callBack;
    if (!this.isMyPlayer(player)) {
      var arr = [];
      for (var item in this.players) {
        if (item.isAlive() && player.getId() != item.getId()) arr.add(item);
      }
      arr.add(this.myPlayer);
      var id = Random().nextInt(arr.length);
      this.targetPlayer = arr[id];
      console.log(
          'askToSelectTargetPlayer[auto] selected:${this.targetPlayer.getName()}');
      this.state = PState.Normal;
      this.callBackSelectedTargetPlayer(this.targetPlayer);
      return; //this.targetPlayer;
    }

    console.log('askToSelectTargetPlayer idle waiting');
    // this.targetPlayer = null;
    // while (true) {
    //   sleep(Duration(seconds: 1));
    //   console.log('askToSelectTargetPlayer waiting');
    //   if (this.targetPlayer != null) {
    //     break;
    //   }
    // }
    // console
    //     .log('askToSelectTargetPlayer selected:${this.targetPlayer.getName()}');
    // return this.targetPlayer;
  }

  void render(Canvas canvas) {
    score.render(canvas);
    myPlayer.render(canvas);

    if (cardStock.length > 0) {
      cardStock.forEach((coin) {
        coin.render(canvas);
      });
    }
    cardPlayed.forEach((coin) {
      coin.render(canvas);
    });
    players.forEach((coin) {
      coin.render(canvas);
    });
  }

  void update(double t) {
    myPlayer.update(t);

    players.forEach((ghost) {
      ghost.update(t);
    });
    cardStock.forEach((ghost) {
      ghost.update(t);
    });

    cardPlayed.forEach((coin) {
      coin.update(t);
    });

    // Remove coins consumed
    // if(_coinsToRemove.isNotEmpty) {
    //   _coins.removeWhere((coin) => _coinsToRemove.contains(coin));
    //   _coinsToRemove.clear();
    // }
  }

  void onTapDown(TapDownDetails details) {
    var pos = details.globalPosition;
    bool handled = myPlayer.onTapDown(details);
    if (handled) return;
    for (var p in this.players) {
      handled = p.onTapDown(details);
      if (handled) {
        break;
      }
    }
  }
}
