**get the code**
```
 svn checkout http://betfairfree.googlecode.com/svn/trunk/ betfairfree
 cd betfairfree
```

**create a session**

quite a good first port of call, it will (naturally) check your library dependencies and try to get a API session using your betfair.com login details.

```
 perl -I./lib _t/session.pl -u username -p password
```

**check your avaiable balance**
```
 perl -I./lib _t/getAccountFunds.pl -u username -p password
```

**log a market's best prices, every 10 seconds**
```
 perl -I./lib _t/log_best_prices.pl -u username -p password -interval 10 -m marketid
```

See the [sample logs](http://betfairfree.googlecode.com/svn/trunk/docs/sample-logs/) for a look at the output of this program.

**place a £2 bet on a market at odds of 2.43**
```
 perl -I./lib _t/place_a_bet.pl -u [user] -p [pass] -m 21031232 -s 123512 -b 2.00 -o 2.43 -back
```

**generate a 300px by 500px graph for YAML data source foo.txt, cap any odds over 100/1**
```
 ./perl -I./lib _t/yml_grapher.pl -d foo.txt -h 300 -w 500 -c 100
```

See the [sample graphs](http://betfairfree.googlecode.com/svn/trunk/docs/sample-graphs/) for a look at the output of this program.