// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$meetingListHash() => r'81584d84abd8d47285042488f2d0e1236afe8283';

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
String _$meetingDetailHash() => r'fb712116557bf2a78cb087019b564d19d7618a88';

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

String _$myMeetingsHash() => r'6f9b1c79c2fbfc42be33be073138bdf90fd9da92';

/// 我的会议提供者 (我参与的会议)
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

String _$searchPrivateMeetingsHash() =>
    r'2fa604fb0c0b95a8089b1b565cbbc0560d169dbf';

/// 搜索私有会议提供者
///
/// Copied from [searchPrivateMeetings].
@ProviderFor(searchPrivateMeetings)
const searchPrivateMeetingsProvider = SearchPrivateMeetingsFamily();

/// 搜索私有会议提供者
///
/// Copied from [searchPrivateMeetings].
class SearchPrivateMeetingsFamily extends Family<AsyncValue<List<Meeting>>> {
  /// 搜索私有会议提供者
  ///
  /// Copied from [searchPrivateMeetings].
  const SearchPrivateMeetingsFamily();

  /// 搜索私有会议提供者
  ///
  /// Copied from [searchPrivateMeetings].
  SearchPrivateMeetingsProvider call(String query) {
    return SearchPrivateMeetingsProvider(query);
  }

  @override
  SearchPrivateMeetingsProvider getProviderOverride(
    covariant SearchPrivateMeetingsProvider provider,
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
  String? get name => r'searchPrivateMeetingsProvider';
}

/// 搜索私有会议提供者
///
/// Copied from [searchPrivateMeetings].
class SearchPrivateMeetingsProvider
    extends AutoDisposeFutureProvider<List<Meeting>> {
  /// 搜索私有会议提供者
  ///
  /// Copied from [searchPrivateMeetings].
  SearchPrivateMeetingsProvider(String query)
    : this._internal(
        (ref) => searchPrivateMeetings(ref as SearchPrivateMeetingsRef, query),
        from: searchPrivateMeetingsProvider,
        name: r'searchPrivateMeetingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$searchPrivateMeetingsHash,
        dependencies: SearchPrivateMeetingsFamily._dependencies,
        allTransitiveDependencies:
            SearchPrivateMeetingsFamily._allTransitiveDependencies,
        query: query,
      );

  SearchPrivateMeetingsProvider._internal(
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
    FutureOr<List<Meeting>> Function(SearchPrivateMeetingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchPrivateMeetingsProvider._internal(
        (ref) => create(ref as SearchPrivateMeetingsRef),
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
    return _SearchPrivateMeetingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchPrivateMeetingsProvider && other.query == query;
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
mixin SearchPrivateMeetingsRef on AutoDisposeFutureProviderRef<List<Meeting>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchPrivateMeetingsProviderElement
    extends AutoDisposeFutureProviderElement<List<Meeting>>
    with SearchPrivateMeetingsRef {
  _SearchPrivateMeetingsProviderElement(super.provider);

  @override
  String get query => (origin as SearchPrivateMeetingsProvider).query;
}

String _$searchPublicMeetingsHash() =>
    r'50f27070c922478821cd3b06de22bce3a4b4928a';

/// 搜索公有会议提供者
///
/// Copied from [searchPublicMeetings].
@ProviderFor(searchPublicMeetings)
const searchPublicMeetingsProvider = SearchPublicMeetingsFamily();

/// 搜索公有会议提供者
///
/// Copied from [searchPublicMeetings].
class SearchPublicMeetingsFamily extends Family<AsyncValue<List<Meeting>>> {
  /// 搜索公有会议提供者
  ///
  /// Copied from [searchPublicMeetings].
  const SearchPublicMeetingsFamily();

  /// 搜索公有会议提供者
  ///
  /// Copied from [searchPublicMeetings].
  SearchPublicMeetingsProvider call(String query) {
    return SearchPublicMeetingsProvider(query);
  }

  @override
  SearchPublicMeetingsProvider getProviderOverride(
    covariant SearchPublicMeetingsProvider provider,
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
  String? get name => r'searchPublicMeetingsProvider';
}

/// 搜索公有会议提供者
///
/// Copied from [searchPublicMeetings].
class SearchPublicMeetingsProvider
    extends AutoDisposeFutureProvider<List<Meeting>> {
  /// 搜索公有会议提供者
  ///
  /// Copied from [searchPublicMeetings].
  SearchPublicMeetingsProvider(String query)
    : this._internal(
        (ref) => searchPublicMeetings(ref as SearchPublicMeetingsRef, query),
        from: searchPublicMeetingsProvider,
        name: r'searchPublicMeetingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$searchPublicMeetingsHash,
        dependencies: SearchPublicMeetingsFamily._dependencies,
        allTransitiveDependencies:
            SearchPublicMeetingsFamily._allTransitiveDependencies,
        query: query,
      );

  SearchPublicMeetingsProvider._internal(
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
    FutureOr<List<Meeting>> Function(SearchPublicMeetingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchPublicMeetingsProvider._internal(
        (ref) => create(ref as SearchPublicMeetingsRef),
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
    return _SearchPublicMeetingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchPublicMeetingsProvider && other.query == query;
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
mixin SearchPublicMeetingsRef on AutoDisposeFutureProviderRef<List<Meeting>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _SearchPublicMeetingsProviderElement
    extends AutoDisposeFutureProviderElement<List<Meeting>>
    with SearchPublicMeetingsRef {
  _SearchPublicMeetingsProviderElement(super.provider);

  @override
  String get query => (origin as SearchPublicMeetingsProvider).query;
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

String _$meetingManagersHash() => r'd5da71dc8c435c6b738d01a8ba4c630d014a3042';

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
    r'807f4e2b4cb978eeb876014078fc04342dc3d335';

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
String _$myPrivateMeetingsHash() => r'114007a59931ac9fca9d4cd309f0aa426edccfb7';

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
String _$blacklistMembersHash() => r'b618d5f6789e96d9089601916fde9e36c8593545';

/// 获取会议黑名单列表
///
/// Copied from [blacklistMembers].
@ProviderFor(blacklistMembers)
const blacklistMembersProvider = BlacklistMembersFamily();

/// 获取会议黑名单列表
///
/// Copied from [blacklistMembers].
class BlacklistMembersFamily extends Family<AsyncValue<List<dynamic>>> {
  /// 获取会议黑名单列表
  ///
  /// Copied from [blacklistMembers].
  const BlacklistMembersFamily();

  /// 获取会议黑名单列表
  ///
  /// Copied from [blacklistMembers].
  BlacklistMembersProvider call(String meetingId) {
    return BlacklistMembersProvider(meetingId);
  }

  @override
  BlacklistMembersProvider getProviderOverride(
    covariant BlacklistMembersProvider provider,
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
  String? get name => r'blacklistMembersProvider';
}

/// 获取会议黑名单列表
///
/// Copied from [blacklistMembers].
class BlacklistMembersProvider
    extends AutoDisposeFutureProvider<List<dynamic>> {
  /// 获取会议黑名单列表
  ///
  /// Copied from [blacklistMembers].
  BlacklistMembersProvider(String meetingId)
    : this._internal(
        (ref) => blacklistMembers(ref as BlacklistMembersRef, meetingId),
        from: blacklistMembersProvider,
        name: r'blacklistMembersProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$blacklistMembersHash,
        dependencies: BlacklistMembersFamily._dependencies,
        allTransitiveDependencies:
            BlacklistMembersFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  BlacklistMembersProvider._internal(
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
    FutureOr<List<dynamic>> Function(BlacklistMembersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BlacklistMembersProvider._internal(
        (ref) => create(ref as BlacklistMembersRef),
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
  AutoDisposeFutureProviderElement<List<dynamic>> createElement() {
    return _BlacklistMembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BlacklistMembersProvider && other.meetingId == meetingId;
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
mixin BlacklistMembersRef on AutoDisposeFutureProviderRef<List<dynamic>> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _BlacklistMembersProviderElement
    extends AutoDisposeFutureProviderElement<List<dynamic>>
    with BlacklistMembersRef {
  _BlacklistMembersProviderElement(super.provider);

  @override
  String get meetingId => (origin as BlacklistMembersProvider).meetingId;
}

String _$isUserInBlacklistHash() => r'526293fedaa0df2bc55646068e2275a44092f3a0';

/// 检查用户是否在黑名单中 - 使用autoDispose完全禁用缓存
///
/// Copied from [isUserInBlacklist].
@ProviderFor(isUserInBlacklist)
const isUserInBlacklistProvider = IsUserInBlacklistFamily();

/// 检查用户是否在黑名单中 - 使用autoDispose完全禁用缓存
///
/// Copied from [isUserInBlacklist].
class IsUserInBlacklistFamily extends Family<AsyncValue<bool>> {
  /// 检查用户是否在黑名单中 - 使用autoDispose完全禁用缓存
  ///
  /// Copied from [isUserInBlacklist].
  const IsUserInBlacklistFamily();

  /// 检查用户是否在黑名单中 - 使用autoDispose完全禁用缓存
  ///
  /// Copied from [isUserInBlacklist].
  IsUserInBlacklistProvider call(String meetingId, String userId) {
    return IsUserInBlacklistProvider(meetingId, userId);
  }

  @override
  IsUserInBlacklistProvider getProviderOverride(
    covariant IsUserInBlacklistProvider provider,
  ) {
    return call(provider.meetingId, provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isUserInBlacklistProvider';
}

/// 检查用户是否在黑名单中 - 使用autoDispose完全禁用缓存
///
/// Copied from [isUserInBlacklist].
class IsUserInBlacklistProvider extends AutoDisposeFutureProvider<bool> {
  /// 检查用户是否在黑名单中 - 使用autoDispose完全禁用缓存
  ///
  /// Copied from [isUserInBlacklist].
  IsUserInBlacklistProvider(String meetingId, String userId)
    : this._internal(
        (ref) =>
            isUserInBlacklist(ref as IsUserInBlacklistRef, meetingId, userId),
        from: isUserInBlacklistProvider,
        name: r'isUserInBlacklistProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$isUserInBlacklistHash,
        dependencies: IsUserInBlacklistFamily._dependencies,
        allTransitiveDependencies:
            IsUserInBlacklistFamily._allTransitiveDependencies,
        meetingId: meetingId,
        userId: userId,
      );

  IsUserInBlacklistProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.meetingId,
    required this.userId,
  }) : super.internal();

  final String meetingId;
  final String userId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsUserInBlacklistRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsUserInBlacklistProvider._internal(
        (ref) => create(ref as IsUserInBlacklistRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        meetingId: meetingId,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsUserInBlacklistProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsUserInBlacklistProvider &&
        other.meetingId == meetingId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, meetingId.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsUserInBlacklistRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;

  /// The parameter `userId` of this provider.
  String get userId;
}

class _IsUserInBlacklistProviderElement
    extends AutoDisposeFutureProviderElement<bool>
    with IsUserInBlacklistRef {
  _IsUserInBlacklistProviderElement(super.provider);

  @override
  String get meetingId => (origin as IsUserInBlacklistProvider).meetingId;
  @override
  String get userId => (origin as IsUserInBlacklistProvider).userId;
}

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
    r'4bb7a08a53fc4fa5e9a9300367bb7079682e1d8f';

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

String _$meetingSignInHash() => r'607eda86dd5bdc1e63b6cd8029b972b1c088cfb7';

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
