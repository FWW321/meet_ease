// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$searchUsersHash() => r'0ac346fa430a2b6666fe39bb5902b7df5b5ae2cc';

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

/// 用户搜索提供者
///
/// Copied from [searchUsers].
@ProviderFor(searchUsers)
const searchUsersProvider = SearchUsersFamily();

/// 用户搜索提供者
///
/// Copied from [searchUsers].
class SearchUsersFamily extends Family<AsyncValue<List<User>>> {
  /// 用户搜索提供者
  ///
  /// Copied from [searchUsers].
  const SearchUsersFamily();

  /// 用户搜索提供者
  ///
  /// Copied from [searchUsers].
  SearchUsersProvider call({
    String? username,
    String? email,
    String? phone,
    String? userId,
  }) {
    return SearchUsersProvider(
      username: username,
      email: email,
      phone: phone,
      userId: userId,
    );
  }

  @override
  SearchUsersProvider getProviderOverride(
    covariant SearchUsersProvider provider,
  ) {
    return call(
      username: provider.username,
      email: provider.email,
      phone: provider.phone,
      userId: provider.userId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'searchUsersProvider';
}

/// 用户搜索提供者
///
/// Copied from [searchUsers].
class SearchUsersProvider extends AutoDisposeFutureProvider<List<User>> {
  /// 用户搜索提供者
  ///
  /// Copied from [searchUsers].
  SearchUsersProvider({
    String? username,
    String? email,
    String? phone,
    String? userId,
  }) : this._internal(
         (ref) => searchUsers(
           ref as SearchUsersRef,
           username: username,
           email: email,
           phone: phone,
           userId: userId,
         ),
         from: searchUsersProvider,
         name: r'searchUsersProvider',
         debugGetCreateSourceHash:
             const bool.fromEnvironment('dart.vm.product')
                 ? null
                 : _$searchUsersHash,
         dependencies: SearchUsersFamily._dependencies,
         allTransitiveDependencies:
             SearchUsersFamily._allTransitiveDependencies,
         username: username,
         email: email,
         phone: phone,
         userId: userId,
       );

  SearchUsersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.username,
    required this.email,
    required this.phone,
    required this.userId,
  }) : super.internal();

  final String? username;
  final String? email;
  final String? phone;
  final String? userId;

  @override
  Override overrideWith(
    FutureOr<List<User>> Function(SearchUsersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchUsersProvider._internal(
        (ref) => create(ref as SearchUsersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        username: username,
        email: email,
        phone: phone,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<User>> createElement() {
    return _SearchUsersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchUsersProvider &&
        other.username == username &&
        other.email == email &&
        other.phone == phone &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, username.hashCode);
    hash = _SystemHash.combine(hash, email.hashCode);
    hash = _SystemHash.combine(hash, phone.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SearchUsersRef on AutoDisposeFutureProviderRef<List<User>> {
  /// The parameter `username` of this provider.
  String? get username;

  /// The parameter `email` of this provider.
  String? get email;

  /// The parameter `phone` of this provider.
  String? get phone;

  /// The parameter `userId` of this provider.
  String? get userId;
}

class _SearchUsersProviderElement
    extends AutoDisposeFutureProviderElement<List<User>>
    with SearchUsersRef {
  _SearchUsersProviderElement(super.provider);

  @override
  String? get username => (origin as SearchUsersProvider).username;
  @override
  String? get email => (origin as SearchUsersProvider).email;
  @override
  String? get phone => (origin as SearchUsersProvider).phone;
  @override
  String? get userId => (origin as SearchUsersProvider).userId;
}

String _$currentUserHash() => r'642757d8261dd2968dc9eaf93acc05f35d3b3958';

/// 当前用户提供者
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeFutureProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeFutureProviderRef<User?>;
String _$userHash() => r'027b11c6b5fdc290186fcf2323c0e6326571c45e';

/// 用户详情提供者
///
/// Copied from [user].
@ProviderFor(user)
const userProvider = UserFamily();

/// 用户详情提供者
///
/// Copied from [user].
class UserFamily extends Family<AsyncValue<User>> {
  /// 用户详情提供者
  ///
  /// Copied from [user].
  const UserFamily();

  /// 用户详情提供者
  ///
  /// Copied from [user].
  UserProvider call(String userId) {
    return UserProvider(userId);
  }

  @override
  UserProvider getProviderOverride(covariant UserProvider provider) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userProvider';
}

/// 用户详情提供者
///
/// Copied from [user].
class UserProvider extends AutoDisposeFutureProvider<User> {
  /// 用户详情提供者
  ///
  /// Copied from [user].
  UserProvider(String userId)
    : this._internal(
        (ref) => user(ref as UserRef, userId),
        from: userProvider,
        name: r'userProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product') ? null : _$userHash,
        dependencies: UserFamily._dependencies,
        allTransitiveDependencies: UserFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(FutureOr<User> Function(UserRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: UserProvider._internal(
        (ref) => create(ref as UserRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<User> createElement() {
    return _UserProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserRef on AutoDisposeFutureProviderRef<User> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserProviderElement extends AutoDisposeFutureProviderElement<User>
    with UserRef {
  _UserProviderElement(super.provider);

  @override
  String get userId => (origin as UserProvider).userId;
}

String _$currentUserIdHash() => r'e60b501b1d0dc8be43f3238891cb5477e070371a';

/// 当前用户ID提供者 (通常从本地存储或会话中获取)
///
/// Copied from [currentUserId].
@ProviderFor(currentUserId)
final currentUserIdProvider = AutoDisposeFutureProvider<String>.internal(
  currentUserId,
  name: r'currentUserIdProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserIdRef = AutoDisposeFutureProviderRef<String>;
String _$userNameHash() => r'c2af173bcead3703f9af7093f00c6dbf4b32fa81';

/// 用户名提供者 - 通过用户ID获取用户名
///
/// Copied from [userName].
@ProviderFor(userName)
const userNameProvider = UserNameFamily();

/// 用户名提供者 - 通过用户ID获取用户名
///
/// Copied from [userName].
class UserNameFamily extends Family<AsyncValue<String>> {
  /// 用户名提供者 - 通过用户ID获取用户名
  ///
  /// Copied from [userName].
  const UserNameFamily();

  /// 用户名提供者 - 通过用户ID获取用户名
  ///
  /// Copied from [userName].
  UserNameProvider call(String userId) {
    return UserNameProvider(userId);
  }

  @override
  UserNameProvider getProviderOverride(covariant UserNameProvider provider) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userNameProvider';
}

/// 用户名提供者 - 通过用户ID获取用户名
///
/// Copied from [userName].
class UserNameProvider extends AutoDisposeFutureProvider<String> {
  /// 用户名提供者 - 通过用户ID获取用户名
  ///
  /// Copied from [userName].
  UserNameProvider(String userId)
    : this._internal(
        (ref) => userName(ref as UserNameRef, userId),
        from: userNameProvider,
        name: r'userNameProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$userNameHash,
        dependencies: UserNameFamily._dependencies,
        allTransitiveDependencies: UserNameFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserNameProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<String> Function(UserNameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserNameProvider._internal(
        (ref) => create(ref as UserNameRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _UserNameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserNameProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserNameRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserNameProviderElement extends AutoDisposeFutureProviderElement<String>
    with UserNameRef {
  _UserNameProviderElement(super.provider);

  @override
  String get userId => (origin as UserNameProvider).userId;
}

String _$userSearchHash() => r'a750b23ee1bfee8f9174fb07a45d45c6101da0b7';

/// 用户搜索状态提供者
///
/// Copied from [UserSearch].
@ProviderFor(UserSearch)
final userSearchProvider =
    AutoDisposeAsyncNotifierProvider<UserSearch, List<User>>.internal(
      UserSearch.new,
      name: r'userSearchProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$userSearchHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserSearch = AutoDisposeAsyncNotifier<List<User>>;
String _$authStateHash() => r'33fceb0dde28b06909a44ef5707a318f5e48fe67';

/// 用户登录状态提供者
///
/// Copied from [AuthState].
@ProviderFor(AuthState)
final authStateProvider = AutoDisposeNotifierProvider<AuthState, bool>.internal(
  AuthState.new,
  name: r'authStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthState = AutoDisposeNotifier<bool>;
String _$userNotifierHash() => r'511d45be2e87c517495ae02613414a2470712142';

/// 用户信息提供者
///
/// Copied from [UserNotifier].
@ProviderFor(UserNotifier)
final userNotifierProvider =
    AutoDisposeAsyncNotifierProvider<UserNotifier, User?>.internal(
      UserNotifier.new,
      name: r'userNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$userNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserNotifier = AutoDisposeAsyncNotifier<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
