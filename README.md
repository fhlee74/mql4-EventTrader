# mql4-EventTrader
This is an MT4 Expert Advisor that help traders to set a schedule to trade News.
This EA supports the following:
1. Opens buy + sell stop-orders at specific time (GMT).
2. Configurable number of pips AWAY from current ask/bid for the StopOrders.
3. Implements OCO (One Cancels the Other) when Stops are triggered.
4. Closes executed trades with x-pip profit (aka TP level).
5. Configurable Time-to-Live for un-triggered stop-orders after x-seconds.

This repo/code is part of a StackOverflow question/request:
https://stackoverflow.com/questions/55930471/how-can-i-cancel-a-trade-when-another-is-open-and-keep-the-open-trade-for-a-give

I am putting this into GitHub so that everyone can use it, and for others to build and improve upon it.
