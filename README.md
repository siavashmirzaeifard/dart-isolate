# dart-isolate

This project contains explanations and examples about isolate in Dart.

## Definition
Isolates are very useful in asynchronous programming that help's you to make sure that your Flutter application UI is not lagging.
Isolates are non-shared memory threads of codes that can run in parallel, and its similar to a program running in your computer and it will has it's own memory pool and inside the process you have the possibility to spawn your threads and those threads will share the same memory as your process. So inside that process you can share memory between your threads. Isolates have their own memory pool and they will also have their event loops.
An event loop inside an isolate is like a function that is carry out the actual functionality of your isolate. In this function you start at a point at the first line of your function and you're able to carry out your work, or you can even do asynchronous wokr inside your function so you don't have to return immediately, or also you may have a loop (event loop) and you can listen to incoming messages for instance from a source (like socket.io) and you can respond to them.
Isolates are somethings like two layer mechanism of the actual entrance to the isolate which is a function that usually returns a future for a stream, and this entrance will create isolate. The actual isolate code won't be inside this entrance. (Briefer: enterance is the function that you call which in itself then spawn a new isolate, and that isolate code itself where the main event loop actually happens which called the main function).
The "main" function in our Flutter applications is our main isolate that handle our event loops for our application, linke scrolling through or pressing buttons and etc.

## For more explanations:
Please go to lib/main.dart and follow the comments.

## Thanks to Vandad Nahavandipoor ->
- [Vandad's GitHub](https://github.com/vandadnp)
- [Vandad's LinkedIn](https://www.linkedin.com/in/vandadnp)
- [Vandad's YouTube Channel](https://www.youtube.com/channel/UC8NpGP0AOQ0kX9ZRcohiPeQ)
