// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$meetingListHash() => r'10d0ed1cd12d7102b3a5b7f982bb332a188111b8';

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
String _$meetingDetailHash() => r'fb1e1c50bbca60500357413be36c736a19cdf917';

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

String _$myMeetingsHash() => r'3e04900385d264907b3ea664daaf765a7c6e31f2';

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

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
