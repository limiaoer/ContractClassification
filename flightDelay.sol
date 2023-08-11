pragma solidity ^0.4.11;
contract FlightDelayContracts{

 /*DELAYED_PAYOUT, CANCELLED_PAYOUT, TICKET_PRICE, INSURANCE_PRICE: 
这些是合约中使用的常量，代表航班延误、取消、机票价格以及保险价格的数值。
InsuranceSet: 这是一个映射，用于记录每个地址（用户）是否购买了保险的状态。
owner: 这是合约的拥有者地址，即保险公司的地址。
claims: 这是一个映射，用于记录每个地址（用户）的理赔金额。
processStatus: 这是一个映射，用于记录每个地址（用户）的机票状态。
InsuranceLimit: 这是一个映射，用于记录每个地址（用户）购买保险的截止时间。
DepositLimit: 这是一个映射，用于记录每个地址（用户）支付保险金的截止时间。
DepositOk: 这是一个映射，用于记录每个地址（用户）是否支付了保险金。
*/
    //payout for insurance
    uint256 constant DELAYED_PAYOUT = 2;
    uint256 constant CANCELLED_PAYOUT = 2;
    uint256 constant TICKET_PRICE = 2;
    uint256 constant INSURANCE_PRICE = 1;

    mapping(address => bool) InsuranceSet; 
    address owner; 
    mapping(address => uint256) claims;         
    mapping(address => uint256) processStatus;   
    mapping(address => uint256) InsuranceLimit;  
    mapping(address => uint256) DepositLimit;    
    mapping(address => bool) DepositOk;
    mapping(address => bool) claimStatus;

    constructor() public payable{
        owner = msg.sender;}


    function buyTicket() payable{
        require(processStatus[msg.sender]!=1);
        require(msg.value >= TICKET_PRICE);
        InsuranceLimit[msg.sender] = block.timestamp + 3;
        processStatus[msg.sender] = 1;
        InsuranceSet[msg.sender] = false;
    }

  //RETURN flightStatuses={1,2,3,4,5}
    function refundTicket(){
        uint status;
        require(processStatus[msg.sender]==1);
        status = flightStatuses(msg.sender);
        require(status == 1);
        //require(!InsuranceSet[msg.sender]);
        claims[msg.sender] += TICKET_PRICE;
        processStatus[msg.sender] = 2;
    }

    function buyInsurance() payable{ 
        uint status;
    	require(!InsuranceSet[msg.sender]);
    	require(processStatus[msg.sender]==1);
        require(block.timestamp <= InsuranceLimit[msg.sender]);
        require(msg.value>=INSURANCE_PRICE);
        InsuranceSet[msg.sender] = true;
        claimStatus[msg.sender] = false;
        DepositLimit[msg.sender] = block.timestamp + 3;
        DepositOk[msg.sender] = false;
    }

    function depositInsurance(address addr) payable{ 
        require(owner==msg.sender);
        require(!DepositOk[addr]);
        require(processStatus[addr]==1);
        require(InsuranceSet[addr]);
        require(block.timestamp <= DepositLimit[addr]);
        require(msg.value >= 2);
        DepositOk[addr] = true;
    }


    function refundInsurance(){
        require(InsuranceSet[msg.sender]);
        require(block.timestamp > DepositLimit[msg.sender]);
        require(!DepositOk[msg.sender]);
        claims[msg.sender] += INSURANCE_PRICE;
        InsuranceSet[msg.sender] = false;
    }


//RETURN flightStatuses={1,2,3,4,5}
    function claimInsurance(){
        uint256 payout;
        uint status;
        require(processStatus[msg.sender]==1);
        //require(block.timestamp <= InsuranceLimit[msg.sender]);
    	require(InsuranceSet[msg.sender]);
    	//require(!claimStatus[msg.sender]);
        status = flightStatuses(msg.sender);
        require(status==4 || status ==5);
        if(!claimStatus[msg.sender]){
            if(status == 4){
                payout = DELAYED_PAYOUT + INSURANCE_PRICE;
                claims[owner] += TICKET_PRICE;
            }else{
                payout = CANCELLED_PAYOUT + INSURANCE_PRICE;
                claims[owner] += TICKET_PRICE;
            }
        }else{
            payout=0;
            claims[owner] += DELAYED_PAYOUT + TICKET_PRICE;
        }
        claimStatus[msg.sender] = true;
        claims[msg.sender] += payout;
    }


    function claimPayouts(){
        uint payout;
        payout = claims[msg.sender];
        msg.sender.transfer(payout);
        claims[msg.sender] = 0;
    }
}

/*这个合约实现了一个航班延误赔付系统，允许用户购买机票、购买保险、赔偿保险以及领取理赔金额。
以下是整个合约的总过程：
1.航班购票：
  用户调用buyTicket()函数购买机票，向合约发送足够的以太币（不小于TICKET_PRICE）。
  合约记录用户的购票状态，并设定购买保险的时间限制。
2.购买保险：
  用户可以在购票后调用buyInsurance()函数购买保险。
  用户需要在限定的时间范围内（InsuranceLimit）购买保险，并支付足够的以太币（不小于INSURANCE_PRICE）。
  购买保险后，合约记录用户的保险状态，保险生效，用户可以进行理赔。
3.保险公司预存赔偿金：
  保险公司可以调用depositInsurance()函数在用户购买保险后，在规定时间内预存赔偿金。
  保险公司需要支付足够的以太币（不小于2 ETH）作为赔偿金。
  用户在航班延误或取消时进行理赔时，可以领取赔偿金。
4.赔偿保险：
  用户在航班延误或取消时可以调用claimInsurance()函数申请理赔。
  用户必须在航班起飞前购买保险并且未领取过理赔金额才能进行理赔。
  如果用户之前未进行过理赔，合约会根据航班状态（延误或取消）计算理赔金额，并将理赔金额加到用户的理赔金额中。
  如果用户之前已经进行过理赔，合约会将理赔金额设置为0，并将延误赔付和机票费用加到保险公司的理赔金额中。
5.领取理赔金额：
  用户可以调用claimPayouts()函数领取理赔金额。
  合约会将用户的理赔金额转账给用户，并将用户的理赔金额设置为0，表示用户已领取理赔金。
*/