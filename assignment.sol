pragma solidity >=0.7.0 <0.8.0;

contract tradeContract{
    
    // Seller list [address and name]
    mapping(address => string) public seller;
    
    // item structure description
    int public itemCount = 0;
    int public delta = 10;
    struct item{
        int itemID;			// item ID
        int price;		// item price
        int qty; //item quantity
        address selleraddress;	// seller address (of address type)
    }
    mapping(int=>item) public items;

    // Order structure description
    int public orderCount = 0;
    struct order{
        int ordrid;					//order ID
        int item_id;				//item ID in order
        int qty;					//order qty
        string buyerName;			// order buyer name
        int sellingPrice;           //price buyer willing to pay
        string status;				// order status
        string delivery_address;		// order delivery address
        address buyer_address;          //item buyer address
    }
    mapping(int => order) public orders;

    struct bid{
        int ordrid;					//order ID
        int item_id;				//item ID in order
        int qty;					//order qty
        // string buyerName;			// order buyer name
        int currentBid;           //price buyer willing to pay
        int nextBid;           //next buyer must pay more than the current bid
        string status;				// order status
        // string delivery_address;		// order delivery address
        address buyer_address;          //item buyer address
    }
    mapping(int => bid) public bids;

    

    // seller registration authentication
    modifier registerSellerAuth() {
        require(bytes(seller[msg.sender]).length == 0);
        _;
    }
    
    // Item addition authentication
    modifier addItemAuth() {
        require(bytes(seller[msg.sender]).length > 0);
        _;
    }

    //***********PUBLICLY AVAILABLE GETTER FUNCTION**********
    // for buyer side
    function getItemDetailsById(int _itmid) view public returns (int, int) {
        require(_itmid <= itemCount);
        return (items[_itmid].itemID, items[_itmid].price);
    }

    //*********************SELLER-SIDE AVAILABLE FUNCTIONS**************
    // seller registration status getter function
    function isSellerRegistered(address _addr) view public returns (bool) {
		
		// if seller address is not set, return false
        if(bytes(seller[_addr]).length == 0){
            return (false);
        }else{
            return (true);
        }
    }

    // seller registration setter function
    function registerSeller(string memory _name) public registerSellerAuth {
        seller[msg.sender] = _name;
    }

    // new item setter function
    function additem_S( int _itemID, int _price, int _qty) public addItemAuth {
        
	  itemCount += 1; // just update the item count
	  // and place the item details in item[UPDATED_PCOUNT]
        items[itemCount] = item(itemCount, _price, _qty, msg.sender);
    }
    
    // item count at a seller getter function
    function getitemCount_S(address _addr) view public returns (int) {
        int icount = 0; int i;
        for(i=1; i <= itemCount; i++){
            if(items[i].selleraddress == _addr){
                icount++;
            }
        }
        return (icount);
    }
    // PRICE UPDATE setter function /// need to set the bid option
    function updatePrice_S(int _itemID, int _newPrice) public {
        require(items[_itemID].selleraddress == msg.sender);
        items[_itemID].price = _newPrice;
    }

    // all order getter function
    function getOrderCount_S(address _addr) view public returns (int) {
        int ocount = 0; int i;
	  
        for(i=1; i <= orderCount; i++){
            if(items[orders[i].item_id].selleraddress == _addr){
                ocount++;
            }
        }
        return (ocount);
    }

    // next order getter function
    function getNextOrderById_S(address _addr,int _oid) view public returns(int,int,int,string memory,string memory,string memory, bool) {
         
	   require(_oid <= orderCount); // to make sure that order id < orderCount
         
	   // address authentication
	   if(items[orders[_oid].item_id].selleraddress==_addr){
		// if valid, return order
             return (orders[_oid].ordrid, orders[_oid].item_id, orders[_oid].qty, orders[_oid].buyerName, orders[_oid].status, orders[_oid].delivery_address, true);
         }
         return (0,0,0,"","","",false);
    }

    // order status setter function
    function updateOrderStatus_S(int _oid, string memory _status) public {
    
        require(items[orders[_oid].item_id].selleraddress == msg.sender); // producer authentication
	  
	  // if order status is rejected, then
        if (keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked("Rejected"))) {
		//take the items from the item struct and place in orders struct
            items[orders[_oid].item_id].qty+=orders[_oid].qty;
            orders[_oid].status = _status; // and update status
        }else{
		// else....
            if(keccak256(abi.encodePacked(orders[_oid].status))!=keccak256(abi.encodePacked("Rejected"))&&
            keccak256(abi.encodePacked(_status))==keccak256(abi.encodePacked("Delivered"))){
			// just update the order status. 
                orders[_oid].status = _status;
            }
        }
    }
    
    // new order setter function
    function placeOrder_S(string memory _bname, string memory _daddress, address _bAddress, int _itemID, int _qty, int _sellingPrice) public {
        
	require(items[_itemID].qty >= _qty); // making sure there are enough items
    int i;
    for(i=1; i <= orderCount; i++){
      require(items[orders[i].item_id].selleraddress == msg.sender &&  items[orders[i].item_id].price == bids[_itemID].currentBid);
    }
        orderCount += 1;
        orders[orderCount] = order(orderCount, _itemID, _qty, _bname, _sellingPrice, "Placed", _daddress, msg.sender);
        items[_itemID].qty -= _qty; // after adding item, deduct the qty
    }
    

    //*********************BUYER-SIDE AVAILABLE FUNCTIONS**************
    
    // new Bid order setter function
    function placeBid_B(string memory _bname, string memory _daddress, int _itemID, int _qty, int _sellingPrice) public {
        
	  require(items[_itemID].qty >= _qty); // making sure there are enough items
        
        orderCount += 1;
        //orders[orderCount] = order(orderCount, _itemID, _qty, _bname, _sellingPrice, "Placed", _daddress, msg.sender);
        bids[orderCount] = bid(orderCount, _itemID, _qty, _sellingPrice, _sellingPrice+delta, "Live",  msg.sender);
        items[_itemID].qty -= _qty; // after adding item, deduct the qty
    }
    
    // order getter function buyer authenticated
    function getOrderCount_B(address _addr) view public returns (int) {
        int counter = 0; int i;
        for(i=1; i <= orderCount; i++){
		// buyer authentication
            if(_addr == orders[i].buyer_address){
                counter++;
            }
        }
        return (counter);
    }
    
    function getNextOrderById_B(address _addr, int _oid) view public returns (int, int, int, string memory, string memory, string memory, bool){
		require(_oid <= orderCount); // making sure the orderID is less than order count
		
		// if buyer address is authenticated
		if(_addr==orders[_oid].buyer_address){
			
			// then return next order
		    return (orders[_oid].ordrid, orders[_oid].item_id, orders[_oid].qty, orders[_oid].buyerName, orders[_oid].status, orders[_oid].delivery_address, true);
		}
        return (0, 0, 0, "", "", "", false); 
    }

    // buyer bid price function
    function bidPrice_B(int _newBid, int _itemID, int _qty ) public {
        
	    // require(items[_itemID].qty >= _qty); // making sure there are enough items
        require(bids[_itemID].nextBid <= _newBid ); //
        // orderCount += 1;

        // orders[orderCount] = order(orderCount, _itemID, _qty, _bname, _sellingPrice, "Placed", _daddress, msg.sender);
        // items[_itemID].qty -= _qty; // after adding item, deduct the qty
        bids[_itemID].currentBid = _newBid; //after updating bid price, update the price of the item
        bids[_itemID].nextBid = _newBid + delta; 
        items[_itemID].price = _newBid;
    }


}