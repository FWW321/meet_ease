// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

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
String _$userNotifierHash() => r'9ab2cc9611f9f7b077e6227bb0db8847ff16a1f0';

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
