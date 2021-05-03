pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

contract KYC_Verification{
    
    address admin;
    uint256 totalBanks;
    
    constructor() {
        admin = msg.sender;
        totalBanks = 0;
    }
    
    struct Customer {
        string userName;   
        string data;  
        bool kycStatus;
        uint256 Downvotes;
        uint256 Upvotes;
        address bank;
    }
    
    struct Bank {
        string name;
        address ethAddress;
        uint256 complaintsReported;
        uint256 KYC_count;
        bool isAllowedToVote;
        string regNumber;
    }

    struct KycRequest{
        string customerName;
        address bankAddress;
        string customerData;
    }
    
    mapping(string => Customer) customers;

    mapping(address => Bank) banks;

    mapping(string => KycRequest) kycRequest;

    // this is an interface to validate that request made by admin or not
    modifier onlyAdmin {
        require(msg.sender == admin, "You are not the admin.");
        _;
    }
    
    // this is an interface to varify the incoming request is from valid bank or not
    modifier isValidBank {
        require(
            banks[msg.sender].ethAddress != 0x0000000000000000000000000000000000000000 &&
            bytes(banks[msg.sender].name).length > 0 &&
            bytes(banks[msg.sender].regNumber).length > 0,
            "Not a valid bank account.");
        _;
    }
    
    modifier isCustomerExist(string memory _customerName){
        require(bytes(customers[_customerName].userName).length > 0, "Customer not exist with this name.");
        _;
    }
    
    modifier isBankExist(address _bankAddress) {
        require(
            _bankAddress != 0x0000000000000000000000000000000000000000 &&
            bytes(banks[_bankAddress].name).length > 0 &&
            bytes(banks[_bankAddress].regNumber).length > 0,
            "Bank dosen't exist with provided details."
            );
        _;
    }
    
    modifier ispermitedToVote {
        require(banks[msg.sender].isAllowedToVote == true, "Bank have no permission to cast vote.");
        _;
    }
    
    // function to add bank by onlyAdmin
    function addBank(string memory _bankName, address _bankAddress, string memory _regNumber) public onlyAdmin {
        require(_bankAddress != 0x0000000000000000000000000000000000000000, "Can't be an empty address.");
        require(
            keccak256(abi.encodePacked(banks[_bankAddress].name)) != keccak256(abi.encodePacked(_bankName)) &&
            keccak256(abi.encodePacked(banks[_bankAddress].regNumber)) != keccak256(abi.encodePacked(_regNumber)),
            "Bank alredy exist with provided details."
            );
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].regNumber = _regNumber;
        banks[_bankAddress].KYC_count = 0;
        banks[_bankAddress].isAllowedToVote = true;
        totalBanks += 1;
    }    
    
    // function to retrive bank details
    function viewBankDetails(address _bankAddress) public isBankExist(_bankAddress) view returns (Bank memory) {
        return banks[_bankAddress];
    }    
    
    // function viewBankDetails(address _bankAddress) public isBankExist(_bankAddress) view returns (string memory, address, uint256, uint256, bool, string memory) {
    //   return (
        //   banks[_bankAddress].name,
        //   banks[_bankAddress].ethAddress, 
        //   banks[_bankAddress].complaintsReported, 
        //   banks[_bankAddress].KYC_count, 
        //   banks[_bankAddress].isAllowedToVote, 
        //   banks[_bankAddress].regNumber
        //   );
    // }    
    
    // this function is to remove existing bank by admin
    function removeBank(address _bankAddress) public onlyAdmin isBankExist(_bankAddress) {
       delete banks[_bankAddress];
       totalBanks -= 1;
    }    
    
    // to view or listout the complaints on a perticular bank
    function getBankComplaints(address _bankAddress) public isBankExist(_bankAddress) view returns (uint256) {
       return banks[_bankAddress].complaintsReported;
    }    
    
    // to restrict bank's againest casting their votes
    function modifyBankIsAllowedToVote(address _bankAddress, bool isAllowedToVote) public onlyAdmin isBankExist(_bankAddress) {
         banks[_bankAddress].isAllowedToVote = isAllowedToVote;
    }    

    // to report any bank by oter banks
    function reportBank(address _bankAddress, string memory _bankName ) public isValidBank isBankExist(_bankAddress) {
        require(keccak256(abi.encodePacked(banks[_bankAddress].name)) == keccak256(abi.encodePacked(_bankName)), "Bank dosen't matched with provided name.");
        banks[_bankAddress].complaintsReported += 1;
        if(banks[_bankAddress].complaintsReported > totalBanks/3){
            banks[_bankAddress].isAllowedToVote = false;
        }
    } 
    
    // to rise a KYC request for customer by bank's
    function addRequest(string memory _customerName, string memory _customerData) public isValidBank {
        require(keccak256(abi.encodePacked(kycRequest[_customerName].customerName)) != keccak256(abi.encodePacked(_customerName)),"Customer alredy exists with this name.");
        kycRequest[_customerName].customerName = _customerName;
        kycRequest[_customerName].customerData = _customerData;
        kycRequest[_customerName].bankAddress = msg.sender;
        banks[msg.sender].KYC_count += 1;
        this.addCustomer(_customerName, _customerData);
    }
    
    // to cancle the KYC request of a customer
    function removeRequest(string memory _customerName) public isValidBank {
        require(kycRequest[_customerName].bankAddress == msg.sender,"Customer not exist in this bank.");
        require(bytes(customers[_customerName].userName).length > 0,"Customer not exist in this bank.");
        require(customers[_customerName].kycStatus == false, "Customer KYC approved, can't be remove.");
        delete kycRequest[_customerName];
        delete customers[_customerName];
    }
    
    // to add new customers into the system
    function addCustomer(string memory _userName, string memory _customerData) public  {
        require(bytes(customers[_userName].userName).length == 0, "Customer alredy exists with this name.");
        customers[_userName].userName = _userName;
        customers[_userName].data = _customerData;
        customers[_userName].Upvotes = 0;
        customers[_userName].Downvotes = 0;
        customers[_userName].kycStatus = false;
        customers[_userName].bank = msg.sender;
    }
    
    // to modify or re-update the customer data for new KYC request
    function modifyCustomer(string memory _userName, string memory _newcustomerData) public isValidBank isCustomerExist(_userName) {
        require(customers[_userName].bank == msg.sender, "Not an authorisd bank to modify customer.");
        this.removeRequest(_userName);
        customers[_userName].data = _newcustomerData;
        customers[_userName].Upvotes = 0;
        customers[_userName].Downvotes = 0;
    } 
    
    // to view customer details 
    function viewCustomer(string memory _userName) public isCustomerExist(_userName) view returns (Customer memory) {
        return customers[_userName];
    }
    
    // function viewCustomer(string memory _userName) public isCustomerExist(_userName) view returns (string memory, string memory, address, bool, uint, uint) {
    //     return (
    //         customers[_userName].userName,
    //         customers[_userName].data,
    //         customers[_userName].bank,
    //         customers[_userName].kycStatus,
    //         customers[_userName].Upvotes,
    //         customers[_userName].Downvotes
    //         );  
    // }
    
    // to vote customer to approve their KYC docs
    function upvoteCustomer(string memory _customerName) public isValidBank ispermitedToVote isCustomerExist(_customerName) {
        customers[_customerName].Upvotes += 1;
        if(customers[_customerName].Upvotes >= totalBanks/2 && customers[_customerName].Downvotes <= totalBanks/3){
            customers[_customerName].kycStatus = true;
        }
    }    
    
    // to vote customer to declain their KYC docs
    function downvoteCustomer(string memory _customerName) public isValidBank ispermitedToVote isCustomerExist(_customerName) {
        customers[_customerName].Downvotes += 1;
    }    

}    
