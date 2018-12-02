import 'dart:async';
import 'package:flutter/material.dart';

/// Journey action which is delivered to the callback provided in [JourneyActionsHandler].
///
/// Extend this class to provide your own journeys and to add instance fields to it.
abstract class JourneyAction {}

/// Root widget to activate [Journeys] in your app.
///
/// Place this at the root of your widget tree, even before you add your first [Navigator]
class Journeys extends StatefulWidget {
  final Widget child;

  const Journeys({Key key, @required this.child}) : assert(child != null);

  @override
  State<StatefulWidget> createState() => _JourneysState();
}

/// Maintains the journeys state.
class _JourneysState extends State<Journeys> {
  StreamController<JourneyAction> _controller;
  bool hasActiveSubscribers = false;

  void enableJourneyStreamUpdates() {
    hasActiveSubscribers = true;
  }

  void disableJourneyStreamUpdates() {
    hasActiveSubscribers = false;
  }

  @override
  void initState() {
    super.initState();
    _controller = StreamController<JourneyAction>.broadcast(
        onListen: enableJourneyStreamUpdates, onCancel: disableJourneyStreamUpdates);
  }

  @override
  Widget build(BuildContext context) => JourneyDispatcher(
        this,
        child: widget.child,
      );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

/// Maintains the [_JourneysState] and makes it accessible to [JourneyActionHandler].
class JourneyDispatcher extends InheritedWidget {
  final _JourneysState _journeys;

  JourneyDispatcher(this._journeys, {Key key, @required child}) : super(key: key, child: child);

  void dispatch(JourneyAction journey) {
    if (_journeys.hasActiveSubscribers) _journeys._controller.add(journey);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  static JourneyDispatcher of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(JourneyDispatcher);
}

/// Handles new journey actions.
///
/// Instantiate this with appropriate callbacks in the widget which you want to make aware of
/// journey actions. Then call [subscribeToJourneyActions] in its [didChangeDependencies] method
/// and call [unsubscribeFromJourneyActions] in its [dispose] method.
class JourneyActionsHandler {
  StreamSubscription<JourneyAction> subscription;
  void Function(JourneyAction) onJourneyAction;
  void Function() onDone;
  void Function(dynamic, StackTrace) onError;

  JourneyActionsHandler({@required this.onJourneyAction, this.onError, this.onDone});

  /// Adds the handler as a listener to journey action updates.
  ///
  /// Your [onJourneyAction] callback will be called each time there is a new journey action
  /// available. Call this during [didChangeDependencies] and pass the [JourneyDispatcher] from your
  /// widget tree as [journeyDispatcher].
  void subscribeToJourneyActions(JourneyDispatcher journeyDispatcher) {
    assert(journeyDispatcher != null);
    if (subscription != null) return;

    subscription = journeyDispatcher._journeys._controller.stream
        .listen(onJourneyAction, onError: onError, onDone: onDone);
  }

  /// Removes the handler from the journey actions listeners.
  ///
  /// No updates will be passed to your [onJourneyAction] callback anymore until you subscribe again
  /// to updates. Updates which occur while this handler is not subscribed to them will be lost.
  void unsubscribeFromJourneyActions() {
    subscription?.cancel();
    subscription = null;
  }
}
