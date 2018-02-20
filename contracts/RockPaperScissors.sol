pragma solidity ^0.4.0;

import "./RPSJudge.sol";
contract RockPaperScissors is EnumContract{
    
    struct GamePair{
        address player1;
        address player2;
        address gameAddress;
        uint startTimeBlock;
        Result result; //0=in progress, 1=player 1 wins, 2=player2 wins, 3=tie
        bool paidOut;
    }
    uint public gameCost;
    address public owner;
    uint public hashDeadlineOffset;
    uint public finalDeadlineOffset;

    mapping(address=>address) public seekingMap;
    mapping(address=>GamePair) public gamePairMap;
    mapping(address=>uint) public accountMap;
    mapping(address=>bool) public accountLockMap;
    mapping(address=>address) public currentGame; //only allowing 1 game at a time
    
    event logNewSeek(address indexed seeker, address indexed seeked);
    event logCancelSeek(address indexed seeker);
    event logNewPairing(address indexed gameAddress, address indexed player1, address indexed player2, uint256 startTimeBlock);
    event logGameResolved(address gameAddress, address indexed player1, address indexed player2, Result result);
    event logWithdrawal(address indexed player, uint withdrawAmount, uint accountBalance);
    event logDeposit(address indexed player, uint depositAmount, uint accountBalance);
    
    function RockPaperScissors(uint _gameCost,uint _hashDeadlineOffset,uint _finalDeadlineOffset)public{
        require(_gameCost>0);
        require(_hashDeadlineOffset>0);
        require(_finalDeadlineOffset>0);
        gameCost=_gameCost;
        hashDeadlineOffset=_hashDeadlineOffset;
        finalDeadlineOffset=_finalDeadlineOffset;
        owner=msg.sender;
    }

    function seekGame(address targetPlayer)public returns(address){
        require(targetPlayer!=0);
        require(msg.sender!=targetPlayer);
        require(accountMap[msg.sender]>=gameCost);
        require(accountMap[targetPlayer]>=gameCost);
        require(currentGame[msg.sender]==0);
        require(currentGame[targetPlayer]==0);
        if(seekingMap[targetPlayer]==msg.sender){
            seekingMap[targetPlayer]=0;
            seekingMap[msg.sender]=0;
            RPSJudge rps=new RPSJudge(targetPlayer,msg.sender,hashDeadlineOffset,finalDeadlineOffset);
            require(address(rps)!=0);
            accountMap[msg.sender]-=gameCost;
            accountMap[targetPlayer]-=gameCost;
            gamePairMap[address(rps)].player1=targetPlayer;
            gamePairMap[address(rps)].player2=msg.sender;
            gamePairMap[address(rps)].startTimeBlock=block.number;
            gamePairMap[address(rps)].gameAddress=address(rps);
            currentGame[msg.sender]=address(rps);
            currentGame[targetPlayer]=address(rps);
            logNewPairing(address(rps),targetPlayer,msg.sender,block.number);
            return (address(rps));
        }else{
            seekingMap[msg.sender]=targetPlayer;
            logNewSeek(msg.sender,targetPlayer);
        }
        return (address(1));
    }
    function cancelSeek()public returns(bool){
        require(seekingMap[msg.sender]!=0);
        seekingMap[msg.sender]=0;
        logCancelSeek(msg.sender);
        return true;
    }
    function resolveGame()public returns(bool){
        require(currentGame[msg.sender]!=0);//a player can only resolve their own game.
        address rpsAddr=currentGame[msg.sender];
        require(gamePairMap[rpsAddr].result==Result.ONGOING);
        require(gamePairMap[rpsAddr].paidOut==false);
        RPSJudge rps=RPSJudge(rpsAddr);
        Result result=rps.resolveGame();
        require(result!=Result.ONGOING);
        gamePairMap[rpsAddr].result=result;
        if(result==Result.VICTORY_1){
            gamePairMap[rpsAddr].paidOut=true;
            accountMap[gamePairMap[rpsAddr].player1]+=2*gameCost;
        }else if(result==Result.VICTORY_2){
            gamePairMap[rpsAddr].paidOut=true;
            accountMap[gamePairMap[rpsAddr].player2]+=2*gameCost;
        }else if(result==Result.TIE){
            gamePairMap[rpsAddr].paidOut=true;
            accountMap[gamePairMap[rpsAddr].player1]+=gameCost;
            accountMap[gamePairMap[rpsAddr].player2]+=gameCost;
        }
        currentGame[gamePairMap[rpsAddr].player1]=0;
        currentGame[gamePairMap[rpsAddr].player2]=0;
        logGameResolved(rpsAddr,gamePairMap[rpsAddr].player1,gamePairMap[rpsAddr].player2,result);
        return true;
    }
    function withdraw(uint amount)public returns (bool){
        require(accountLockMap[msg.sender]==false);
        require(seekingMap[msg.sender]==0); //don't allow withdrawing if looking for a game.
        require(accountMap[msg.sender]>=amount);
        assert(accountMap[msg.sender]-amount<accountMap[msg.sender]);

        accountLockMap[msg.sender]=true;
        accountMap[msg.sender]-=amount;
        msg.sender.transfer(amount);
        accountLockMap[msg.sender]=false;
        logWithdrawal(msg.sender,amount,accountMap[msg.sender]);
        return true;
    }
    function deposit()public payable returns (bool){
        require(msg.value>0);
        assert(accountMap[msg.sender]+msg.value>accountMap[msg.sender]);
        
        accountMap[msg.sender]+=msg.value;
        logDeposit(msg.sender,msg.value,accountMap[msg.sender]);
        return true;
    }

    //visibility stuff
    function getAccount(address player)public constant returns(uint){
        return accountMap[player];
    }
    function getCurrentGame(address player) public constant returns(address){
        return currentGame[player];
    }
    function getSeek(address player) public constant returns(address){
        return seekingMap[player];
    }
    function gameResult(address game) public constant returns(Result){
        return gamePairMap[game].result;
    }
}


