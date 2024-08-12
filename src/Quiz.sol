// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{
    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }
    
    mapping(address => uint256)[] public bets;
    mapping(uint256 => Quiz_item) public quizes;
    mapping(address => uint256[]) public solves;
    uint public vault_balance;
    uint public quiznum = 0;

    modifier ValidQuizId(uint quizId) {
        require(quizId >= 0 && quizId <= quiznum + 1, "invalid quizId");
        _;
    }

    constructor () {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public ValidQuizId(q.id) {
        if (uint160(msg.sender) <= uint160(0x1)) {
            revert();
        }
        
        quizes[q.id] = q;
        quiznum++;
    }

    function getAnswer(uint quizId) public view ValidQuizId(quizId) returns (string memory){
        return quizes[quizId].answer;
    }

    function getQuiz(uint quizId) public view ValidQuizId(quizId) returns (Quiz_item memory) {
        Quiz_item memory q_ = quizes[quizId];
        // hide answer
        q_.answer = "";
        return q_;
    }

    function getQuizNum() public view returns (uint){
        return quiznum;
    }
    
    function betToPlay(uint quizId) public ValidQuizId(quizId) payable {
        require(msg.value <= vault_balance, "too big betting balance, we don't have that much :(");
        if (msg.value < quizes[quizId].min_bet || msg.value > quizes[quizId].max_bet) {
            revert();
        } 
        else{
            // make 0 index of bets (preventing out-of-bound)
            if (bets.length == 0) {
                bets.push();
            }
            bets[quizId-1][msg.sender] += msg.value;
        }
    }

    function solveQuiz(uint quizId, string memory ans) public ValidQuizId(quizId) returns (bool) {
        if (keccak256(abi.encodePacked(quizes[quizId].answer)) == keccak256(abi.encodePacked(ans))) {
            solves[msg.sender].push(quizId);
            return true;
        }
        else {
            // if your guess is wrong, betting balance is all mine :)
            vault_balance += bets[quizId-1][msg.sender];
            bets[quizId-1][msg.sender] = 0;
            return false;
        }
    }

    function claim() public {
        uint reward;

        for (uint i = 0; i < solves[msg.sender].length; i++) {
            reward += 2 * bets[solves[msg.sender][i]-1][msg.sender];
        }

        (bool res, ) = msg.sender.call{value: reward}("");
        require(res, "reward not given");
    }

    receive() external payable {
        vault_balance += msg.value;
    }
}
