//+------------------------------------------------------------------+
//|																	SO55930471.mq4 |
//|					  Copyright 2019, Joseph Lee, joseph.lee@fs.com.my |
//|														  TELEGRAM @JosephLee74 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Joseph Lee, TELEGRAM @JosephLee74"
#property link		"http://www.fs.com.my"
#property version	"1.00"
#property strict


//-------------------------------------------------------------------
// APPLICABLE PARAMETERS
//-------------------------------------------------------------------
//-------------------------------------------------------------------
// NEWS IMPACT SELECTION
//===================================================================
extern string		vsEAComment							= "Telegram @JosephLee74";		//Ego trip
extern datetime	vdTradeStartInGMT					= D'2019.5.14 06:00';			//When to trade (GMT)
extern int			viStopOrderLevelInPip			= 5;					// StopOrder distance from ask/bid (pips)
extern double		viFixLots							= 0.01;				// Lot size
extern int			viStopLossInPip					= 20;					// StopLoss (pips)
extern int			viTargetProfitInPip				= 100;				// TargetProfit (pips)
extern int			viDeleteStopOrderAfterInSec	= 30;					// StopOrder TTL (sec)
extern int			viDeleteOpenOrderAfterInSec	= 300;				// Executed Order TTL (sec)
extern int			viMaxSlippageInPip				= 2;					// Max Slippage (pip)


//-------------------------------------------------------------------
// System Variables
//-------------------------------------------------------------------
int		viMagicId					= 0;
double	viPipsToPrice				= 0.0001;
double	viPipsToPoint				= 1;
int		viBuyStopTicket			= -1;
int		viSellStopTicket			= -1;
int		viBuyOrderTicket			= -1;
int		viSellOrderTicket			= -1;
string	vsDisplay					= "EVENT-TRADER v1.01 - ";

//-------------------------------------------------------------------



//+------------------------------------------------------------------+
//| EA Initialization function
//+------------------------------------------------------------------+
int init() {
	ObjectsDeleteAll();	Comment("");
	// Caclulate PipsToPrice & PipsToPoints (old sytle, but works)
	if((Digits == 2) || (Digits == 3)) {viPipsToPrice=0.01;}
	if((Digits == 3) || (Digits == 5)) {viPipsToPoint=10;}
	viMagicId = vdTradeStartInGMT;
	start();
	return(0);
}
//+------------------------------------------------------------------+
//| EA Stand-Down function
//+------------------------------------------------------------------+
int deinit() {
	ObjectsDeleteAll();
	return(0);
}

 
//============================================================
// MAIN EA ROUTINE
//============================================================
int start() {

	//==========================================
	//MANAGE ROBOT EXPIRY
	//==========================================
	if( TimeCurrent() > D'2020.1.1' ) {
		Comment(vsDisplay + "EXPIRED. Please contact josephfhlee74 at gmail dot com"); // Who am I kidding?
		return(0);
	}
	
	
	ResetLastError();
	// Exit the routine if it is not time to trade yet.
	if(TimeGMT() < vdTradeStartInGMT) {
		// Show a count-down timer to the trading time.
		Comment(vsDisplay +
			"[" + TimeToStr(TimeGMT()) + " GMT] " + 
			IntegerToString(int(vdTradeStartInGMT - TimeGMT())) + " sec to [" + 
			TimeToStr(vdTradeStartInGMT) + " GMT]"
		);
		return(0);
	}
	
	
	viBuyStopTicket		= -1;
	viSellStopTicket		= -1;
	viBuyOrderTicket		= -1;
	viSellOrderTicket		= -1;
	Comment("MT4 EVENT TRADER BOT (v1.01): [GMT " + TimeToStr(TimeGMT()) + "] Executing ...");
	
	
	//=========================================================
	//FIND *OPENED* BUY/SELL PENDING ORDERS
	//---------------------------------------------------------
	for( int i=OrdersTotal()-1; i>=0; i-- ) {
		if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES ))
			if( OrderSymbol() == Symbol() )
				if( OrderMagicNumber() == viMagicId) {
					if( OrderType() == OP_BUYSTOP )
						viBuyStopTicket  = OrderTicket();
					if( OrderType() == OP_SELLSTOP )
						viSellStopTicket  = OrderTicket();
					if( OrderType() == OP_BUY )
						viBuyOrderTicket  = OrderTicket();
					if( OrderType() == OP_SELL )
						viSellOrderTicket  = OrderTicket();
				}
	}
	//=========================================================
	//FIND *CLOSED* BUY/SELL ORDERS FOR THIS EVENT
	//---------------------------------------------------------
	for(int i=OrdersHistoryTotal()-1; i>=0; i--) {
		if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
			if(OrderSymbol() == Symbol())
				if(OrderMagicNumber() == viMagicId) {
					if( OrderType() == OP_BUYSTOP )
						viBuyStopTicket  = OrderTicket();
					if( OrderType() == OP_SELLSTOP )
						viSellStopTicket  = OrderTicket();
					if( OrderType() == OP_BUY )
						viBuyOrderTicket  = OrderTicket();
					if( OrderType() == OP_SELL )
						viSellOrderTicket  = OrderTicket();
				}
	}
	// The above 2 sections will ensure that each event will only be executed once.
	// If orders are cancelled or closed for whatever reason, they will never be open again.
	
	
	//=========================================================
	// HANDLES OCO (One-Cancels-the-Other)
	//---------------------------------------------------------
	// BUY Order EXISTS, cancels all SellStops
	if( viBuyOrderTicket != -1 ) {
		for( int i=OrdersTotal()-1; i>=0; i-- ) {
			if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES ))
				if( OrderSymbol() == Symbol() )
					if( OrderMagicNumber() == viMagicId)
						if( OrderType() == OP_SELLSTOP )
							OrderDelete(OrderTicket());
		}
	}
	// SELL Order EXISTS, cancels all BuyStops
	if( viSellOrderTicket != -1 ) {
		for( int i=OrdersTotal()-1; i>=0; i-- ) {
			if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES ))
				if( OrderSymbol() == Symbol() )
					if( OrderMagicNumber() == viMagicId)
						if( OrderType() == OP_BUYSTOP )
							OrderDelete(OrderTicket());
		}
	}

	//=========================================================
	//CLOSE EXPIRED STOP/EXECUTED ORDERS
	//---------------------------------------------------------
	for( int i=OrdersTotal()-1; i>=0; i-- ) {
		if(OrderSelect( i, SELECT_BY_POS, MODE_TRADES ))
			if( OrderSymbol() == Symbol() )
				if( OrderMagicNumber() == viMagicId) {
					if( (OrderType() == OP_BUYSTOP) || (OrderType() == OP_SELLSTOP) )
						if((TimeCurrent()-OrderOpenTime()) >= viDeleteStopOrderAfterInSec)
							OrderDelete(OrderTicket());
					if( (OrderType() == OP_BUY) || (OrderType() == OP_SELL) )
						if((TimeCurrent()-OrderOpenTime()) >= viDeleteOpenOrderAfterInSec)
							OrderDelete(OrderTicket());
				}
	}



	//===================================================================
	//OPEN STOP ORDERS IF NO EXISTING nor CLOSED NO BUY/SELL STOP/ORDERS
	//-------------------------------------------------------------------
	// Do NOT execute (place new orders) if it is past the trading window.
	if(TimeGMT() >= (vdTradeStartInGMT+viDeleteStopOrderAfterInSec))
	{
		Comment(vsDisplay + "[" + TimeToStr(TimeGMT()) + " GMT] " + "Already passed execution time.");
		return(0);
	}
	// Place BuyStop if not exists; and no executed-Buy order
	if( (viBuyStopTicket == -1) && (viBuyOrderTicket == -1)) {
		viFixLots		= NormalizeDouble(viFixLots, 2);
		double viPrice = NormalizeDouble(Ask + (viStopOrderLevelInPip*viPipsToPrice), Digits);
		double viSL	 = viPrice - (viStopLossInPip*viPipsToPrice);
		double viTP	 = viPrice + (viTargetProfitInPip*viPipsToPrice);
		viBuyStopTicket	  =	OrderSend(Symbol(), OP_BUYSTOP, viFixLots
										, viPrice
										, int(viMaxSlippageInPip*viPipsToPoint)
										, viSL, viTP
										, vsEAComment, viMagicId, 0, Blue);
		if(viBuyStopTicket == -1)
			Print("Error executing BuyStop [" + IntegerToString(GetLastError()) + "]." );
	}
	// Place SellStop if not exists; and no executed-Sell order
	if( (viSellStopTicket == -1) && (viSellOrderTicket == -1) ) {
		RefreshRates();
		viFixLots		= NormalizeDouble(viFixLots, 2);
		double viPrice	= NormalizeDouble(Bid - (viStopOrderLevelInPip*viPipsToPrice), Digits);
		double viSL		= viPrice + (viStopLossInPip*viPipsToPrice);
		double viTP		= viPrice - (viTargetProfitInPip*viPipsToPrice);
		viSellStopTicket	  =	OrderSend(Symbol(), OP_SELLSTOP, viFixLots
										, viPrice
										, int(viMaxSlippageInPip*viPipsToPoint)
										, viSL, viTP
										, vsEAComment, viMagicId, 0, Red);
		if(viSellStopTicket == -1)
			Print("Error executing SellStop [" + IntegerToString(GetLastError()) + "]." );
	}
	return(0);
}