// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$meetingListHash() => r'a56c0cca30b22641e44f845c386021191eb29515';

/// 会议列表提供者
///
/// Copied from [meetingList].
@ProviderFor(meetingList)
final meetingListProvider = AutoDisposeFutureProvider<List<Meeting>>.internal(
  meetingList,
  name: r'meetingListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$meetingListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MeetingListRef = AutoDisposeFutureProviderRef<List<Meeting>>;
String _$meetingDetailHash() => r'8c96711bb3f1555611b678c6f565c50295d02b37';

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

/// 会议详情提供者
///
/// Copied from [meetingDetail].
@ProviderFor(meetingDetail)
const meetingDetailProvider = MeetingDetailFamily();

/// 会议详情提供者
///
/// Copied from [meetingDetail].
class MeetingDetailFamily extends Family<AsyncValue<Meeting>> {
  /// 会议详情提供者
  ///
  /// Copied from [meetingDetail].
  const MeetingDetailFamily();

  /// 会议详情提供者
  ///
  /// Copied from [meetingDetail].
  MeetingDetailProvider call(String meetingId) {
    return MeetingDetailProvider(meetingId);
  }

  @override
  MeetingDetailProvider getProviderOverride(
    covariant MeetingDetailProvider provider,
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
  String? get name => r'meetingDetailProvider';
}

/// 会议详情提供者
///
/// Copied from [meetingDetail].
class MeetingDetailProvider extends AutoDisposeFutureProvider<Meeting> {
  /// 会议详情提供者
  ///
  /// Copied from [meetingDetail].
  MeetingDetailProvider(String meetingId)
    : this._internal(
        (ref) => meetingDetail(ref as MeetingDetailRef, meetingId),
        from: meetingDetailProvider,
        name: r'meetingDetailProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingDetailHash,
        dependencies: MeetingDetailFamily._dependencies,
        allTransitiveDependencies:
            MeetingDetailFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingDetailProvider._internal(
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
    FutureOr<Meeting> Function(MeetingDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeetingDetailProvider._internal(
        (ref) => create(ref as MeetingDetailRef),
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
  AutoDisposeFutureProviderElement<Meeting> createElement() {
    return _MeetingDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingDetailProvider && other.meetingId == meetingId;
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
mixin MeetingDetailRef on AutoDisposeFutureProviderRef<Meeting> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingDetailProviderElement
    extends AutoDisposeFutureProviderElement<Meeting>
    with MeetingDetailRef {
  _MeetingDetailProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingDetailProvider).meetingId;
}

String _$myMeetingsHash() => r'344978d82f356fa00bbc9a0c293cf79071b4e2c1';

/// 我的会议提供者 (已签到)
///
/// Copied from [myMeetings].
@ProviderFor(myMeetings)
final myMeetingsProvider = AutoDisposeFutureProvider<List<Meeting>>.internal(
  myMeetings,
  name: r'myMeetingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myMeetingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyMeetingsRef = AutoDisposeFutureProviderRef<List<Meeting>>;
String _$searchMeetingsHash() => r'dc08945e2516c23d877aa212f7027e1b4d86e95b';

/// 搜索会议提供者
///
/// Copied from [searchMeetings].
@ProviderFor(searchMeetings)
const searchMeetingsProvider = SearchMeetingsFamily();

/// 搜索会议提供者
///
/// Copied from [searchMeetings].
class SearchMeetingsFamily extends Family<AsyncValue<List<Meeting>>> {
  /// 搜索会议提供者
  ///
  /// Copied from [searchMeetings].
  const SearchMeetingsFamily();

  /// 搜索会议提供者
  ///
  /// Copied from [searchMeetings].
  SearchMeetingsProvider call(String query) {
    return SearchMeetingsProvider(query);
  }

  @override
  SearchMeetingsProvider getProviderOverride(
    covariant SearchMeetingsProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchMeetingsProvider';
}

/// 搜索会议提供者
///
/// Copied from [searchMeetings].
class SearchMeetingsProvider extends AutoDisposeFutureProvider<List<Meeting>> {
  /// 搜索会议提供者
  ///
  /// Copied from [searchMeetings].
  SearchMeetingsProvider(String query)
    : this._internal(
        (ref) => searchMeetings(ref as SearchMeetingsRef, query),
        from: searchMeetingsProvider,
        name: r'searchMeetingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$searchMeetingsHash,
        dependencies: SearchMeetingsFamily._dependencies,
        allTransitiveDependencies:
            SearchMeetingsFamily._allTransitiveDependencies,
        query: query,
      );

  SearchMeetingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<Meeting>> Function(SearchMeetingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchMeetingsProvider._internal(
        (ref) => create(ref as SearchMeetingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Meeting>> createElement() {
    return _SearchMeetingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchMeetingsProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchMeetingsRef on AutoDisposeFutureProviderRef<List<Meeting>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchMeetingsProviderElement
    extends AutoDisposeFutureProviderElement<List<Meeting>>
    with SearchMeetingsRef {
  _SearchMeetingsProviderElement(super.provider);

  @override
  String get query => (origin as SearchMeetingsProvider).query;
}

String _$meetingParticipantsHash() =>
    r'951d4223e12e079926290963ff637f77ae60da01';

/// 会议参与者提供者
///
/// Copied from [meetingParticipants].
@ProviderFor(meetingParticipants)
const meetingParticipantsProvider = MeetingParticipantsFamily();

/// 会议参与者提供者
///
/// Copied from [meetingParticipants].
class MeetingParticipantsFamily extends Family<AsyncValue<List<User>>> {
  /// 会议参与者提供者
  ///
  /// Copied from [meetingParticipants].
  const MeetingParticipantsFamily();

  /// 会议参与者提供者
  ///
  /// Copied from [meetingParticipants].
  MeetingParticipantsProvider call(String meetingId) {
    return MeetingParticipantsProvider(meetingId);
  }

  @override
  MeetingParticipantsProvider getProviderOverride(
    covariant MeetingParticipantsProvider provider,
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
  String? get name => r'meetingParticipantsProvider';
}

/// 会议参与者提供者
///
/// Copied from [meetingParticipants].
class MeetingParticipantsProvider
    extends AutoDisposeFutureProvider<List<User>> {
  /// 会议参与者提供者
  ///
  /// Copied from [meetingParticipants].
  MeetingParticipantsProvider(String meetingId)
    : this._internal(
        (ref) => meetingParticipants(ref as MeetingParticipantsRef, meetingId),
        from: meetingParticipantsProvider,
        name: r'meetingParticipantsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingParticipantsHash,
        dependencies: MeetingParticipantsFamily._dependencies,
        allTransitiveDependencies:
            MeetingParticipantsFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingParticipantsProvider._internal(
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
    FutureOr<List<User>> Function(MeetingParticipantsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeetingParticipantsProvider._internal(
        (ref) => create(ref as MeetingParticipantsRef),
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
  AutoDisposeFutureProviderElement<List<User>> createElement() {
    return _MeetingParticipantsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingParticipantsProvider && other.meetingId == meetingId;
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
mixin MeetingParticipantsRef on AutoDisposeFutureProviderRef<List<User>> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingParticipantsProviderElement
    extends AutoDisposeFutureProviderElement<List<User>>
    with MeetingParticipantsRef {
  _MeetingParticipantsProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingParticipantsProvider).meetingId;
}

String _$meetingManagersHash() => r'5b41ef77a7d7ebe6f6d6e3bc4aa02e4639d42032';

/// 会议管理员列表提供者
///
/// Copied from [meetingManagers].
@ProviderFor(meetingManagers)
const meetingManagersProvider = MeetingManagersFamily();

/// 会议管理员列表提供者
///
/// Copied from [meetingManagers].
class MeetingManagersFamily extends Family<AsyncValue<List<User>>> {
  /// 会议管理员列表提供者
  ///
  /// Copied from [meetingManagers].
  const MeetingManagersFamily();

  /// 会议管理员列表提供者
  ///
  /// Copied from [meetingManagers].
  MeetingManagersProvider call(String meetingId) {
    return MeetingManagersProvider(meetingId);
  }

  @override
  MeetingManagersProvider getProviderOverride(
    covariant MeetingManagersProvider provider,
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
  String? get name => r'meetingManagersProvider';
}

/// 会议管理员列表提供者
///
/// Copied from [meetingManagers].
class MeetingManagersProvider extends AutoDisposeFutureProvider<List<User>> {
  /// 会议管理员列表提供者
  ///
  /// Copied from [meetingManagers].
  MeetingManagersProvider(String meetingId)
    : this._internal(
        (ref) => meetingManagers(ref as MeetingManagersRef, meetingId),
        from: meetingManagersProvider,
        name: r'meetingManagersProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingManagersHash,
        dependencies: MeetingManagersFamily._dependencies,
        allTransitiveDependencies:
            MeetingManagersFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingManagersProvider._internal(
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
    FutureOr<List<User>> Function(MeetingManagersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeetingManagersProvider._internal(
        (ref) => create(ref as MeetingManagersRef),
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
  AutoDisposeFutureProviderElement<List<User>> createElement() {
    return _MeetingManagersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingManagersProvider && other.meetingId == meetingId;
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
mixin MeetingManagersRef on AutoDisposeFutureProviderRef<List<User>> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingManagersProviderElement
    extends AutoDisposeFutureProviderElement<List<User>>
    with MeetingManagersRef {
  _MeetingManagersProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingManagersProvider).meetingId;
}

String _$recommendedMeetingsHash() =>
    r'c0ca0f0c7e2b77c49905be59e5e8c9478ad7e1fa';

/// 推荐会议列表提供者
///
/// Copied from [recommendedMeetings].
@ProviderFor(recommendedMeetings)
final recommendedMeetingsProvider =
    AutoDisposeFutureProvider<List<MeetingRecommendation>>.internal(
      recommendedMeetings,
      name: r'recommendedMeetingsProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$recommendedMeetingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecommendedMeetingsRef =
    AutoDisposeFutureProviderRef<List<MeetingRecommendation>>;
String _$myPrivateMeetingsHash() => r'dad7ff8d7ee2d5d7d5a8f1ec5debf8242addc9c8';

/// 我的私密会议列表提供者
///
/// Copied from [myPrivateMeetings].
@ProviderFor(myPrivateMeetings)
final myPrivateMeetingsProvider =
    AutoDisposeFutureProvider<List<Meeting>>.internal(
      myPrivateMeetings,
      name: r'myPrivateMeetingsProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$myPrivateMeetingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyPrivateMeetingsRef = AutoDisposeFutureProviderRef<List<Meeting>>;
String _$createMeetingHash() => r'ad7ce223cd00374078eca4dbfa608e7cf52b7c69';

/// 创建会议提供者
///
/// Copied from [CreateMeeting].
@ProviderFor(CreateMeeting)
final createMeetingProvider =
    AutoDisposeAsyncNotifierProvider<CreateMeeting, Meeting?>.internal(
      CreateMeeting.new,
      name: r'createMeetingProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$createMeetingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CreateMeeting = AutoDisposeAsyncNotifier<Meeting?>;
String _$validateMeetingPasswordHash() =>
    r'2a007aa4a6e5475f5630a0ba82fff5a920686d1c';

abstract class _$ValidateMeetingPassword
    extends BuildlessAutoDisposeAsyncNotifier<bool?> {
  late final String meetingId;

  FutureOr<bool?> build(String meetingId);
}

/// 验证会议密码提供者
///
/// Copied from [ValidateMeetingPassword].
@ProviderFor(ValidateMeetingPassword)
const validateMeetingPasswordProvider = ValidateMeetingPasswordFamily();

/// 验证会议密码提供者
///
/// Copied from [ValidateMeetingPassword].
class ValidateMeetingPasswordFamily extends Family<AsyncValue<bool?>> {
  /// 验证会议密码提供者
  ///
  /// Copied from [ValidateMeetingPassword].
  const ValidateMeetingPasswordFamily();

  /// 验证会议密码提供者
  ///
  /// Copied from [ValidateMeetingPassword].
  ValidateMeetingPasswordProvider call(String meetingId) {
    return ValidateMeetingPasswordProvider(meetingId);
  }

  @override
  ValidateMeetingPasswordProvider getProviderOverride(
    covariant ValidateMeetingPasswordProvider provider,
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
  String? get name => r'validateMeetingPasswordProvider';
}

/// 验证会议密码提供者
///
/// Copied from [ValidateMeetingPassword].
class ValidateMeetingPasswordProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<ValidateMeetingPassword, bool?> {
  /// 验证会议密码提供者
  ///
  /// Copied from [ValidateMeetingPassword].
  ValidateMeetingPasswordProvider(String meetingId)
    : this._internal(
        () => ValidateMeetingPassword()..meetingId = meetingId,
        from: validateMeetingPasswordProvider,
        name: r'validateMeetingPasswordProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$validateMeetingPasswordHash,
        dependencies: ValidateMeetingPasswordFamily._dependencies,
        allTransitiveDependencies:
            ValidateMeetingPasswordFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  ValidateMeetingPasswordProvider._internal(
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
  FutureOr<bool?> runNotifierBuild(covariant ValidateMeetingPassword notifier) {
    return notifier.build(meetingId);
  }

  @override
  Override overrideWith(ValidateMeetingPassword Function() create) {
    return ProviderOverride(
      origin: this,
      override: ValidateMeetingPasswordProvider._internal(
        () => create()..meetingId = meetingId,
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
  AutoDisposeAsyncNotifierProviderElement<ValidateMeetingPassword, bool?>
  createElement() {
    return _ValidateMeetingPasswordProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ValidateMeetingPasswordProvider &&
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
mixin ValidateMeetingPasswordRef on AutoDisposeAsyncNotifierProviderRef<bool?> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _ValidateMeetingPasswordProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<ValidateMeetingPassword, bool?>
    with ValidateMeetingPasswordRef {
  _ValidateMeetingPasswordProviderElement(super.provider);

  @override
  String get meetingId => (origin as ValidateMeetingPasswordProvider).meetingId;
}

String _$meetingSignInHash() => r'13a9e8bdd98df69399b56808d66a5a2a5f107e03';

abstract class _$MeetingSignIn extends BuildlessAutoDisposeAsyncNotifier<bool> {
  late final String meetingId;

  FutureOr<bool> build(String meetingId);
}

/// 会议签到提供者
///
/// Copied from [MeetingSignIn].
@ProviderFor(MeetingSignIn)
const meetingSignInProvider = MeetingSignInFamily();

/// 会议签到提供者
///
/// Copied from [MeetingSignIn].
class MeetingSignInFamily extends Family<AsyncValue<bool>> {
  /// 会议签到提供者
  ///
  /// Copied from [MeetingSignIn].
  const MeetingSignInFamily();

  /// 会议签到提供者
  ///
  /// Copied from [MeetingSignIn].
  MeetingSignInProvider call(String meetingId) {
    return MeetingSignInProvider(meetingId);
  }

  @override
  MeetingSignInProvider getProviderOverride(
    covariant MeetingSignInProvider provider,
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
  String? get name => r'meetingSignInProvider';
}

/// 会议签到提供者
///
/// Copied from [MeetingSignIn].
class MeetingSignInProvider
    extends AutoDisposeAsyncNotifierProviderImpl<MeetingSignIn, bool> {
  /// 会议签到提供者
  ///
  /// Copied from [MeetingSignIn].
  MeetingSignInProvider(String meetingId)
    : this._internal(
        () => MeetingSignIn()..meetingId = meetingId,
        from: meetingSignInProvider,
        name: r'meetingSignInProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingSignInHash,
        dependencies: MeetingSignInFamily._dependencies,
        allTransitiveDependencies:
            MeetingSignInFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingSignInProvider._internal(
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
  FutureOr<bool> runNotifierBuild(covariant MeetingSignIn notifier) {
    return notifier.build(meetingId);
  }

  @override
  Override overrideWith(MeetingSignIn Function() create) {
    return ProviderOverride(
      origin: this,
      override: MeetingSignInProvider._internal(
        () => create()..meetingId = meetingId,
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
  AutoDisposeAsyncNotifierProviderElement<MeetingSignIn, bool> createElement() {
    return _MeetingSignInProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingSignInProvider && other.meetingId == meetingId;
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
mixin MeetingSignInRef on AutoDisposeAsyncNotifierProviderRef<bool> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingSignInProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<MeetingSignIn, bool>
    with MeetingSignInRef {
  _MeetingSignInProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingSignInProvider).meetingId;
}

String _$meetingOperationsHash() => r'6176faab397217e0d51836837238fe3c064afc9d';

/// 会议管理操作提供者
///
/// Copied from [MeetingOperations].
@ProviderFor(MeetingOperations)
final meetingOperationsProvider = AutoDisposeNotifierProvider<
  MeetingOperations,
  AsyncValue<Meeting?>
>.internal(
  MeetingOperations.new,
  name: r'meetingOperationsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$meetingOperationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MeetingOperations = AutoDisposeNotifier<AsyncValue<Meeting?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
