import 'package:flutter/widgets.dart';

/// 全 App 共用的路由觀察者（掛在 main.dart 的 MaterialApp.navigatorObservers）。
///
/// 頁面可以用 RouteAware 訂閱，在「上面的頁面關掉、自己重新顯示」時收到
/// didPopNext()，用來重新讀取資料。例如聲影日記首頁：寫完日記在完成頁按
/// 「回首頁」後，首頁要馬上顯示「已完成今天的紀錄」和月曆照片。
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
