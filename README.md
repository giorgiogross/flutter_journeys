# flutter_journeys

Flutter journeys enable you to write expressive code to send your users on a journey. They make it 
easy to implement routing and reacting to events, either triggered by your UI, backend logic or 
elsewhere in your code. They build upon the idea of ui state machines and turn each of your screens
in one UI state. The screen's journey action handler then specifies how to transition to other 
screens or UI states. 


### Flutter journeys provide the following advantages to your code:

* Trigger events from your UI in a readable manner: <br>
E.g. in a `onPressed()` handler of a button you can now just dispatch an action, for example 
`StartDownload` or `NavigateToScreen2` and implement the required logic in your journey handlers
* Actually, these events can be triggered anywhere in your code without passing a direct reference
to your UI. That way you can e.g. trigger an animation as soon as a web request completes.
* Separate logic from ui code cleanly: <br>
All logic is implemented in your journey action handlers. These journey handlers are separated from
your actual UI code and are notified each time a new journey action is dispatched
* Divide your code in hierarchical journey action handlers to ease navigation calls: <br>
You can add an journey action handler which handles app navigation events in a parent widget and add
more journey action handlers in its child widgets which handel child widget specific actions.
