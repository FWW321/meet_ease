// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_process_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$meetingAgendaHash() => r'd3b519ceaecb55eb4ebbe157ed0ebd8f1c7d104a';

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

///--------------------- 会议议程相关 ---------------------///
/// 会议议程提供者
///
/// Copied from [meetingAgenda].
@ProviderFor(meetingAgenda)
const meetingAgendaProvider = MeetingAgendaFamily();

///--------------------- 会议议程相关 ---------------------///
/// 会议议程提供者
///
/// Copied from [meetingAgenda].
class MeetingAgendaFamily extends Family<AsyncValue<MeetingAgenda>> {
  ///--------------------- 会议议程相关 ---------------------///
  /// 会议议程提供者
  ///
  /// Copied from [meetingAgenda].
  const MeetingAgendaFamily();

  ///--------------------- 会议议程相关 ---------------------///
  /// 会议议程提供者
  ///
  /// Copied from [meetingAgenda].
  MeetingAgendaProvider call(String meetingId) {
    return MeetingAgendaProvider(meetingId);
  }

  @override
  MeetingAgendaProvider getProviderOverride(
    covariant MeetingAgendaProvider provider,
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
  String? get name => r'meetingAgendaProvider';
}

///--------------------- 会议议程相关 ---------------------///
/// 会议议程提供者
///
/// Copied from [meetingAgenda].
class MeetingAgendaProvider extends AutoDisposeFutureProvider<MeetingAgenda> {
  ///--------------------- 会议议程相关 ---------------------///
  /// 会议议程提供者
  ///
  /// Copied from [meetingAgenda].
  MeetingAgendaProvider(String meetingId)
    : this._internal(
        (ref) => meetingAgenda(ref as MeetingAgendaRef, meetingId),
        from: meetingAgendaProvider,
        name: r'meetingAgendaProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingAgendaHash,
        dependencies: MeetingAgendaFamily._dependencies,
        allTransitiveDependencies:
            MeetingAgendaFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingAgendaProvider._internal(
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
    FutureOr<MeetingAgenda> Function(MeetingAgendaRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeetingAgendaProvider._internal(
        (ref) => create(ref as MeetingAgendaRef),
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
  AutoDisposeFutureProviderElement<MeetingAgenda> createElement() {
    return _MeetingAgendaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingAgendaProvider && other.meetingId == meetingId;
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
mixin MeetingAgendaRef on AutoDisposeFutureProviderRef<MeetingAgenda> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingAgendaProviderElement
    extends AutoDisposeFutureProviderElement<MeetingAgenda>
    with MeetingAgendaRef {
  _MeetingAgendaProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingAgendaProvider).meetingId;
}

String _$meetingMaterialsHash() => r'49fcef15779cd1555e9ee7eb2bde282754c58a44';

///--------------------- 会议资料相关 ---------------------///
/// 会议资料提供者
///
/// Copied from [meetingMaterials].
@ProviderFor(meetingMaterials)
const meetingMaterialsProvider = MeetingMaterialsFamily();

///--------------------- 会议资料相关 ---------------------///
/// 会议资料提供者
///
/// Copied from [meetingMaterials].
class MeetingMaterialsFamily extends Family<AsyncValue<MeetingMaterials>> {
  ///--------------------- 会议资料相关 ---------------------///
  /// 会议资料提供者
  ///
  /// Copied from [meetingMaterials].
  const MeetingMaterialsFamily();

  ///--------------------- 会议资料相关 ---------------------///
  /// 会议资料提供者
  ///
  /// Copied from [meetingMaterials].
  MeetingMaterialsProvider call(String meetingId) {
    return MeetingMaterialsProvider(meetingId);
  }

  @override
  MeetingMaterialsProvider getProviderOverride(
    covariant MeetingMaterialsProvider provider,
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
  String? get name => r'meetingMaterialsProvider';
}

///--------------------- 会议资料相关 ---------------------///
/// 会议资料提供者
///
/// Copied from [meetingMaterials].
class MeetingMaterialsProvider
    extends AutoDisposeFutureProvider<MeetingMaterials> {
  ///--------------------- 会议资料相关 ---------------------///
  /// 会议资料提供者
  ///
  /// Copied from [meetingMaterials].
  MeetingMaterialsProvider(String meetingId)
    : this._internal(
        (ref) => meetingMaterials(ref as MeetingMaterialsRef, meetingId),
        from: meetingMaterialsProvider,
        name: r'meetingMaterialsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingMaterialsHash,
        dependencies: MeetingMaterialsFamily._dependencies,
        allTransitiveDependencies:
            MeetingMaterialsFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingMaterialsProvider._internal(
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
    FutureOr<MeetingMaterials> Function(MeetingMaterialsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeetingMaterialsProvider._internal(
        (ref) => create(ref as MeetingMaterialsRef),
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
  AutoDisposeFutureProviderElement<MeetingMaterials> createElement() {
    return _MeetingMaterialsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingMaterialsProvider && other.meetingId == meetingId;
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
mixin MeetingMaterialsRef on AutoDisposeFutureProviderRef<MeetingMaterials> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingMaterialsProviderElement
    extends AutoDisposeFutureProviderElement<MeetingMaterials>
    with MeetingMaterialsRef {
  _MeetingMaterialsProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingMaterialsProvider).meetingId;
}

String _$meetingNotesHash() => r'68d04f08e20596a69590c842ea05755b59b6b283';

///--------------------- 会议笔记相关 ---------------------///
/// 会议笔记提供者
///
/// Copied from [meetingNotes].
@ProviderFor(meetingNotes)
const meetingNotesProvider = MeetingNotesFamily();

///--------------------- 会议笔记相关 ---------------------///
/// 会议笔记提供者
///
/// Copied from [meetingNotes].
class MeetingNotesFamily extends Family<AsyncValue<List<MeetingNote>>> {
  ///--------------------- 会议笔记相关 ---------------------///
  /// 会议笔记提供者
  ///
  /// Copied from [meetingNotes].
  const MeetingNotesFamily();

  ///--------------------- 会议笔记相关 ---------------------///
  /// 会议笔记提供者
  ///
  /// Copied from [meetingNotes].
  MeetingNotesProvider call(String meetingId) {
    return MeetingNotesProvider(meetingId);
  }

  @override
  MeetingNotesProvider getProviderOverride(
    covariant MeetingNotesProvider provider,
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
  String? get name => r'meetingNotesProvider';
}

///--------------------- 会议笔记相关 ---------------------///
/// 会议笔记提供者
///
/// Copied from [meetingNotes].
class MeetingNotesProvider
    extends AutoDisposeFutureProvider<List<MeetingNote>> {
  ///--------------------- 会议笔记相关 ---------------------///
  /// 会议笔记提供者
  ///
  /// Copied from [meetingNotes].
  MeetingNotesProvider(String meetingId)
    : this._internal(
        (ref) => meetingNotes(ref as MeetingNotesRef, meetingId),
        from: meetingNotesProvider,
        name: r'meetingNotesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingNotesHash,
        dependencies: MeetingNotesFamily._dependencies,
        allTransitiveDependencies:
            MeetingNotesFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingNotesProvider._internal(
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
    FutureOr<List<MeetingNote>> Function(MeetingNotesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeetingNotesProvider._internal(
        (ref) => create(ref as MeetingNotesRef),
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
  AutoDisposeFutureProviderElement<List<MeetingNote>> createElement() {
    return _MeetingNotesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingNotesProvider && other.meetingId == meetingId;
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
mixin MeetingNotesRef on AutoDisposeFutureProviderRef<List<MeetingNote>> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingNotesProviderElement
    extends AutoDisposeFutureProviderElement<List<MeetingNote>>
    with MeetingNotesRef {
  _MeetingNotesProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingNotesProvider).meetingId;
}

String _$meetingVotesHash() => r'91805351b5ec2190e6ca48b1c3696b295968862c';

///--------------------- 会议投票相关 ---------------------///
/// 会议投票列表提供者
///
/// Copied from [meetingVotes].
@ProviderFor(meetingVotes)
const meetingVotesProvider = MeetingVotesFamily();

///--------------------- 会议投票相关 ---------------------///
/// 会议投票列表提供者
///
/// Copied from [meetingVotes].
class MeetingVotesFamily extends Family<AsyncValue<List<MeetingVote>>> {
  ///--------------------- 会议投票相关 ---------------------///
  /// 会议投票列表提供者
  ///
  /// Copied from [meetingVotes].
  const MeetingVotesFamily();

  ///--------------------- 会议投票相关 ---------------------///
  /// 会议投票列表提供者
  ///
  /// Copied from [meetingVotes].
  MeetingVotesProvider call(String meetingId) {
    return MeetingVotesProvider(meetingId);
  }

  @override
  MeetingVotesProvider getProviderOverride(
    covariant MeetingVotesProvider provider,
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
  String? get name => r'meetingVotesProvider';
}

///--------------------- 会议投票相关 ---------------------///
/// 会议投票列表提供者
///
/// Copied from [meetingVotes].
class MeetingVotesProvider
    extends AutoDisposeFutureProvider<List<MeetingVote>> {
  ///--------------------- 会议投票相关 ---------------------///
  /// 会议投票列表提供者
  ///
  /// Copied from [meetingVotes].
  MeetingVotesProvider(String meetingId)
    : this._internal(
        (ref) => meetingVotes(ref as MeetingVotesRef, meetingId),
        from: meetingVotesProvider,
        name: r'meetingVotesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingVotesHash,
        dependencies: MeetingVotesFamily._dependencies,
        allTransitiveDependencies:
            MeetingVotesFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingVotesProvider._internal(
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
    FutureOr<List<MeetingVote>> Function(MeetingVotesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeetingVotesProvider._internal(
        (ref) => create(ref as MeetingVotesRef),
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
  AutoDisposeFutureProviderElement<List<MeetingVote>> createElement() {
    return _MeetingVotesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingVotesProvider && other.meetingId == meetingId;
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
mixin MeetingVotesRef on AutoDisposeFutureProviderRef<List<MeetingVote>> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingVotesProviderElement
    extends AutoDisposeFutureProviderElement<List<MeetingVote>>
    with MeetingVotesRef {
  _MeetingVotesProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingVotesProvider).meetingId;
}

String _$voteDetailHash() => r'0b90adcc70364db2f5573bedf8101e3e087762d0';

/// 单个投票详情提供者
///
/// Copied from [voteDetail].
@ProviderFor(voteDetail)
const voteDetailProvider = VoteDetailFamily();

/// 单个投票详情提供者
///
/// Copied from [voteDetail].
class VoteDetailFamily extends Family<AsyncValue<MeetingVote>> {
  /// 单个投票详情提供者
  ///
  /// Copied from [voteDetail].
  const VoteDetailFamily();

  /// 单个投票详情提供者
  ///
  /// Copied from [voteDetail].
  VoteDetailProvider call(String voteId) {
    return VoteDetailProvider(voteId);
  }

  @override
  VoteDetailProvider getProviderOverride(
    covariant VoteDetailProvider provider,
  ) {
    return call(provider.voteId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'voteDetailProvider';
}

/// 单个投票详情提供者
///
/// Copied from [voteDetail].
class VoteDetailProvider extends AutoDisposeFutureProvider<MeetingVote> {
  /// 单个投票详情提供者
  ///
  /// Copied from [voteDetail].
  VoteDetailProvider(String voteId)
    : this._internal(
        (ref) => voteDetail(ref as VoteDetailRef, voteId),
        from: voteDetailProvider,
        name: r'voteDetailProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$voteDetailHash,
        dependencies: VoteDetailFamily._dependencies,
        allTransitiveDependencies: VoteDetailFamily._allTransitiveDependencies,
        voteId: voteId,
      );

  VoteDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.voteId,
  }) : super.internal();

  final String voteId;

  @override
  Override overrideWith(
    FutureOr<MeetingVote> Function(VoteDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VoteDetailProvider._internal(
        (ref) => create(ref as VoteDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        voteId: voteId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<MeetingVote> createElement() {
    return _VoteDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VoteDetailProvider && other.voteId == voteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, voteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VoteDetailRef on AutoDisposeFutureProviderRef<MeetingVote> {
  /// The parameter `voteId` of this provider.
  String get voteId;
}

class _VoteDetailProviderElement
    extends AutoDisposeFutureProviderElement<MeetingVote>
    with VoteDetailRef {
  _VoteDetailProviderElement(super.provider);

  @override
  String get voteId => (origin as VoteDetailProvider).voteId;
}

String _$voteResultsHash() => r'8d7cd5e5c4b5a271a0820f2ed82edd7a2a47e8c0';

/// 投票结果提供者
///
/// Copied from [voteResults].
@ProviderFor(voteResults)
const voteResultsProvider = VoteResultsFamily();

/// 投票结果提供者
///
/// Copied from [voteResults].
class VoteResultsFamily extends Family<AsyncValue<List<VoteOption>>> {
  /// 投票结果提供者
  ///
  /// Copied from [voteResults].
  const VoteResultsFamily();

  /// 投票结果提供者
  ///
  /// Copied from [voteResults].
  VoteResultsProvider call(String voteId) {
    return VoteResultsProvider(voteId);
  }

  @override
  VoteResultsProvider getProviderOverride(
    covariant VoteResultsProvider provider,
  ) {
    return call(provider.voteId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'voteResultsProvider';
}

/// 投票结果提供者
///
/// Copied from [voteResults].
class VoteResultsProvider extends AutoDisposeFutureProvider<List<VoteOption>> {
  /// 投票结果提供者
  ///
  /// Copied from [voteResults].
  VoteResultsProvider(String voteId)
    : this._internal(
        (ref) => voteResults(ref as VoteResultsRef, voteId),
        from: voteResultsProvider,
        name: r'voteResultsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$voteResultsHash,
        dependencies: VoteResultsFamily._dependencies,
        allTransitiveDependencies: VoteResultsFamily._allTransitiveDependencies,
        voteId: voteId,
      );

  VoteResultsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.voteId,
  }) : super.internal();

  final String voteId;

  @override
  Override overrideWith(
    FutureOr<List<VoteOption>> Function(VoteResultsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VoteResultsProvider._internal(
        (ref) => create(ref as VoteResultsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        voteId: voteId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<VoteOption>> createElement() {
    return _VoteResultsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VoteResultsProvider && other.voteId == voteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, voteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VoteResultsRef on AutoDisposeFutureProviderRef<List<VoteOption>> {
  /// The parameter `voteId` of this provider.
  String get voteId;
}

class _VoteResultsProviderElement
    extends AutoDisposeFutureProviderElement<List<VoteOption>>
    with VoteResultsRef {
  _VoteResultsProviderElement(super.provider);

  @override
  String get voteId => (origin as VoteResultsProvider).voteId;
}

String _$agendaItemStatusNotifierHash() =>
    r'7de6309c47571508dbd22a40b5f77bba017bbe3e';

abstract class _$AgendaItemStatusNotifier
    extends BuildlessAutoDisposeAsyncNotifier<AgendaItem?> {
  late final String agendaItemId;
  late final String meetingId;

  FutureOr<AgendaItem?> build(String agendaItemId, String meetingId);
}

/// 议程项状态更新提供者
///
/// Copied from [AgendaItemStatusNotifier].
@ProviderFor(AgendaItemStatusNotifier)
const agendaItemStatusNotifierProvider = AgendaItemStatusNotifierFamily();

/// 议程项状态更新提供者
///
/// Copied from [AgendaItemStatusNotifier].
class AgendaItemStatusNotifierFamily extends Family<AsyncValue<AgendaItem?>> {
  /// 议程项状态更新提供者
  ///
  /// Copied from [AgendaItemStatusNotifier].
  const AgendaItemStatusNotifierFamily();

  /// 议程项状态更新提供者
  ///
  /// Copied from [AgendaItemStatusNotifier].
  AgendaItemStatusNotifierProvider call(String agendaItemId, String meetingId) {
    return AgendaItemStatusNotifierProvider(agendaItemId, meetingId);
  }

  @override
  AgendaItemStatusNotifierProvider getProviderOverride(
    covariant AgendaItemStatusNotifierProvider provider,
  ) {
    return call(provider.agendaItemId, provider.meetingId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'agendaItemStatusNotifierProvider';
}

/// 议程项状态更新提供者
///
/// Copied from [AgendaItemStatusNotifier].
class AgendaItemStatusNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          AgendaItemStatusNotifier,
          AgendaItem?
        > {
  /// 议程项状态更新提供者
  ///
  /// Copied from [AgendaItemStatusNotifier].
  AgendaItemStatusNotifierProvider(String agendaItemId, String meetingId)
    : this._internal(
        () =>
            AgendaItemStatusNotifier()
              ..agendaItemId = agendaItemId
              ..meetingId = meetingId,
        from: agendaItemStatusNotifierProvider,
        name: r'agendaItemStatusNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$agendaItemStatusNotifierHash,
        dependencies: AgendaItemStatusNotifierFamily._dependencies,
        allTransitiveDependencies:
            AgendaItemStatusNotifierFamily._allTransitiveDependencies,
        agendaItemId: agendaItemId,
        meetingId: meetingId,
      );

  AgendaItemStatusNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.agendaItemId,
    required this.meetingId,
  }) : super.internal();

  final String agendaItemId;
  final String meetingId;

  @override
  FutureOr<AgendaItem?> runNotifierBuild(
    covariant AgendaItemStatusNotifier notifier,
  ) {
    return notifier.build(agendaItemId, meetingId);
  }

  @override
  Override overrideWith(AgendaItemStatusNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AgendaItemStatusNotifierProvider._internal(
        () =>
            create()
              ..agendaItemId = agendaItemId
              ..meetingId = meetingId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        agendaItemId: agendaItemId,
        meetingId: meetingId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AgendaItemStatusNotifier, AgendaItem?>
  createElement() {
    return _AgendaItemStatusNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AgendaItemStatusNotifierProvider &&
        other.agendaItemId == agendaItemId &&
        other.meetingId == meetingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, agendaItemId.hashCode);
    hash = _SystemHash.combine(hash, meetingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AgendaItemStatusNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<AgendaItem?> {
  /// The parameter `agendaItemId` of this provider.
  String get agendaItemId;

  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _AgendaItemStatusNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          AgendaItemStatusNotifier,
          AgendaItem?
        >
    with AgendaItemStatusNotifierRef {
  _AgendaItemStatusNotifierProviderElement(super.provider);

  @override
  String get agendaItemId =>
      (origin as AgendaItemStatusNotifierProvider).agendaItemId;
  @override
  String get meetingId =>
      (origin as AgendaItemStatusNotifierProvider).meetingId;
}

String _$meetingMaterialsNotifierHash() =>
    r'db713c49d011264da37b8b847d8c74ce9a2c0213';

abstract class _$MeetingMaterialsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<MeetingMaterials> {
  late final String meetingId;

  FutureOr<MeetingMaterials> build(String meetingId);
}

/// 会议资料管理提供者
///
/// Copied from [MeetingMaterialsNotifier].
@ProviderFor(MeetingMaterialsNotifier)
const meetingMaterialsNotifierProvider = MeetingMaterialsNotifierFamily();

/// 会议资料管理提供者
///
/// Copied from [MeetingMaterialsNotifier].
class MeetingMaterialsNotifierFamily
    extends Family<AsyncValue<MeetingMaterials>> {
  /// 会议资料管理提供者
  ///
  /// Copied from [MeetingMaterialsNotifier].
  const MeetingMaterialsNotifierFamily();

  /// 会议资料管理提供者
  ///
  /// Copied from [MeetingMaterialsNotifier].
  MeetingMaterialsNotifierProvider call(String meetingId) {
    return MeetingMaterialsNotifierProvider(meetingId);
  }

  @override
  MeetingMaterialsNotifierProvider getProviderOverride(
    covariant MeetingMaterialsNotifierProvider provider,
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
  String? get name => r'meetingMaterialsNotifierProvider';
}

/// 会议资料管理提供者
///
/// Copied from [MeetingMaterialsNotifier].
class MeetingMaterialsNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          MeetingMaterialsNotifier,
          MeetingMaterials
        > {
  /// 会议资料管理提供者
  ///
  /// Copied from [MeetingMaterialsNotifier].
  MeetingMaterialsNotifierProvider(String meetingId)
    : this._internal(
        () => MeetingMaterialsNotifier()..meetingId = meetingId,
        from: meetingMaterialsNotifierProvider,
        name: r'meetingMaterialsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingMaterialsNotifierHash,
        dependencies: MeetingMaterialsNotifierFamily._dependencies,
        allTransitiveDependencies:
            MeetingMaterialsNotifierFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingMaterialsNotifierProvider._internal(
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
  FutureOr<MeetingMaterials> runNotifierBuild(
    covariant MeetingMaterialsNotifier notifier,
  ) {
    return notifier.build(meetingId);
  }

  @override
  Override overrideWith(MeetingMaterialsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MeetingMaterialsNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<
    MeetingMaterialsNotifier,
    MeetingMaterials
  >
  createElement() {
    return _MeetingMaterialsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingMaterialsNotifierProvider &&
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
mixin MeetingMaterialsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<MeetingMaterials> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingMaterialsNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          MeetingMaterialsNotifier,
          MeetingMaterials
        >
    with MeetingMaterialsNotifierRef {
  _MeetingMaterialsNotifierProviderElement(super.provider);

  @override
  String get meetingId =>
      (origin as MeetingMaterialsNotifierProvider).meetingId;
}

String _$meetingNotesNotifierHash() =>
    r'5700a2593b8325defe99110f8d0c9ae42278b46c';

abstract class _$MeetingNotesNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<MeetingNote>> {
  late final String meetingId;

  FutureOr<List<MeetingNote>> build(String meetingId);
}

/// 会议笔记管理提供者
///
/// Copied from [MeetingNotesNotifier].
@ProviderFor(MeetingNotesNotifier)
const meetingNotesNotifierProvider = MeetingNotesNotifierFamily();

/// 会议笔记管理提供者
///
/// Copied from [MeetingNotesNotifier].
class MeetingNotesNotifierFamily extends Family<AsyncValue<List<MeetingNote>>> {
  /// 会议笔记管理提供者
  ///
  /// Copied from [MeetingNotesNotifier].
  const MeetingNotesNotifierFamily();

  /// 会议笔记管理提供者
  ///
  /// Copied from [MeetingNotesNotifier].
  MeetingNotesNotifierProvider call(String meetingId) {
    return MeetingNotesNotifierProvider(meetingId);
  }

  @override
  MeetingNotesNotifierProvider getProviderOverride(
    covariant MeetingNotesNotifierProvider provider,
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
  String? get name => r'meetingNotesNotifierProvider';
}

/// 会议笔记管理提供者
///
/// Copied from [MeetingNotesNotifier].
class MeetingNotesNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          MeetingNotesNotifier,
          List<MeetingNote>
        > {
  /// 会议笔记管理提供者
  ///
  /// Copied from [MeetingNotesNotifier].
  MeetingNotesNotifierProvider(String meetingId)
    : this._internal(
        () => MeetingNotesNotifier()..meetingId = meetingId,
        from: meetingNotesNotifierProvider,
        name: r'meetingNotesNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$meetingNotesNotifierHash,
        dependencies: MeetingNotesNotifierFamily._dependencies,
        allTransitiveDependencies:
            MeetingNotesNotifierFamily._allTransitiveDependencies,
        meetingId: meetingId,
      );

  MeetingNotesNotifierProvider._internal(
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
  FutureOr<List<MeetingNote>> runNotifierBuild(
    covariant MeetingNotesNotifier notifier,
  ) {
    return notifier.build(meetingId);
  }

  @override
  Override overrideWith(MeetingNotesNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MeetingNotesNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<
    MeetingNotesNotifier,
    List<MeetingNote>
  >
  createElement() {
    return _MeetingNotesNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingNotesNotifierProvider &&
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
mixin MeetingNotesNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<MeetingNote>> {
  /// The parameter `meetingId` of this provider.
  String get meetingId;
}

class _MeetingNotesNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          MeetingNotesNotifier,
          List<MeetingNote>
        >
    with MeetingNotesNotifierRef {
  _MeetingNotesNotifierProviderElement(super.provider);

  @override
  String get meetingId => (origin as MeetingNotesNotifierProvider).meetingId;
}

String _$voteNotifierHash() => r'1937e4ee288b8842514a146fd24a690ff4de73c1';

abstract class _$VoteNotifier
    extends BuildlessAutoDisposeAsyncNotifier<MeetingVote?> {
  late final String voteId;
  late final String? meetingId;

  FutureOr<MeetingVote?> build(String voteId, {String? meetingId});
}

/// 投票管理提供者
///
/// Copied from [VoteNotifier].
@ProviderFor(VoteNotifier)
const voteNotifierProvider = VoteNotifierFamily();

/// 投票管理提供者
///
/// Copied from [VoteNotifier].
class VoteNotifierFamily extends Family<AsyncValue<MeetingVote?>> {
  /// 投票管理提供者
  ///
  /// Copied from [VoteNotifier].
  const VoteNotifierFamily();

  /// 投票管理提供者
  ///
  /// Copied from [VoteNotifier].
  VoteNotifierProvider call(String voteId, {String? meetingId}) {
    return VoteNotifierProvider(voteId, meetingId: meetingId);
  }

  @override
  VoteNotifierProvider getProviderOverride(
    covariant VoteNotifierProvider provider,
  ) {
    return call(provider.voteId, meetingId: provider.meetingId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'voteNotifierProvider';
}

/// 投票管理提供者
///
/// Copied from [VoteNotifier].
class VoteNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<VoteNotifier, MeetingVote?> {
  /// 投票管理提供者
  ///
  /// Copied from [VoteNotifier].
  VoteNotifierProvider(String voteId, {String? meetingId})
    : this._internal(
        () =>
            VoteNotifier()
              ..voteId = voteId
              ..meetingId = meetingId,
        from: voteNotifierProvider,
        name: r'voteNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$voteNotifierHash,
        dependencies: VoteNotifierFamily._dependencies,
        allTransitiveDependencies:
            VoteNotifierFamily._allTransitiveDependencies,
        voteId: voteId,
        meetingId: meetingId,
      );

  VoteNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.voteId,
    required this.meetingId,
  }) : super.internal();

  final String voteId;
  final String? meetingId;

  @override
  FutureOr<MeetingVote?> runNotifierBuild(covariant VoteNotifier notifier) {
    return notifier.build(voteId, meetingId: meetingId);
  }

  @override
  Override overrideWith(VoteNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: VoteNotifierProvider._internal(
        () =>
            create()
              ..voteId = voteId
              ..meetingId = meetingId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        voteId: voteId,
        meetingId: meetingId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<VoteNotifier, MeetingVote?>
  createElement() {
    return _VoteNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VoteNotifierProvider &&
        other.voteId == voteId &&
        other.meetingId == meetingId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, voteId.hashCode);
    hash = _SystemHash.combine(hash, meetingId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin VoteNotifierRef on AutoDisposeAsyncNotifierProviderRef<MeetingVote?> {
  /// The parameter `voteId` of this provider.
  String get voteId;

  /// The parameter `meetingId` of this provider.
  String? get meetingId;
}

class _VoteNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<VoteNotifier, MeetingVote?>
    with VoteNotifierRef {
  _VoteNotifierProviderElement(super.provider);

  @override
  String get voteId => (origin as VoteNotifierProvider).voteId;
  @override
  String? get meetingId => (origin as VoteNotifierProvider).meetingId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
