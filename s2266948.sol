//SPDX-License-Identifier:UNLICENSED
pragma solidity >=0.7.0 <0.9.0;


contract DiceGame {
    mapping(address => uint256) balance;
    mapping(address => bytes32) hashes;
    mapping(address => uint256) values;
    address payable playerA;
    address payable playerB;
    uint initgas;
    uint rand;
    uint internal gameState = 1;
    mapping(uint => string) gameStateInfo;
    
    constructor() {
        gameStateInfo[1] = "Game not started";
        gameStateInfo[2] = "One player registered";
        gameStateInfo[3] = "Two players registered";
        gameStateInfo[4] = "One player revealed";
        gameStateInfo[5] = "Two players revealed";
        gameStateInfo[6] = "Dice roll evaluated";
        gameStateInfo[7] = "One person withdrew";
    }

    function initialize() internal {
        delete hashes[playerA];
        delete hashes[playerB];
        delete values[playerA];
        delete values[playerB];
        delete playerA;
        delete playerB;
        delete rand;
        gameState = 1;
    }

    function cancel() public {
        require(msg.sender == playerA || msg.sender == playerB, "restricted call");
        require(gameState < 5, "cannot cancel after dice roll");
        if (gameState < 4) {
            uint sentamount = balance[playerA] + 0;
            balance[playerA] = 0;
            playerA.transfer(sentamount*10**18);

            sentamount = balance[playerB] + 0;
            balance[playerB] = 0;
            playerB.transfer(sentamount*10**18);
        }
        if (gameState == 4) {
            if (values[playerA] == 0) {
                if (msg.sender == playerA) {
                    playerB.transfer(6 * 1 ether);
                    balance[playerB] = 0;
                } else {
                    playerA.transfer(3 * 1 ether);
                }
                balance[playerA] = 0;
            } 
            else {
                if (msg.sender == playerB) {
                    playerA.transfer(6 * 1 ether);
                    balance[playerA] = 0;
                } else {
                    playerB.transfer(3 * 1 ether);
                }
                balance[playerB] = 0;
            } 

        }
        initialize();
    }


    function viewState() public view returns(string memory)  {
        return gameStateInfo[gameState];
    }

    //// register

    function register(address coplayer, bytes32 hash) public payable {
        require(msg.value >= 3 ether, "registered value less than 3 ");
        require(coplayer != address(0), "enter a valid address");
        require(msg.sender != coplayer, "cannot play with the same account");

        uint gas = gasleft();

        if (gameState > 5) {
            initialize();
        }
        if ((playerA == address(0) && playerB == address(0))) {
            require(gameState == 1, "Invalid Function Call");
            playerA = payable(msg.sender); 
            playerB = payable(coplayer);
            balance[msg.sender] = 3;
            gameState = 2;
            initgas += (gas - gasleft())*tx.gasprice;
        } else {
            require(playerB == msg.sender && playerA == coplayer, "Invalid address");
            require(gameState == 2, "Invalid Function Call");
            balance[msg.sender] = 3;
            gameState = 3;
            initgas -= (gas - gasleft())*tx.gasprice;
        }

        hashes[msg.sender] = hash;
        initgas += initgas/2;
    }

    ////// reaveal

    function reveal(uint value) public {
        require(isVerified(value), "unverifiable value");
        require(msg.sender == playerA || msg.sender == playerB, "access restricted");
        require(values[msg.sender] == 0, "value already revealed");
        require(gameState == 3 || gameState == 4, "logic flow error");


        values[msg.sender] = value;
        gameState++;
        if (gameState == 5){
            rand = getRand();
            if (rand > 3) {
                balance[playerA] = (6 - rand) * 1 ether + initgas;
                balance[playerB] =     (rand) * 1 ether + initgas;
            } else {
                balance[playerA] = (3 + rand) * 1 ether + initgas;
                balance[playerB] = (3 - rand) * 1 ether - initgas;
            }
            gameState++;
        }
    }

    function isVerified(uint value) private view returns(bool) {
        return hashes[msg.sender] == keccak256(abi.encodePacked(value, msg.sender));
    }

    function getRand() private view returns(uint) {
        return (values[playerA] ^ values[playerB]) % 6 + 1;
    }

    /////// withdraw

    function withdraw() public {
        uint sentamount = balance[msg.sender] + 0;
        balance[msg.sender] = 0;
        payable(msg.sender).transfer(sentamount);
    }
}
