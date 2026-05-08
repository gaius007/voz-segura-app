// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$securityServiceHash() => r'0b6606de0a9bceae83ca768829366d5f3f269cc7';

/// See also [securityService].
@ProviderFor(securityService)
final securityServiceProvider = AutoDisposeProvider<SecurityService>.internal(
  securityService,
  name: r'securityServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$securityServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecurityServiceRef = AutoDisposeProviderRef<SecurityService>;
String _$photoStorageServiceHash() =>
    r'e502091e17bca3627257b2f8cc31cf8abe51bd8a';

/// See also [photoStorageService].
@ProviderFor(photoStorageService)
final photoStorageServiceProvider =
    AutoDisposeProvider<PhotoStorageService>.internal(
      photoStorageService,
      name: r'photoStorageServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$photoStorageServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PhotoStorageServiceRef = AutoDisposeProviderRef<PhotoStorageService>;
String _$reportLocalDataSourceHash() =>
    r'47ead94194016da4956fa32051cd38a176b7a792';

/// See also [reportLocalDataSource].
@ProviderFor(reportLocalDataSource)
final reportLocalDataSourceProvider =
    AutoDisposeProvider<ReportLocalDataSource>.internal(
      reportLocalDataSource,
      name: r'reportLocalDataSourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reportLocalDataSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReportLocalDataSourceRef =
    AutoDisposeProviderRef<ReportLocalDataSource>;
String _$reportRepositoryHash() => r'7d8c2be1e0727eb56022cb1c84e590ae6f571dc1';

/// See also [reportRepository].
@ProviderFor(reportRepository)
final reportRepositoryProvider =
    AutoDisposeProvider<ReportRepositoryImpl>.internal(
      reportRepository,
      name: r'reportRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reportRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReportRepositoryRef = AutoDisposeProviderRef<ReportRepositoryImpl>;
String _$reportListControllerHash() =>
    r'c7760673d2699ef718c7e09e33b9af93c2a639c3';

/// See also [ReportListController].
@ProviderFor(ReportListController)
final reportListControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      ReportListController,
      List<Report>
    >.internal(
      ReportListController.new,
      name: r'reportListControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reportListControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReportListController = AutoDisposeAsyncNotifier<List<Report>>;
String _$reportCreateControllerHash() =>
    r'b8ca3932fb3c9232d28f8400d514c399ad81d261';

/// See also [ReportCreateController].
@ProviderFor(ReportCreateController)
final reportCreateControllerProvider =
    AutoDisposeNotifierProvider<
      ReportCreateController,
      AsyncValue<void>
    >.internal(
      ReportCreateController.new,
      name: r'reportCreateControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reportCreateControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReportCreateController = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
