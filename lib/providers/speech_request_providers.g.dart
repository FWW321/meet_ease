// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speech_request_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$meetingSpeechRequestsHash() =>
    r'f6d638bac82aed1f43fd06e5e9e16a709662e505';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 会议发言申请列表提供者
///
/// Copied from [meetingSpeechRequests].
@ProviderFor(meetingSpeechRequests)
const meetingSpeechRequestsProvider = MeetingSpeechRequestsFamily();

/// 会议发言申请列表提供者
///
/// Copied from [meetingSpeechRequests].
class MeetingSpeechRequestsFamily
    extends Family<AsyncValue<List<SpeechRequest>>> {
  /// 会议发言申请列表提供者
  ///
  /// Copied from [meetingSpeechRequests].
  const MeetingSpeechRequestsFamily();

  /// 会议发言申请列表提供者
  ///
  /// Copied from [meetingSpeechRequests].
  MeetingSpeechRequestsProvider call(String meetingId) {
    return MeetingSpeechRequestsProvider(meetingId);
  }

  @override
  MeetingSpeechRequestsProvider getProviderOverride(
    covariant MeetingSpeechRequestsProvider provider,
  ) {
    return call(provider.meetingId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'meetingSpeechRequestsProvider';
}

/// 会议发言申请列表提供者
///
/// Copied from [meetingSpeechRequests].
class MeetingSpeechRequestsProvider
    extends AutoDisposeFutureProvider<List<SpeechRequest>> {
  /// 会议发言申请列表提供者
  ///
  /// Copied from [meetingSpeechRequests].
  MeetingSpeechRequestsProvider(String meetingId)
    : this._internal(
        (ref) =>
            meetingSpeechRequests(ref as MeetingSpeechRequestsRef, meetingId),
        from: meetingSpeechRequestsProvider,
        name: r'meetingSpeechRequestsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingSpeechRequestsHash,
        dependencies: MeetingSpeechRequestsFamily._dependencies,
        allTransitiveDependencies:
            MeetingSpeechRequestsFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingSpeechRequestsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.meetingId,
  }) : super.internal();

  final String meetingId;

  @override
  Override overrideWith(
    FutureOr<List<SpeechRequest>> Function(MeetingSpeechRequestsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeetingSpeechRequestsProvider._internal(
        (ref) => create(ref as MeetingSpeechRequestsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        meetingId: meetingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SpeechRequest>> createElement() {
    return _MeetingSpeechRequestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingSpeechRequestsProvider &&
        other.meetingId == meetingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, meetingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MeetingSpeechRequestsRef
    on AutoDisposeFutureProviderRef<List<SpeechRequest>> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingSpeechRequestsProviderElement
    extends AutoDisposeFutureProviderElement<List<SpeechRequest>>
    with MeetingSpeechRequestsRef {
  _MeetingSpeechRequestsProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingSpeechRequestsProvider).meetingId;
}

String _$currentSpeechHash() => r'9def9445dab72d44a991692cdaa4fdf31673b802';

/// 当前正在进行的发言提供者
///
/// Copied from [currentSpeech].
@ProviderFor(currentSpeech)
const currentSpeechProvider = CurrentSpeechFamily();

/// 当前正在进行的发言提供者
///
/// Copied from [currentSpeech].
class CurrentSpeechFamily extends Family<AsyncValue<SpeechRequest?>> {
  /// 当前正在进行的发言提供者
  ///
  /// Copied from [currentSpeech].
  const CurrentSpeechFamily();

  /// 当前正在进行的发言提供者
  ///
  /// Copied from [currentSpeech].
  CurrentSpeechProvider call(String meetingId) {
    return CurrentSpeechProvider(meetingId);
  }

  @override
  CurrentSpeechProvider getProviderOverride(
    covariant CurrentSpeechProvider provider,
  ) {
    return call(provider.meetingId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'currentSpeechProvider';
}

/// 当前正在进行的发言提供者
///
/// Copied from [currentSpeech].
class CurrentSpeechProvider extends AutoDisposeFutureProvider<SpeechRequest?> {
  /// 当前正在进行的发言提供者
  ///
  /// Copied from [currentSpeech].
  CurrentSpeechProvider(String meetingId)
    : this._internal(
        (ref) => currentSpeech(ref as CurrentSpeechRef, meetingId),
        from: currentSpeechProvider,
        name: r'currentSpeechProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$currentSpeechHash,
        dependencies: CurrentSpeechFamily._dependencies,
        allTransitiveDependencies:
            CurrentSpeechFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  CurrentSpeechProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.meetingId,
  }) : super.internal();

  final String meetingId;

  @override
  Override overrideWith(
    FutureOr<SpeechRequest?> Function(CurrentSpeechRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentSpeechProvider._internal(
        (ref) => create(ref as CurrentSpeechRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        meetingId: meetingId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SpeechRequest?> createElement() {
    return _CurrentSpeechProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentSpeechProvider && other.meetingId == meetingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, meetingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentSpeechRef on AutoDisposeFutureProviderRef<SpeechRequest?> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _CurrentSpeechProviderElement
    extends AutoDisposeFutureProviderElement<SpeechRequest?>
    with CurrentSpeechRef {
  _CurrentSpeechProviderElement(super.provider);

  @override
  String get meetingId => (origin as CurrentSpeechProvider).meetingId;
}

String _$speechRequestCreatorHash() =>
    r'0a9a3660931be30ea0bc2f39414bdf936dbc1c88';

/// 创建发言申请提供者
///
/// Copied from [SpeechRequestCreator].
@ProviderFor(SpeechRequestCreator)
final speechRequestCreatorProvider = AutoDisposeAsyncNotifierProvider<
  SpeechRequestCreator,
  SpeechRequest?
>.internal(
  SpeechRequestCreator.new,
  name: r'speechRequestCreatorProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$speechRequestCreatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SpeechRequestCreator = AutoDisposeAsyncNotifier<SpeechRequest?>;
String _$speechRequestManagerHash() =>
    r'd8c0aca43ec216853e6475b934923bcf7200876e';

abstract class _$SpeechRequestManager
    extends BuildlessAutoDisposeAsyncNotifier<SpeechRequest?> {
  late final String requestId;

  FutureOr<SpeechRequest?> build(String requestId);
}

/// 管理发言申请提供者
///
/// Copied from [SpeechRequestManager].
@ProviderFor(SpeechRequestManager)
const speechRequestManagerProvider = SpeechRequestManagerFamily();

/// 管理发言申请提供者
///
/// Copied from [SpeechRequestManager].
class SpeechRequestManagerFamily extends Family<AsyncValue<SpeechRequest?>> {
  /// 管理发言申请提供者
  ///
  /// Copied from [SpeechRequestManager].
  const SpeechRequestManagerFamily();

  /// 管理发言申请提供者
  ///
  /// Copied from [SpeechRequestManager].
  SpeechRequestManagerProvider call(String requestId) {
    return SpeechRequestManagerProvider(requestId);
  }

  @override
  SpeechRequestManagerProvider getProviderOverride(
    covariant SpeechRequestManagerProvider provider,
  ) {
    return call(provider.requestId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'speechRequestManagerProvider';
}

/// 管理发言申请提供者
///
/// Copied from [SpeechRequestManager].
class SpeechRequestManagerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          SpeechRequestManager,
          SpeechRequest?
        > {
  /// 管理发言申请提供者
  ///
  /// Copied from [SpeechRequestManager].
  SpeechRequestManagerProvider(String requestId)
    : this._internal(
        () => SpeechRequestManager()..requestId = requestId,
        from: speechRequestManagerProvider,
        name: r'speechRequestManagerProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$speechRequestManagerHash,
        dependencies: SpeechRequestManagerFamily._dependencies,
        allTransitiveDependencies:
            SpeechRequestManagerFamily._allTransitiveDependencies,
        requestId: requestId,
      );

  SpeechRequestManagerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.requestId,
  }) : super.internal();

  final String requestId;

  @override
  FutureOr<SpeechRequest?> runNotifierBuild(
    covariant SpeechRequestManager notifier,
  ) {
    return notifier.build(requestId);
  }

  @override
  Override overrideWith(SpeechRequestManager Function() create) {
    return ProviderOverride(
      origin: this,
      override: SpeechRequestManagerProvider._internal(
        () => create()..requestId = requestId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        requestId: requestId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<SpeechRequestManager, SpeechRequest?>
  createElement() {
    return _SpeechRequestManagerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SpeechRequestManagerProvider &&
        other.requestId == requestId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, requestId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SpeechRequestManagerRef
    on AutoDisposeAsyncNotifierProviderRef<SpeechRequest?> {
  /// The parameter `requestId` of this provider.
  String get requestId;
}

class _SpeechRequestManagerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          SpeechRequestManager,
          SpeechRequest?
        >
    with SpeechRequestManagerRef {
  _SpeechRequestManagerProviderElement(super.provider);

  @override
  String get requestId => (origin as SpeechRequestManagerProvider).requestId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
