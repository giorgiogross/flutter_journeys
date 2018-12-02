# flutter_built_redux_journeys

Navigator extension based on flutter_built_redux



Interface:

A station has the methods
* start
* restart
* travel

and can be used to define top level navigation behaviour as well as low level navigation through 
mixin/inheritance and still provides abilities to implement TickerProviderMixin etc.
In a station the normal flutter navigator is used for routing.
The generic station does not care about animation and is not depending on its child ui (there is no 
platform anymore..)
The journey actions can be dispatched from anywhere in the code.
A station may observe navigation events but we drop that if it's possible
There are no stations anymore. There are only Journey instances. The state is maintained in JourneyState
A Journey is a normal stateful widget in the widget tree and can be obtained by Journey.of(). This
way all its properties (ui state variables, animation controller, vsync, etc) can be obtained by its
sub-widgets


## Let me take you on a journey..
..That's the metaphor used in this package: All user interaction is interpreted as a Journey 
(routes). Journeys start at (train) stations (screens) which may have different platform (platform 
A, B, nine and three quarters, .. in fact different views within the station which can be visited 
without traveling to a new station). Traveling to a new station (screen) means leaving this station, 
doing some transitions and ending up a the new station. There, we start a new Journey and so on.

<hr>

### Theoretical Background
The ui flow is defined through an ui state machine encapsulated by the [Journey] class. Each main 
screen (route) resembles a ui state (subclasses [Journey]). Each of those states can declare its own 
state variables and constructor in the subclass and implements the travel() function which takes the 
previous state and a redux action. Based on that information the new ui state (next station or 
platform) is computed which might be the same state with different state variables or a completely 
new state. In the latter case we speak of 'a new journey starting at that station'.

Also navigating to other screens is handled here. If a UI wants to respond to certain events these 
events need to be encapsulated in an action. These actions are called JourneyActions throughout this 
package and are solely handled by the ui state machines. You can call them whatever you like in your
application code. Handling other actions (e.g. some that also update the app state) in ui state 
machines can cause unpredictable behaviour (due to built_redux or some other framework, currently 
unclear). As a ui state has access to the build context and the active presenter a ui state machine 
is able to directly update the ui (well, that's the whole point of it, isn't it?) by using 
down-casts in the state machine and public functions in the StoreConnector implementation. For 
general cases the built context should be sufficient but you can always get more fancy and add 
custom functions to your StoreConnector..


### Understanding state division and responsibilities
Generally spoken, every time user data should be updated your app state reducers are used; whenever 
the ui state should change your [Journey] implementation is addressed to perform the changes. Thus, 
passing data to a new screen is twofold: As all ui state data is maintained by the journey instances 
ui state variables are passed to the new ui state (e.g. if the next screen needs to know what his 
previous screen was this information may be passed to the new screen's journey constructor). Passing 
raw user data is usually done by updating the app state; the data is then loaded lazily by the new 
screen through flutter_built_redux. However, if the data is volatile it may also be passed to the 
journey constructor.

The actual StoreConnector and StoreConnectorChild constructors should not be used to pass any data 
to the instances except for when the data is only needed once. This is caused by the design decision 
that all state information resides in the app state, never in the widgets. Thus, the widgets will 
not save and maintain passed parameters in their state. An exception are animation values as it is 
more performant (and not of interest for any other component) storing animation values directly in 
the widget.


### Bugs
* Having a modal route (e.g. a bottom sheet) on a screen and pushing a new route on top without 
popping the modal route first leads to journey state inconsistencies when the covering route is 
popped.