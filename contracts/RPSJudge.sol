pragma solidity ^0.4.0;

import "./EnumLib.sol";
contract RPSJudge is EnumContract{
    
    address public gameOwner; //contract that sent the game to RPS Judge and needs to be notified of results
    address public player1;
    address public player2;
    bytes32 public hashMove1;
    bytes32 public hashMove2;
    uint256 public hashDeadline;
    Move public finalMove1;  //none=0, rock=1, paper=2, scissors=3
    Move public finalMove2;
    uint256 public finalDeadline;
    Result public result; //ongoing=0, victory_1=1, victory_2=2, tie=3;

    event logNewGame(address indexed owner, address indexed _player1, address indexed _player2,uint startBlock, uint _hashDeadline, uint _finalDeadline);
    event logMoveMade(address indexed player,bytes32 hashedMove);
    event logMoveRevealed(address indexed player, Move revealedMove);
    event logGameOver(address indexed owner, address indexed _player1, address indexed _player2, Move move1, Move move2, Result _result);
    function RPSJudge(address _player1, address _player2,uint hashDeadlineOffset,uint finalDeadlineOffset)public{
        require(_player1!=0);
        require(_player2!=0);
        require(_player1!=player2);
        require (hashDeadlineOffset>0);
        require (finalDeadlineOffset>0);
        hashDeadline=block.number+hashDeadlineOffset;
        finalDeadline=hashDeadline+finalDeadlineOffset;
        player1=_player1;
        player2=_player2;
        gameOwner=msg.sender;
        logNewGame(msg.sender,_player1,_player2,block.number,hashDeadline,finalDeadline);
    }

    function hashMove(address player,Move move,bytes32 secretKey)public constant returns(bytes32){
        //we are validating all the info on hashMove because it is called externally by players to create their moves.
        require(move==Move.ROCK||move==Move.PAPER||move==Move.SCISSORS);
        require(player!=0);
        require(secretKey!=0);
        return keccak256(player,move,secretKey,this); //throw 'this' in to serve as a unique nonce
    }

    function submitMove(bytes32 moveHash)public returns(bool){
        require(moveHash!=0);
        require(hashDeadline>block.number);
        require(player1==msg.sender||player2==msg.sender);
        if(player1==msg.sender) hashMove1=moveHash;
        else hashMove2=moveHash;
        logMoveMade(msg.sender,moveHash);
        return true;
    }
    function revealMove(Move move,bytes32 secretKey)public returns(bool){
        require(player1==msg.sender||player2==msg.sender);
        require(move==Move.ROCK||move==Move.PAPER||move==Move.SCISSORS);
        require(secretKey!=0);
        require(hashDeadline<=block.number);
        require(finalDeadline>block.number);
        if(player1==msg.sender){
            require(hashMove1==hashMove(msg.sender,move,secretKey));
            finalMove1=move;
        }else{
            require(hashMove2==hashMove(msg.sender,move,secretKey));
            finalMove2=move;
        } 
        logMoveRevealed(msg.sender,move);
        return true;
    }
    
    function resolveGame()public returns(Result){
        require(msg.sender==gameOwner);
        require(finalDeadline<=block.number);
        require(result==Result.ONGOING);
        if(finalMove1==finalMove2){
            result=Result.TIE;
        }else if(finalMove1==Move.NONE){
            result=Result.VICTORY_2;
        }else if(finalMove2==Move.NONE){
            result=Result.VICTORY_1;
        }else if(finalMove1==Move.ROCK&&finalMove2==Move.PAPER){
            result=Result.VICTORY_2;
        }else if(finalMove1==Move.PAPER&&finalMove2==Move.SCISSORS){
            result=Result.VICTORY_2;
        }else if(finalMove1==Move.SCISSORS&&finalMove2==Move.ROCK){
            result=Result.VICTORY_2;
        }else if(finalMove1==Move.PAPER&&finalMove2==Move.ROCK){
            result=Result.VICTORY_1;
        }else if(finalMove1==Move.SCISSORS&&finalMove2==Move.PAPER){
            result=Result.VICTORY_1;
        }else if(finalMove1==Move.ROCK&&finalMove2==Move.SCISSORS){
            result=Result.VICTORY_1;
        }
        logGameOver(gameOwner,player1,player2,finalMove1,finalMove2,result);
        return result;
    }
    
    //visibility functions
    function getGameState()public constant returns(GameState){
        if (block.number<hashDeadline) return GameState.WAIT_MOVE;
        if (block.number<finalDeadline) return GameState.WAIT_REVEAL;
        if (result==Result.ONGOING) return GameState.TIMES_UP;
        return GameState.RESOLVED;
    }
    function getHashedMove(address player)public constant returns(bytes32){
       require(player==player1||player==player2);
        if (player==player1)return hashMove1;
        return hashMove2;
    }
    function getMove(address player)public constant returns(Move){
       require(player==player1||player==player2);
        if (player==player1)return finalMove1;
        return finalMove2;
    }
    function getResult()public constant returns(Result){
        return result;
    }
}


