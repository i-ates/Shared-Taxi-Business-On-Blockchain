pragma solidity >= 0.6.5;

contract taxi {
    
    struct Participant {
        address payable address1;
        uint account;
    }
    
    struct TaxiDriver {
        address payable address1;
        uint salary;
        uint account;
    }
    
    struct ProposedDriver {
        TaxiDriver taxiDriver;
        uint8 approvalState;
        mapping (address => bool) approvedParticipants;
    }
    
    struct ProposedCar {
        uint256 id;
        uint price;
        uint offerValidTime;
        uint8 approvalState;
        mapping (address => bool) approvedParticipants;
    }
    
    
    address payable public manager;
    address payable public carDealer;
    address payable[] public participantArray;
    mapping(address => Participant) public participants;
    uint256 public contractBalance=0;
    uint expenses = 10 ether;
    uint participationFee = 100 ether;
    TaxiDriver public taxiDriver;
    ProposedDriver proposedDriver;
    uint256 public ownedCar;
    ProposedCar proposedCar;
    ProposedCar proposedRepurchaseCar;
    uint256 startTime;
    uint256 lastSalaryTime;
    uint256 lastDividendTime;
    uint256 lastCarExpensesTime;
    

    modifier onlyManager {
        require(msg.sender == manager);
        _;
    }
    
    modifier onlyCarDealer {
        require(msg.sender == carDealer);
        _;
    }
    
    modifier onlyDriver {
        require(msg.sender == taxiDriver.address1);
        _;
    }
    
    modifier onlyParticipants {
        require(participants[msg.sender].address1 == msg.sender);
        _;
    }
    

    constructor() public {
        manager = msg.sender;
        startTime = now;
        lastDividendTime = now;
        lastCarExpensesTime = now;
    }
    


    function join() external payable {
        require(participantArray.length < 9);
        require(msg.value == 100 ether);
        require(participants[msg.sender].address1 != msg.sender);
        
        contractBalance += 100 ether;
        participants[msg.sender] = Participant({address1: msg.sender, account: 1 ether});
        participantArray.push(msg.sender);
    }
    
    
    function setCarDealer(address payable _carDealer) public onlyManager {
        carDealer = _carDealer;
    }
    
    
    function carProposeToBusiness(uint256 _carID, uint _price, uint _offerValidTime) public onlyCarDealer {
        proposedCar = ProposedCar({
            id: _carID,
            price: _price,
            offerValidTime: _offerValidTime,
            approvalState: 0
        });
        
        for (uint i = 0; i < participantArray.length; i++) {
            proposedCar.approvedParticipants[participantArray[i]] = false;
        }
    }
    
    function approvePurchaseCar() public onlyParticipants {
        require(proposedCar.approvedParticipants[msg.sender] == false, 'This participant already approved for this car.');

        proposedCar.approvedParticipants[msg.sender] = true;
        proposedCar.approvalState++;
    }
    
    function purchaseCar() public onlyManager {
        require(now < proposedCar.offerValidTime);
        require(proposedCar.approvalState > (participantArray.length / 2));
        
        ownedCar = proposedCar.id;
        carDealer.transfer(proposedCar.price);  // Transfer the price
    }
    
    function repurchaseCarPropose(uint256 _carID, uint _price, uint _offerValidTime) public onlyCarDealer {
        proposedRepurchaseCar = ProposedCar({
            id: _carID,
            price: _price,
            offerValidTime: _offerValidTime,
            approvalState: 0
        });
        
        for (uint i = 0; i < participantArray.length; i++) {
            proposedRepurchaseCar.approvedParticipants[participantArray[i]] = false;
        }
    }
    
    function approveSellProposal() public onlyParticipants {
        require(proposedRepurchaseCar.approvedParticipants[msg.sender] == false, 'This participant already approved for this car.');
        
        proposedRepurchaseCar.approvedParticipants[msg.sender] = true;
        proposedRepurchaseCar.approvalState++;
    }
    
    function repurchaseCar() public payable onlyCarDealer {
        require(now < proposedRepurchaseCar.offerValidTime && proposedRepurchaseCar.approvalState > (participantArray.length / 2));
    }
    
    function proposeDriver(address payable _driverAdress, uint _salary) public onlyManager {
        proposedDriver = ProposedDriver({
            taxiDriver: TaxiDriver({
                address1: _driverAdress,
                salary: _salary,
                account: 0
            }),
            approvalState: 0
        });
        
        for (uint i = 0; i < participantArray.length; i++) {
            proposedDriver.approvedParticipants[participantArray[i]] = false;
        }
    }
    
    function approveDriver() public onlyParticipants {
        require(proposedDriver.approvedParticipants[msg.sender] == false, 'This participant already approved for this car.');

        proposedDriver.approvedParticipants[msg.sender] = true;
        proposedDriver.approvalState++;
    }

    function setDriver() public onlyManager {
        require(proposedDriver.approvalState > (participantArray.length / 2), 'More than half of the participants must approve to be able to purchase the car.');

        taxiDriver = proposedDriver.taxiDriver;
        lastSalaryTime = now;
    }
    
    function fireDriver() public onlyManager {
        taxiDriver.account += taxiDriver.salary;
        contractBalance -= taxiDriver.salary;
    }
    
    function getCharge() public payable {
        contractBalance += msg.value;
    }

    function releaseSalary() public onlyManager {
        require(now >= lastSalaryTime + 30 days);
        lastSalaryTime = now;
        
        taxiDriver.account += taxiDriver.salary;
        contractBalance -= taxiDriver.salary;
    }

    function getSalary() public onlyDriver {
        require (taxiDriver.account > 0);
        
        uint tmp_account = taxiDriver.account;
        taxiDriver.account = 0;
        taxiDriver.address1.transfer(tmp_account);
    }

    function carExpenses() public onlyManager {
        require(now >= lastCarExpensesTime + 180 days);
        lastCarExpensesTime = now;
        
        contractBalance -= expenses;
        carDealer.transfer(expenses);
    }
    
    function payDividend() public onlyManager {
        require(now >= lastDividendTime + 180 days);
        
        carExpenses();
        releaseSalary();

        uint dividend = contractBalance / participantArray.length;
        for (uint i = 0; i < participantArray.length; i++) {
            participants[participantArray[i]].account += dividend;
            contractBalance -= dividend;
        }
        
        lastDividendTime = now;
    }
    
    function getDividend() public onlyParticipants {
        uint tmp_participant_balance = participants[msg.sender].account;
        participants[msg.sender].account = 0;
        msg.sender.transfer(tmp_participant_balance);
    }

    fallback() external {
        revert ();
    }
    
    receive() external payable {
        revert ();
    }
}