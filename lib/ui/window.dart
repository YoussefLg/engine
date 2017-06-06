// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

/// Signature of callbacks that have no arguments and return no data.
typedef void VoidCallback();

/// Signature for [Window.onBeginFrame].
typedef void FrameCallback(Duration duration);

/// Signature for [Window.onPointerDataPacket].
typedef void PointerDataPacketCallback(PointerDataPacket packet);

/// Signature for [Window.onSemanticsAction].
typedef void SemanticsActionCallback(int id, SemanticsAction action);

/// Signature for responses to platform messages.
///
/// Used as a parameter to [Window.sendPlatformMessage] and
/// [Window.onPlatformMessage].
typedef void PlatformMessageResponseCallback(ByteData data);

/// Signature for [Window.onPlatformMessage].
typedef void PlatformMessageCallback(String name, ByteData data, PlatformMessageResponseCallback callback);

/// States that an application can be in.
///
/// The values below describe notifications from the operating system.
/// Applications should not expect to always receive all possible
/// notifications. For example, if the users pulls out the battery from the
/// device, no notification will be sent before the application is suddenly
/// terminated, along with the rest of the operating system.
///
/// See also:
///
///  * [WidgetsBindingObserver], for a mechanism to observe the lifecycle state
///    from the widgets layer.
enum AppLifecycleState {
  /// The application is visible and responding to user input.
  resumed,

  /// The application is in an inactive state and is not receiving user input.
  ///
  /// On iOS, this state corresponds to an app running in the foreground
  /// inactive state. Apps transition to this state when in a phone call,
  /// responding to a TouchID request, or when entering the app switcher. Apps
  /// in this state should assume that they may be [paused] at any time.
  ///
  /// On Android, this state is currently unused.
  inactive,

  /// The application is not currently visible to the user, not responding to
  /// user input, and running in the background.
  ///
  /// When the application is in this state, the engine will not call the
  /// [Window.onBeginFrame] and [Window.onDrawFrame] callbacks.
  ///
  /// Apps in this state should assume that they may be [suspended] at any
  /// time.
  paused,

  /// The application will be suspended momentarily.
  ///
  /// When the application is in this state, the engine will not call the
  /// [Window.onBeginFrame] and [Window.onDrawFrame] callbacks.
  ///
  /// On iOS, this state is currently unused.
  suspending,
}

/// A representation of distances for each of the four edges of a rectangle,
/// used to encode the padding that applications should place around their user
/// interface, as exposed by [Window.padding].
///
/// For a generic class that represents distances around a rectangle, see the
/// [EdgeInsets] class.
///
/// See also:
///
///  * [WidgetsBindingObserver], for a widgets layer mechanism to receive
///    notifications when the padding changes.
///  * [MediaQuery.of], a simpler mechanism for the same.
///  * [Scaffold], which automatically applies the padding in material design
///    applications.
class WindowPadding {
  const WindowPadding._({ this.left, this.top, this.right, this.bottom });

  /// The distance from the left edge to the first unobscured pixel, in physical pixels.
  final double left;

  /// The distance from the top edge to the first unobscured pixel, in physical pixels.
  final double top;

  /// The distance from the right edge to the first unobscured pixel, in physical pixels.
  final double right;

  /// The distance from the bottom edge to the first unobscured pixel, in physical pixels.
  final double bottom;

  /// A window padding that has zeros for each edge.
  static const WindowPadding zero = const WindowPadding._(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0);
}

/// An identifier used to select a user's language and formatting preferences,
/// consisting of a language and a country. This is a subset of locale
/// identifiers as defined by BCP 47.
///
/// See also:
///
///  * [Window.locale], which specifies the system's currently selected
///    [Locale].
class Locale {
  /// Creates a new Locale object. The first argument is the
  /// primary language subtag, the second is the region subtag.
  ///
  /// For example:
  ///
  /// ```dart
  /// const Locale swissFrench = const Locale('fr', 'CH');
  /// const Locale canadianFrench = const Locale('fr', 'CA');
  /// ```
  const Locale(this.languageCode, this.countryCode);

  /// The primary language subtag for the locale.
  final String languageCode;

  /// The region subtag for the locale.
  final String countryCode;

  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! Locale)
      return false;
    final Locale typedOther = other;
    return languageCode == typedOther.languageCode
        && countryCode == typedOther.countryCode;
  }

  int get hashCode {
    int result = 373;
    result = 37 * result + languageCode.hashCode;
    result = 37 * result + countryCode.hashCode;
    return result;
  }

  String toString() => '${languageCode}_$countryCode';
}

/// The most basic interface to the host operating system's user interface.
///
/// There is a single Window instance in the system, which you can
/// obtain from the [window] property.
class Window {
  Window._();

  /// The number of device pixels for each logical pixel. This number might not
  /// be a power of two. Indeed, it might not even be an integer. For example,
  /// the Nexus 6 has a device pixel ratio of 3.5.
  ///
  /// Device pixels are also referred to as physical pixels. Logical pixels are
  /// also referred to as device-independent or resolution-independent pixels.
  ///
  /// By definition, there are roughly 38 logical pixels per centimeter, or
  /// about 96 logical pixels per inch, of the physical display. The value
  /// returned by [devicePixelRatio] is ultimately obtained either from the
  /// hardware itself, the device drivers, or a hard-coded value stored in the
  /// operating system or firmware, and may be inaccurate, sometimes by a
  /// significant margin.
  ///
  /// The Flutter framework operates in logical pixels, so it is rarely
  /// necessary to directly deal with this property.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio = 1.0;

  /// The dimensions of the rectangle into which the application will be drawn,
  /// in physical pixels.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  Size get physicalSize => _physicalSize;
  Size _physicalSize = Size.zero;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the application can render, but over which the operating system will
  /// likely place system UI (such as the Android system notification area), or
  /// which might be rendered outside of the physical display (e.g. overscan
  /// regions on television screens).
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  ///  * [Scaffold], which automatically applies the padding in material design
  ///    applications.
  WindowPadding get padding => _padding;
  WindowPadding _padding = WindowPadding.zero;

  /// A callback that is invoked whenever the [devicePixelRatio],
  /// [physicalSize], or [padding] values change, for example when the device is
  /// rotated or when the application is resized (e.g. when showing applications
  /// side-by-side on Android).
  VoidCallback onMetricsChanged;

  /// The system-reported locale.
  ///
  /// This establishes the language and formatting conventions that application
  /// should, if possible, use to render their user interface.
  ///
  /// The [onLocaleChanged] callback is called whenever this value changes.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  Locale get locale => _locale;
  Locale _locale;

  /// A callback that is invoked whenever [locale] changes value.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback onLocaleChanged;

  /// A callback that is invoked to notify the application that it is an
  /// appropriate time to provide a scene using the [SceneBuilder] API and the
  /// [render] method. When possible, this is driven by the hardware VSync
  /// signal. This is only called if [scheduleFrame] has been called since the
  /// last time this callback was invoked.
  ///
  /// The [onDrawFrame] callback is invoked immediately after [onBeginFrame],
  /// after draining any microtasks (e.g. completions of any [Future]s) queued
  /// by the [onBeginFrame] handler.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  FrameCallback onBeginFrame;

  /// A callback that is invoked for each frame after [onBeginFrame] has
  /// completed and after the microtask queue has been drained. This can be
  /// used to implement a second phase of frame rendering that happens
  /// after any deferred work queued by the [onBeginFrame] phase.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  VoidCallback onDrawFrame;

  /// A callback that is invoked when pointer data is available.
  ///
  /// See also:
  ///
  ///  * [GestureBinding], the Flutter framework class which manages pointer
  ///    events.
  PointerDataPacketCallback onPointerDataPacket;

  /// The route or path that the operating system requested when the application
  /// was launched.
  String get defaultRouteName => _defaultRouteName();
  String _defaultRouteName() native "Window_defaultRouteName";

  /// Requests that, at the next appropriate opportunity, the [onBeginFrame]
  /// and [onDrawFrame] callbacks be invoked.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  void scheduleFrame() native "Window_scheduleFrame";

  /// Updates the application's rendering on the GPU with the newly provided
  /// [Scene]. This function must be called within the scope of the
  /// [onBeginFrame] or [onDrawFrame] callbacks being invoked. If this function
  /// is called a second time during a single [onBeginFrame]/[onDrawFrame]
  /// callback sequence or called outside the scope of those callbacks, the call
  /// will be ignored.
  ///
  /// To record graphical operations, first create a [PictureRecorder], then
  /// construct a [Canvas], passing that [PictureRecorder] to its constructor.
  /// After issuing all the graphical operations, call the
  /// [PictureRecorder.endRecording] function on the [PictureRecorder] to obtain
  /// the final [Picture] that represents the issued graphical operations.
  ///
  /// Next, create a [SceneBuilder], and add the [Picture] to it using
  /// [SceneBuilder.addPicture]. With the [SceneBuilder.build] method you can
  /// then obtain a [Scene] object, which you can display to the user via this
  /// [render] function.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  void render(Scene scene) native "Window_render";

  /// Whether the user has requested that [updateSemantics] be called when
  /// the semantic contents of window changes.
  ///
  /// The [onSemanticsEnabledChanged] callback is called whenever this value
  /// changes.
  bool get semanticsEnabled => _semanticsEnabled;
  bool _semanticsEnabled = false;

  /// A callback that is invoked when the value of [semanticsEnabled] changes.
  VoidCallback onSemanticsEnabledChanged;

  /// A callback that is invoked whenever the user requests an action to be
  /// performed.
  ///
  /// This callback is used when the user expresses the action they wish to
  /// perform based on the semantics supplied by [updateSemantics].
  SemanticsActionCallback onSemanticsAction;

  /// Change the retained semantics data about this window.
  ///
  /// If [semanticsEnabled] is true, the user has requested that this funciton
  /// be called whenever the semantic content of this window changes.
  ///
  /// In either case, this function disposes the given update, which means the
  /// semantics update cannot be used further.
  void updateSemantics(SemanticsUpdate update) native "Window_updateSemantics";

  /// Sends a message to a platform-specific plugin.
  ///
  /// The `name` parameter determines which plugin receives the message. The
  /// `data` parameter contains the message payload and is typically UTF-8
  /// encoded JSON but can be arbitrary data. If the plugin replies to the
  /// message, `callback` will be called with the response.
  void sendPlatformMessage(String name,
                           ByteData data,
                           PlatformMessageResponseCallback callback) {
    _sendPlatformMessage(name, callback, data);
  }
  void _sendPlatformMessage(String name,
                            PlatformMessageResponseCallback callback,
                            ByteData data) native "Window_sendPlatformMessage";

  /// Called whenever this window receives a message from a platform-specific
  /// plugin.
  ///
  /// The `name` parameter determines which plugin sent the message. The `data`
  /// parameter is the payload and is typically UTF-8 encoded JSON but can be
  /// arbitrary data.
  ///
  /// Message handlers must call the function given in the `callback` parameter.
  /// If the handler does not need to respond, the handler should pass `null` to
  /// the callback.
  PlatformMessageCallback onPlatformMessage;

  /// Called by [_dispatchPlatformMessage].
  void _respondToPlatformMessage(int responseId, ByteData data)
      native "Window_respondToPlatformMessage";
}

/// The [Window] singleton. This object exposes the size of the display, the
/// core scheduler API, the input event callback, the graphics drawing API, and
/// other such core services.
final Window window = new Window._();
