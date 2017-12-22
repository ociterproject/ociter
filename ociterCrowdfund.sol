pragma solidity ^0.4.16;

/**
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract token { function transfer(address receiver, uint amount){  } }
contract OciterCrowdsale {
  using SafeMath for uint256;

  // uint256 durationInMinutes;
  // address where funds are collected
  address public wallet;
  // token address
  address addressOfTokenUsedAsReward;

  token tokenReward;



  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTimeInMinutes;
  uint256 public endTimeinMinutes;
  uint public fundingGoal = 5800000000000000000;
  uint public minimumFundingGoal = 4544731519985457;
  uint256 public price;
  // amount of raised money in wei
  uint256 public weiRaised;
  
  
  mapping(address => uint256) public balanceOf;
  bool fundingGoalReached = false;
  bool crowdsaleClosed = false;
  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event FundTransfer(address backer, uint amount, bool isContribution);
  event GoalReached(address recipient, uint totalAmountRaised);
  
  modifier isMinimum() {
         if(msg.value < 4544731519985457) throw;
        _;
    }
    
  modifier afterDeadline() { 
      if (now <= endTimeinMinutes) throw;
      _;
  }    

  function OciterCrowdsale(uint256 _startTimeInMinutes, 
  uint256 _endTimeInMinutes, 
  address _beneficiary, 
  address _addressTokenUsedAsReward,
  uint256 _tokenConvertioninEther) {
    wallet = _beneficiary;
    // durationInMinutes = _durationInMinutes;
    addressOfTokenUsedAsReward = _addressTokenUsedAsReward;
    price = _tokenConvertioninEther;
    tokenReward = token(addressOfTokenUsedAsReward);
    //startTime = now + 28250 * 1 minutes;
    startTimeInMinutes = now + _startTimeInMinutes * 1 minutes;
    endTimeinMinutes = startTimeInMinutes + _endTimeInMinutes * 1 minutes;
    
    //endTime = startTime + 64*24*60 * 1 minutes;
  }

  // fallback function can be used to buy tokens
  function () payable isMinimum{
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be sent
    uint256 tokens = (weiAmount) * price;
    
    
    // update state
    balanceOf[msg.sender] += weiAmount;
    weiRaised = weiRaised.add(weiAmount);
    tokenReward.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
  
  
  //withdrawal or refund for investor and beneficiary
  function safeWithdrawal() afterDeadline {
        if ((weiRaised >= fundingGoal || weiRaised >= minimumFundingGoal) && wallet == msg.sender) {
            if (wallet.send(weiRaised)) {
                FundTransfer(wallet, weiRaised, false);
                GoalReached(wallet, weiRaised);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }


  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTimeInMinutes && now <= endTimeinMinutes;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTimeinMinutes;
  }
 
}