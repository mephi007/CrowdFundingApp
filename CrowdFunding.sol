pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minContri;
    uint public deadline;
    uint public target;
    uint public noOfContri;
    uint public raisedAmt; 

    constructor(uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline;
        minContri = 100 wei;
        manager = msg.sender;
    }

    function sendEth() public payable{
        require(block.timestamp < deadline, "DeadLine has passed");
        require(msg.value >= minContri, "Minimum Contribution is not met");
        if(contributors[msg.sender] == 0){
            noOfContri++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmt += msg.value;
    }

    function getContractBal() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline && raisedAmt < target, "you are not eligible");
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        raisedAmt -= contributors[msg.sender];
        contributors[msg.sender] = 0;
        noOfContri--;
    }

    struct Request{
        string desc;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    mapping(uint=>Request) public requests;
    uint public requestNum;


    modifier onlyManager{
        require(msg.sender == manager, " Only Manager Accessible");
        _;
    }

    function createRequest(string memory _desc, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[requestNum];
        requestNum++;
        newRequest.desc = _desc;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _reqNo) public{
        require(contributors[msg.sender] > 0, "not a contributor");
        Request storage thisReq = requests[_reqNo];
        require(thisReq.voters[msg.sender] == false, " Already Voted");
        thisReq.voters[msg.sender] = true;
        thisReq.noOfVoters++;
    }

    function makePayment(uint _reqNo) public onlyManager{
        require(raisedAmt >= target);
        Request storage thisReq = requests[_reqNo];
        require(thisReq.completed == false, "request has been completed");
        require(thisReq.noOfVoters > (noOfContri/2), "Majority do no support");
        thisReq.recipient.transfer(thisReq.value);
        thisReq.completed = true;
    }

}