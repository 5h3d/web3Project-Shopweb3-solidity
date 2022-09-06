//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
// 2. Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";


error notOwner();
error zeroEthSent();
error transferFailed();

contract Shopweb3{


    receive() external payable { 
    
    }

     uint256 s_transactionId;
     address immutable i_owner;
     address[] private s_customers;

     AggregatorV3Interface priceFeed;
   
    
    event TransactionEvent(
        
        address from,
        uint256 timestamp,
        uint256[] productId,
        string[] productName,
        uint256 price,
        OrderState orderState
        
    );
    event StatusChanged(
        
        address from,
        uint256 timestamp,
        uint256[] productId,
        string[] productName,
        uint256 price,
        OrderState orderState
    );

    constructor(){
        
        i_owner = msg.sender; 
        s_transactionId = 0;
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
       
    }
        
    
    enum OrderState{
        pending,
        confirmed,
        delivered, 
        cancelled
    }

    struct CustomerInfo{
        address from;
        uint256 time;
        uint256[] productId;
        string[] productName;
        uint256 totalAmount;
        uint256[] itemAmount;
        OrderState orderState;
        uint256[] productQuantity;
        string email;
        string userAddress;
        string city;
        string country;
        string phoneNumber; 
        uint256 transactionId;
    }


    mapping (address => uint256) private customerToCustomerCount;
    mapping (address => mapping(uint256 => CustomerInfo)) private transactionArray;
    mapping (address => bool) private isAddress;

    CustomerInfo[] private allOrders;
    OrderState private orderState;


     modifier onlyOwner {
      if(msg.sender == i_owner){
         revert notOwner();
      }
      _;
     }

   

    function makePayment(uint256[] memory _productId, string[] memory  _itemName, uint256 _totalAmount, uint256[] memory _itemAmount, uint256[] memory _productQuantity, string memory _email, string memory _userAddress, string memory _city, string  memory country, string memory _phoneNumber) public payable{

      
        transactionArray[msg.sender][customerToCustomerCount[msg.sender]] = CustomerInfo(msg.sender,block.timestamp,_productId,_itemName,_totalAmount, _itemAmount, OrderState.pending, _productQuantity, _email, _userAddress, _city,country,_phoneNumber, s_transactionId );
        customerToCustomerCount[msg.sender] = customerToCustomerCount[msg.sender] + 1;
        allOrders.push(CustomerInfo(msg.sender,block.timestamp,_productId,_itemName,_totalAmount, _itemAmount, OrderState.pending, _productQuantity, _email, _userAddress, _city,country,_phoneNumber, s_transactionId ));
        emit TransactionEvent(msg.sender,block.timestamp,_productId,_itemName,_totalAmount, OrderState.pending);
        s_transactionId++;

        if(isAddress[msg.sender] == false){
             s_customers.push(msg.sender);
             isAddress[msg.sender] = true;
        }


    }
     function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
    
 

   
    function getCustomerCount(address customerAddress) public view returns(uint256){
        return customerToCustomerCount[customerAddress];
    }
  

    

    function customerTransactions() public view returns(CustomerInfo[] memory){
        
        CustomerInfo[] memory id = new CustomerInfo[](customerToCustomerCount[msg.sender]);

        for (uint256 i = 0; i < customerToCustomerCount[msg.sender]; i++){

            CustomerInfo storage maps = transactionArray[msg.sender][i];
            id[i] = maps;
        }
        return id;  
    }

    function getAllOrders() public view returns(CustomerInfo[] memory){
        return allOrders;
       
    }

    


    function getAllCustomers() public  view returns (address[] memory){

        return s_customers;
    }

    function withdraw() public onlyOwner{
        
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        if(!success){
            revert transferFailed();
        }
    }

   function isACustomer(address _customerAddress) public view returns(bool){
       return isAddress[_customerAddress];
   }

    function confirmOrder(address _customerAddress, uint256 _customerId) public onlyOwner{
        transactionArray[_customerAddress][_customerId].orderState = OrderState.confirmed;
    }
    function cancelOrder(address _customerAddress, uint256 _customerId) public onlyOwner{
        transactionArray[_customerAddress][_customerId].orderState = OrderState.cancelled;
    }

    
}
