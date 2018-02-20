pragma solidity ^0.4.0;

contract EnumContract{
    enum Move {NONE,ROCK,PAPER,SCISSORS}
    enum Result {ONGOING, VICTORY_1,VICTORY_2,TIE}
    enum GameState {WAIT_MOVE,WAIT_REVEAL,TIMES_UP,RESOLVED}
}
