import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/report.dart';
import '../../domain/usecases/create_report.dart';
import '../../domain/usecases/get_reports.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../data/datasources/report_local_datasource.dart';
import '../../data/repositories/photo_storage_service.dart';
import '../../data/repositories/security_service.dart';

part 'report_controller.g.dart';

@riverpod
SecurityService securityService(SecurityServiceRef ref) => SecurityService();

@riverpod
PhotoStorageService photoStorageService(PhotoStorageServiceRef ref) => PhotoStorageService();

@riverpod
ReportLocalDataSource reportLocalDataSource(ReportLocalDataSourceRef ref) {
  final security = ref.watch(securityServiceProvider);
  return ReportLocalDataSource(security);
}

@riverpod
ReportRepositoryImpl reportRepository(ReportRepositoryRef ref) {
  final dataSource = ref.watch(reportLocalDataSourceProvider);
  final photoService = ref.watch(photoStorageServiceProvider);
  return ReportRepositoryImpl(
    localDataSource: dataSource,
    photoService: photoService,
  );
}

@riverpod
class ReportListController extends _$ReportListController {
  @override
  FutureOr<List<Report>> build() async {
    final getReports = GetReports(ref.watch(reportRepositoryProvider));
    return getReports();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final getReports = GetReports(ref.watch(reportRepositoryProvider));
      return getReports();
    });
  }
}

@riverpod
class ReportCreateController extends _$ReportCreateController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> createReport(String description, List<String> photoPaths) async {
    state = const AsyncValue.loading();
    final createReportUseCase = CreateReport(ref.watch(reportRepositoryProvider));
    
    final result = await AsyncValue.guard(() => createReportUseCase((
      description: description,
      photoPaths: photoPaths,
    )));

    state = result;
    
    if (!result.hasError) {
      ref.read(reportListControllerProvider.notifier).refresh();
      return true;
    }
    return false;
  }
}
