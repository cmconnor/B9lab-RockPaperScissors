var RockPaperScissors = artifacts.require("./RockPaperScissors.sol");
var RPSJudge = artifacts.require("./RPSJudge.sol");
var hashDeadlineOffset=4;
var finalDeadlineOffset=4;
var gameCost=10;


contract('RockPaperScissors', function(accounts) {
  var rpsContract;
  var ownerAddress=accounts[0];
  var aliceAddress=accounts[1];
  var bobAddress=accounts[2];
  var carolAddress=accounts[3];
  var duderAddress=accounts[4];

  beforeEach(function(){
    return RockPaperScissors.new(gameCost,hashDeadlineOffset,finalDeadlineOffset)
    .then(function(instance){
        rpsContract=instance;
    });
   });

  it("deposit and withdrawal function properly", function() {
    var depositVal=100;
    var withdrawVal=50;
    return rpsContract.deposit.sendTransaction({from:aliceAddress,value:depositVal})
    .then(function(tx){
      return rpsContract.getAccount(aliceAddress)
    })
    .then(function(balance){
      assert.equal(balance,depositVal,"Alice's balance is off");
      return rpsContract.withdraw.sendTransaction(withdrawVal,{from:aliceAddress})
    })
    .then(function(tx){
      return rpsContract.getAccount(aliceAddress)
    })
    .then(function(balance){
      assert.equal(balance,withdrawVal,"Alice's balance is off");
    });
  });

  it("seek works properly", function() {
    var depositVal=100;
    return rpsContract.deposit.sendTransaction({from:aliceAddress,value:depositVal})
    .then(tx=>rpsContract.deposit.sendTransaction({from:bobAddress,value:depositVal}))
    .then(tx=>rpsContract.seekGame.sendTransaction(bobAddress,{from:aliceAddress}))
    .then(tx=>rpsContract.getSeek.call(aliceAddress,{from:aliceAddress}))
    .then(function(seekAddress){
      assert.equal(seekAddress,bobAddress,"seek address doesn't match input");
      return rpsContract.cancelSeek.sendTransaction({from:aliceAddress})
    })
    .then(tx=>rpsContract.getSeek.call(aliceAddress,{from:aliceAddress}))
    .then(function(seekAddress){
      assert.equal(seekAddress,0,"seek address isn't nil after cancellation");
    });
  });

  it("player matching and game play works properly", function() {
    var depositVal=100;
    var gameContract;
    var gameAddress;
    var amoveHash;
    var bmoveHash;
    var aMove=1; //reminder that 1=rock, 2=paper, 3=scissors. for now it is test by hand (change #'s, verify result.)
    var bMove=2;
    var aPw="hi";
    var bPw="there";
    var expectedResult=2; //reminder: 0=game not done, 1=player 1 wins, 2=player 2 wins, 3=tie

    return rpsContract.deposit.sendTransaction({from:aliceAddress,value:depositVal})
    .then(tx=>rpsContract.deposit.sendTransaction({from:bobAddress,value:depositVal}))
    .then(tx=>rpsContract.seekGame.sendTransaction(bobAddress,{from:aliceAddress}))
    .then(tx=>rpsContract.seekGame.sendTransaction(aliceAddress,{from:bobAddress}))
    .then(tx=>rpsContract.getSeek.call(aliceAddress,{from:aliceAddress}))
    .then(function(seekAddress){
      assert.equal(seekAddress,0,"alice seek address didn't nil after game made");
      return rpsContract.getSeek.call(bobAddress,{from:bobAddress})
    })
    .then(function(seekAddress){
      assert.equal(seekAddress,0,"bob seek address didn't nil after game made");
      return rpsContract.getCurrentGame.call(aliceAddress,{from:aliceAddress})
    })
    .then(function (_addr){
      gameAddress=_addr;
      gameContract=RPSJudge.at(_addr);
      return gameContract.hashMove.call(aliceAddress,aMove,aPw,{from:aliceAddress})
    })
    .then(function(moveHash){
      moveHash1=moveHash;
      return gameContract.submitMove.sendTransaction(moveHash,{from:aliceAddress}).catch(err=>console.log("alice submit err:"+err))
    })
    .then(function (tx){
      return gameContract.hashMove.call(bobAddress,bMove,bPw,{from:bobAddress})
    })
    .then(function(moveHash){
      moveHash2=moveHash;
      return gameContract.submitMove.sendTransaction(moveHash,{from:bobAddress}).catch(err=>console.log("bob submit err:"+err))
    })
    .then(tx=>rpsContract.deposit.sendTransaction({from:aliceAddress,value:depositVal}))//using to increment the block.number by 1
    .then(tx=>rpsContract.deposit.sendTransaction({from:aliceAddress,value:depositVal}))
    .then(tx=>gameContract.revealMove.sendTransaction(aMove,aPw,{from:aliceAddress}))
    .then(tx=>gameContract.revealMove.sendTransaction(bMove,bPw,{from:bobAddress}))
    .then(tx=>rpsContract.deposit.sendTransaction({from:bobAddress,value:depositVal}))
    .then(tx=>rpsContract.deposit.sendTransaction({from:aliceAddress,value:depositVal}))
    .then(tx=>rpsContract.deposit.sendTransaction({from:bobAddress,value:depositVal}))
    .then(tx=>rpsContract.deposit.sendTransaction({from:bobAddress,value:depositVal}))
    .then(tx=>rpsContract.deposit.sendTransaction({from:bobAddress,value:depositVal}))
    .then(tx=>rpsContract.resolveGame.sendTransaction({from:aliceAddress})).catch(err=>console.log("resolve err:"+err))
    .then(tx=>rpsContract.gameResult.call(gameAddress,{from:aliceAddress}))
    .then(function(result){
      console.log("result:"+result); //reminder: 0=game not done, 1=player 1 wins, 2=player 2 wins, 3=tie
      assert.equal(result.toNumber(),expectedResult,"result does not match expected result");
    })
  });
});
