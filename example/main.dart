import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_journeys/flutter_journeys.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Journeys(
      child: MaterialApp(
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
          // counter didn't reset back to zero; the application is not restarted.
          primarySwatch: Colors.blue,
        ),
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Screen1(),
          '/screen2': (BuildContext context) => Screen2()
        },
      ),
    );
  }
}

class Screen1 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => Screen1State();
}

class Screen1State extends State<Screen1> {
  JourneyActionsHandler journeyHandler;

  Screen1State() {
    journeyHandler = JourneyActionsHandler(onJourneyAction: onJourneyAction);
  }

  void onJourneyAction(JourneyAction journeyAction) {
    if (journeyAction is NavigateToScreen2Action) {
      Navigator.of(context).pushNamed('/screen2');
      print('Navigated to screen 2 and got payload data ${journeyAction.somePayloadData}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Screen 1"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            RaisedButton(
              onPressed: () {
                JourneyDispatcher.of(context).dispatch(NavigateToScreen2Action(123));
              },
              child: Text("Go to Screen 2"),
            )
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    journeyHandler.subscribeToJourneyActions(JourneyDispatcher.of(context));
  }

  @override
  void dispose() {
    journeyHandler.unsubscribeFromJourneyActions();
    super.dispose();
  }
}

class Screen2 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => Screen2State();
}

class Screen2State extends State<Screen2> with TickerProviderStateMixin {
  JourneyActionsHandler journeyHandler;
  AnimationController animationController;

  double animationRadius = 0.0;
  double animationOpacity = 1.0;

  Screen2State() {
    journeyHandler = JourneyActionsHandler(onJourneyAction: onJourneyAction);

    // show a splash animation after 2 seconds
    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        // with journeys you simply dispatch the journey action here. The actual animation will take
        // place in your handler implementation so that this part of your code remains clean and
        // readable. You could also dispatch a journey action for example after making a web request
        // in order to animate new data updates on the screen. With journeys you don't need a direct
        // reference to your UI code, just a reference to the [JourneyDispatcher] which takes care
        // of distributing the journey action properly. As long as there is a widget which is
        // interested in the journey action its handler will get called.
        // This helps you to decouple your UI code from your logic code.
        JourneyDispatcher.of(context).dispatch(AnimateSplasher());
      }
    });
  }

  void onJourneyAction(JourneyAction journeyAction) {
    if (journeyAction is NavigateToScreen1Action) {
      Navigator.of(context).pop();
      print('Navigated back to screen 1 and got payload data ${journeyAction.somePayloadData}');
    }

    if (journeyAction is AnimateSplasher) {
      print('Starting the splash animation!');

      animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..addListener(
            () {
          setState(() {
            animationRadius = lerpDouble(
              Splasher.startAnimationRadius,
              Splasher.endAnimationRadius,
              animationController.value,
            );
            animationOpacity = 1.0 - animationController.value;
          });
        },
      );

      animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Screen 2"),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Splasher(
              radius: animationRadius,
              opacity: animationOpacity,
            ),
            RaisedButton(
              onPressed: () {
                // this will be processed by all action handlers which are currently subscribed
                // and have a proper implementation to handle [NavigateToScreen1Action]s
                JourneyDispatcher.of(context).dispatch(NavigateToScreen1Action(456));
              },
              child: Text("Back to Screen 1"),
            )
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    journeyHandler.subscribeToJourneyActions(JourneyDispatcher.of(context));
  }

  @override
  void dispose() {
    journeyHandler.unsubscribeFromJourneyActions();
    super.dispose();
  }
}

class Splasher extends StatelessWidget {
  final double radius;
  final double opacity;

  static double startAnimationRadius = 0.0;
  static double endAnimationRadius = 400.0;

  const Splasher({Key key, this.radius, this.opacity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.green[300],
            width: 18.0 * opacity, // just makes the line thinner and thinner
          ),
        ),
      ),
    );
  }
}

class NavigateToScreen1Action extends JourneyAction {
  final int somePayloadData;

  NavigateToScreen1Action(this.somePayloadData);
}

class NavigateToScreen2Action extends JourneyAction {
  final int somePayloadData;

  NavigateToScreen2Action(this.somePayloadData);
}

class AnimateSplasher extends JourneyAction {}
