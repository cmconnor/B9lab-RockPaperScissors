var RockPaperScissors = artifacts.require("./RockPaperScissors.sol");
var hashDeadlineOffset=5;
var finalDeadlineOffset=5;
var gameCost=10;

module.exports = function(deployer) {
    deployer.deploy(RockPaperScissors,gameCost,hashDeadlineOffset,finalDeadlineOffset);
  
};
