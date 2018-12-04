import 'dart:async';
import 'package:flutter/material.dart';

/// Root widget to activate [Journeys] in your app.
///
/// Place this at the root of your widget tree, even before you add your first [Navigator]
class Journeys extends StatefulWidget {
  final Widget child;

  const Journeys({Key key, @required this.child}) : assert(child != null);

  @override
  State<StatefulWidget> createState() => JourneysState();

  /// The state from the closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Journeys.of(context)
  ///   ..dispatch(YourJourneyAction());
  /// ```
  static JourneysState of(
    BuildContext context, {
    bool nullOk = false,
  }) {
    final JourneysState journey = context.ancestorStateOfType(const TypeMatcher<JourneysState>());
    assert(() {
      if (journey == null && !nullOk) {
        throw FlutterError(
            'Navigator operation requested with a context that does not include a Navigator.\n'
            'The context used to push or pop routes from the Navigator must be that of a '
            'widget that is a descendant of a Navigator widget.');
      }
      return true;
    }());
    return journey;
  }
}

/// Maintains the journeys state.
class JourneysState extends State<Journeys> {
  StreamController<dynamic> _controller;
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
    _controller = StreamController<dynamic>.broadcast(
        onListen: enableJourneyStreamUpdates, onCancel: disableJourneyStreamUpdates);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void dispatch(dynamic journeyAction) {
    if (hasActiveSubscribers) _controller.add(journeyAction);
  }
}

/// Handles new journey actions.
///
/// Instantiate this with appropriate callbacks in the widget which you want to make aware of
/// journey actions. Then call [subscribeToJourneyActions] in its [didChangeDependencies] method
/// and call [unsubscribeFromJourneyActions] in its [dispose] method.
class JourneyActionsHandler {
  StreamSubscription<dynamic> subscription;
  void Function(dynamic) onJourneyAction;
  void Function() onDone;
  void Function(dynamic, StackTrace) onError;

  JourneyActionsHandler({@required this.onJourneyAction, this.onError, this.onDone});

  JourneyActionsHandler._withNoHandler({this.onError, this.onDone});

  /// Adds the handler as a listener to journey action updates.
  ///
  /// Your [onJourneyAction] callback will be called each time there is a new journey action
  /// available. Call this during [didChangeDependencies] and pass the [JourneyDispatcher] from your
  /// widget tree as [journeysState].
  void subscribeToJourneyActions(BuildContext context) {
    assert(context != null,
        'The provided BuildContext is null. Make sure you call this method with a valid build context, e.g. in didChangeDependecies()');

    final journeysState = Journeys.of(context);

    assert(journeysState != null,
        'Journeys widget was not found. Make sure Journeys is an ancestor of the component from where you are calling this method.');
    if (subscription != null) return;

    subscription =
        journeysState._controller.stream.listen(onJourneyAction, onError: onError, onDone: onDone);
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

class TypedJourneyActionsHandler extends JourneyActionsHandler {
  var _typedActionHandlers = List<_TypedJourneyActionHandler>();

  TypedJourneyActionsHandler({onError, onDone})
      : super._withNoHandler(onError: onError, onDone: onDone) {
    // point the action handler to our [typedOnJourneyAction]
    onJourneyAction = _typedOnJourneyAction;
  }

  /// Adds a new journey action handler which will get called if the dispatched journey action is
  /// of type [ActionType]
  void addHandler<ActionType>(void Function(ActionType) f) {
    _typedActionHandlers.add(_TypedJourneyActionHandler<ActionType>(f));
  }

  /// Calls all [journeyActionHandlers] and passes the [journeyAction].
  ///
  /// The calls will only result in an actual journey handler call if there is one which can handle
  /// the type of the journey action.
  /// If there are multiple then all of them get called. It is not safe to make assuptions about the
  /// order in which they are called.
  void _typedOnJourneyAction(journeyAction) {
    for (var typedActionHandler in _typedActionHandlers) {
      typedActionHandler(journeyAction);
    }
  }
}

abstract class TypedJourneyActionsHandlerMixin<T extends StatefulWidget> extends State<T> {
  var typedJourneyActionsHandler = TypedJourneyActionsHandler();

  void setOnErrorJourneyHandler(void Function(dynamic, StackTrace) onError) {
    typedJourneyActionsHandler.onError = onError;
  }

  void setOnDoneJourneyHandler(void Function() onDone) {
    typedJourneyActionsHandler.onDone = onDone;
  }

  /// Adds a new journey action handler which will get called if the dispatched journey action is
  /// of type [ActionType]
  void addHandler<ActionType>(void Function(ActionType) f) {
    typedJourneyActionsHandler.addHandler(f);
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    print("called mixin didChangeDependencies");
    super.didChangeDependencies();
    typedJourneyActionsHandler.subscribeToJourneyActions(context);
  }

  @override
  @mustCallSuper
  void dispose() {
    print("called mixin dispose");
    typedJourneyActionsHandler.unsubscribeFromJourneyActions();
    super.dispose();
  }
}

class _TypedJourneyActionHandler<ActionType> {
  final void Function(ActionType) handlerFunction;

  _TypedJourneyActionHandler(this.handlerFunction);

  void call(dynamic journeyAction) {
    if (journeyAction is ActionType) handlerFunction(journeyAction);
  }
}
