
async function sleep(time = 0) {
    return await new Promise((resolve, reject) => {
        setTimeout(() => {
            resolve();
        }, time);
    });
}

let obj = {};
class EventEmitter {
    on = (name, fn) => {
        if (!obj[name]) {
            obj[name] = [];
        }
        obj[name].push(fn);
    }

    emit = (name, val) => {
        if (obj[name]) {
            obj[name].map((fn) => {
                fn(val);
            });
        }
    }

    off = (name, fn) => {
        if (obj[name]) {
            if (fn) {
                let index = obj[name].indexOf(fn);
                if (index > -1) {
                    obj[name].splice(index, 1);
                }
            } else {
                obj[name].length = 0;
                //设长度为0比obj[name] = []更优，因为如果是空数组则又开辟了一个新空间，设长度为0则不必开辟新空间
            }
        }
    }
}

let C = {
    HandSize: 5,
    DeadlineScore: 99,
}
class Card {
    static CardID = 0;
    static GameCtrl = null;
    constructor(val) {
        this.value = val;
        this.id = Card.CardID++;
    }

    getName() {
        return this.value.toString();
    }
    async execute(player) {

        Card.GameCtrl.eventEmitter.emit('judge', player);
    }
}
class CardScore extends Card {
    constructor(val) {
        super(val);
    }

    async execute(player) {
        Card.GameCtrl.score.add(parseInt(this.value));
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardPlusMinus extends Card {
    constructor(val, scoreVal) {
        super(val);
        this.scoreVal = scoreVal;
    }
    async execute(player) {
        let toPlus = await Card.GameCtrl.askToSelectPlusOrMinusScore(player, this.scoreVal);
        Card.GameCtrl.score.add(toPlus ? this.scoreVal : -this.scoreVal);
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardSteal extends Card {
    constructor(val) {
        super(val);
    }
    async execute(player) {
        let targetPlayer = await Card.GameCtrl.askToSelectTargetPlayer(player);
        let card = targetPlayer.pickCard();
        player.takeIn(card);
        // Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardReverse extends Card {
    constructor(val) {
        super(val);
    }
    async execute(player) {

        Card.GameCtrl.reversePlayOrder();
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardExchange extends Card {
    constructor(val) {
        super(val);
    }
    async execute(player) {
        let targetPlayer = await Card.GameCtrl.askToSelectTargetPlayer(player);
        // Card.GameCtrl.getCardToPlayer(player);
        let c = targetPlayer.handCards;
        targetPlayer.handCards = player.handCards;
        player.handCards = c;
        super.execute(player);
    }
}
class CardScoreToTop extends Card {
    constructor(val) {
        super(val);
    }
    async execute(player) {
        Card.GameCtrl.score.set(C.DeadlineScore);
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardPickNext extends Card {
    constructor(val) {
        super(val);
    }
    async execute(player) {
        let targetPlayer = await Card.GameCtrl.askToSelectTargetPlayer(player);
        Card.GameCtrl.setNextPlayer(targetPlayer);
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}



function createCard(val) {
    switch (val.toString()) {
        case '1':
            return new CardPickNext(val);
        case '3':
        case '4':
        case '5':
        case '6':
        case '9':
            return new CardScore(val);
        case '10':
            return new CardPlusMinus(val, 10);
        case 'q':
            return new CardPlusMinus(val, 20);
        case 'j':
            return new CardSteal((val));
        case 'k':
            return new CardScoreToTop((val));
        case '8':
            return new CardReverse((val));
        case '7':
            return new CardExchange((val));

        default:
            break;
    }
    return null;
}
class Score {
    constructor() {
        this.score = 0;
    }
    get() { return this.score; }
    set(s) { this.score = s; }
    add(plusValue) {
        this.score += plusValue;
    }
}

var State = {
    Init: 0,
    BuildHands: 1,

}

// var EventEmitter = require('events').EventEmitter

class GameCtrl {

    constructor() {
        this.eventEmitter = new EventEmitter();
        this.score = new Score();
        this.players = [];
        this.cardStock = [];
        this.cardPlayed = [];
        this.myPlayer = null;
        this.tickCnt = 0;
        this.state = State.init;
        this.renderDomId = '';
        this.targetPlayer = null;

        this.playOrderClockwise = true;
        this.specifiedNextPlayerId = -1;
        this.curPlayerId = 0;

        this.rivalNumber = 4;
    }
    initGame() {

        this.eventEmitter.on('judge', async () => {
            console.log('onEvent judge');


        })
        this.eventEmitter.on('nextPlayer', async () => {
            console.log('onEvent nextPlayer');
            let np = this.getNextPlayer();
            await sleep(5000);
            if (this.isMyPlayer(np)) {

                return;
            }
            let card = np.pickCard();
            this.playCard(np, card);
        })

        this.state = State.init;
        for (var i = 1; i <= 10; ++i) {
            if (i == 2) continue;
            this.cardStock.push(createCard(i));
            this.cardStock.push(createCard(i));
            this.cardStock.push(createCard(i));
            this.cardStock.push(createCard(i));
        }
        var arr = ['j', 'q', 'k'];
        for (const item of arr) {
            this.cardStock.push(createCard(item));
            this.cardStock.push(createCard(item));
            this.cardStock.push(createCard(item));
            this.cardStock.push(createCard(item));
        }
    }
    initPlayers(rivalNumber) {
        this.myPlayer = new Player('Me', 0);
        for (var i = 0; i < rivalNumber; ++i) {
            this.players.push(new Player(i.toString(), i + 1));
        }

    }

    _pickCard() {
        let n = Math.floor(Math.random() * this.cardStock.length);
        let card = this.cardStock.splice(n, 1)[0];
        return card;
    }

    setNextPlayer(player) {
        for (let i = 0; i < this.players.length; ++i) {
            if (player == this.players[i]) {
                this.specifiedNextPlayerId = i + 1;
            }
        }
        if (player == this.myPlayer) {
            this.specifiedNextPlayerId = 0;
        }
        console.log(`setNextPlayer specify id:${this.specifiedNextPlayerId}`);
    }
    getNextPlayer() {
        if (this.specifiedNextPlayerId >= 0) {
            this.curPlayerId = this.specifiedNextPlayerId;
            this.specifiedNextPlayerId = -1;
        } else {
            this.playOrderClockwise ? this.curPlayerId++ : this.curPlayerId--;

        }
        if (this.curPlayerId > this.players.length) {
            this.curPlayerId = 0;
        }
        if (this.curPlayerId < 0) {
            this.curPlayerId = this.players.length;
        }
        console.log(`getNextPlayer id:${this.curPlayerId}`);
        if (this.curPlayerId == 0) {
            return this.myPlayer;
        }
        return this.players[this.curPlayerId - 1];
    }
    reversePlayOrder() {
        this.playOrderClockwise = !this.playOrderClockwise;

    }

    getCardToPlayer(player) {
        let a = this._pickCard();
        player.takeIn(a);
        console.log(`getCardToPlayer card:${a.getName()} player:${player.getName()}`);
    }
    recvPlayedCard(card) {
        this.cardPlayed.push(card);
    }
    setTargetPlayer(player) {
        this.targetPlayer = player;
    }
    getTargetPlayer() {
        return this.targetPlayer;
    }
    async buildHands() {
        console.log('buildHands');
        this.state = State.BuildHands;
        for (var i = 0; i < C.HandSize; i++) {

            await sleep(1000);
            let a = this._pickCard();
            this.myPlayer.takeIn(a);
            for (var j = 0; j < this.players.length; j++) {
                let b = this._pickCard();

                this.players[j].takeIn(b);
            }
        }
    }
    async initRound() {
        await this.buildHands();
    }

    isMyPlayer(player) {
        return player.getName() == this.myPlayer.getName();
    }
    async askToSelectPlusOrMinusScore(player, score) {
        if (!this.isMyPlayer(player)) {
            let toPlus = Math.round(Math.random()) == 1;
            console.log('askToSelectPlusOrMinusScore[auto]: ' + toPlus ? 'plus' : 'minus');
            return toPlus;
        }
        let toPlus = await window.confirm(`plus or minus ${score}`);
        console.log('askToSelectPlusOrMinusScore: ' + toPlus ? 'plus' : 'minus');
        return toPlus;
    }
    async askToSelectTargetPlayer(player) {
        if (!this.isMyPlayer(player)) {
            let id = Math.ceil(Math.random() * this.rivalNumber);
            if (id == player.getId()) {
                this.targetPlayer = this.myPlayer;
            } else {
                this.targetPlayer = this.players[id - 1];
            }
            console.log(`askToSelectTargetPlayer[auto] selected:${this.targetPlayer.getName()}`)
            return this.targetPlayer;
        }
        window.alert('select a player to apply your magic');
        document.getElementsByClassName('player');
        this.targetPlayer = null;

        while (true) {
            await sleep(100);
            console.log('askToSelectTargetPlayer waiting');
            if (this.targetPlayer) {
                break;
            }
        }
        console.log(`askToSelectTargetPlayer selected:${this.targetPlayer.getName()}`)
        return this.targetPlayer;
    }

    playCard(player, card) {
        if (card) {
            console.warn(`[playCard] "${player.getName()}" played ${card.getName()}`);
            gt.recvPlayedCard(card);
            card.execute(player);
        }
        gt.tick();
    }

    renderCard(c) {
        return c.getName();
    }
    renderCardClickable(c) {
        return '<button class=player onclick="playCard(' + c.id + ')">' + c.getName() + '</button>';
    }
    renderPlayer(p, curPlayerId) {
        let color = curPlayerId == p.id ? 'red' : 'black';
        return '<button style="color:' + color + '" onclick="selectPlayer(\'' + p.getName() + '\')">Player ' + p.getName() + '</button> : ' + p.handCards.map((c) => {
            return '*';
        }).join(' ') + '<br/>';
    }
    renderMyPlayer(p, curPlayerId) {
        let color = curPlayerId == p.id ? 'red' : 'black';
        return '<span style="color:' + color + '">Me</span>    : ' + p.handCards.map((c) => {
            return this.renderCardClickable(c);
        }).join(' ') + '<br/>';
    }
    renderCardStock() {
        return '*'.repeat(this.cardStock.length);
    }
    renderCardPlayed() {
        return 'Played    : ' + this.cardPlayed.map((c) => {
            return this.renderCard(c);
        }).join(' ') + '<br/>';
    }
    render() {
        let eleId = this.renderDomId;
        let tmpTick = '<BR/>tic : $tick$ ';
        let tmpScore = '<BR/>score: $score$               '
        '<BR/> ';
        let tmpPlayerInfo = '$hideHandCards$';
        let hideCard = '*';
        let tmpPlayers = this.players.map((p) => {
            return this.renderPlayer(p, this.curPlayerId);
        });
        let tmpPlayersHtml = tmpPlayers.join('<br/>');

        let tmpMy = this.renderMyPlayer(this.myPlayer, this.curPlayerId);

        let html = '';

        let htmlTick = tmpTick.replace('$tick$', this.tickCnt);
        html = htmlTick;
        html += tmpScore.replace('$score$', this.score.get());
        html += '<hr/>';
        html += this.renderCardStock();
        html += '<hr/>';
        html += this.renderCardPlayed();
        html += '<hr/>';
        html += tmpPlayersHtml;
        html += '<hr/>';
        html += tmpMy;

        document.getElementById(eleId).innerHTML = html;
    }

    tick() {
        // console.log('tick');
        this.tickCnt++;
        this.render();
    }

    run(eleId) {
        this.initGame();
        this.initPlayers(this.rivalNumber);
        this.initRound();
        this.renderDomId = eleId;
        let the = this;
        setInterval(() => {
            the.tick(eleId);
        }, 1000);

    }

}

class Player {
    constructor(name, id) {
        this.handCards = [];
        this.name = name;
        this.id = id;
    }
    getId() { return this.id; }
    getName() {
        return this.name;
    }
    takeIn(card) {
        this.handCards.push(card);
    }
    moveCardOut(card) {
        let index = this.handCards.findIndex((c) => { return card.id == c.id; });
        this.handCards.splice(index, 1);

    }
    playOutByID(id) {
        let card = this.handCards.find((c) => { return c.id == id; });
        if (card) {
            this.moveCardOut(card);
        } else {
            console.error('playOutByID not found card:' + id);
        }
        return card;
    }
    pickCard() {
        let n = Math.random(this.handCards.length - 1);
        let card = this.handCards.splice(n, 1)[0];
        return card;
    }
}

var gt = new GameCtrl();
Card.GameCtrl = gt;
function getGameCtrl() {
    return gt;
}
function playCard(id) {
    let card = gt.myPlayer.playOutByID(id);
    gt.playCard(gt.myPlayer, card);
}


function selectPlayer(name) {
    let player = gt.players.find((c) => { return c.name == name; });

    console.log('selectPlayer ' + player.getName());
    gt.setTargetPlayer(player);
}